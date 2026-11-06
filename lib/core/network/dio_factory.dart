import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/failures.dart';
import '../security/jwt_decoder.dart';
import '../security/token_storage.dart';

/// Crea el cliente Dio con interceptores de seguridad.
Dio createDio({
  required AppConfig config,
  required TokenStorage tokenStorage,
  required void Function() onSessionExpired,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
        tokenStorage: tokenStorage, onSessionExpired: onSessionExpired),
  );
  if (_isDebugBuild()) dio.interceptors.add(SafeLogInterceptor());
  return dio;
}

/// Adjunta el JWT, verifica su expiración antes de enviar y gestiona 401.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenStorage, required this.onSessionExpired});

  final TokenStorage tokenStorage;
  final void Function() onSessionExpired;

  static const _publicPaths = [
    '/iam/auth/login',
    '/iam/auth/device-token',
    '/health/',
  ];

  bool _isPublic(String path) => _publicPaths.any(path.contains);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublic(options.path)) return handler.next(options);
    final token = await tokenStorage.readToken();
    if (token == null) {
      onSessionExpired();
      return handler.reject(
        DioException(
          requestOptions: options,
          error: const SessionExpiredFailure(),
          type: DioExceptionType.cancel,
        ),
      );
    }
    final claims = JwtDecoder.tryDecode(token);
    if (claims != null && claims.isExpired()) {
      await tokenStorage.clear();
      onSessionExpired();
      return handler.reject(
        DioException(
          requestOptions: options,
          error: const SessionExpiredFailure(),
          type: DioExceptionType.cancel,
        ),
      );
    }
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final isLogin = err.requestOptions.path.contains('/iam/auth/login');
    if (err.response?.statusCode == 401 && !isLogin) {
      await tokenStorage.clear();
      onSessionExpired();
    }
    handler.next(err);
  }
}

/// Log de depuración que NUNCA imprime tokens, contraseñas ni cuerpos.
class SafeLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('[HTTP] → ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log('[HTTP] ← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      '[HTTP] ✕ ${err.response?.statusCode ?? err.type.name} ${err.requestOptions.path}',
    );
    handler.next(err);
  }
}

/// true solo en compilaciones de depuración (las aserciones se eliminan en
/// release/profile).
bool _isDebugBuild() {
  var debug = false;
  assert(() {
    debug = true;
    return true;
  }());
  return debug;
}

void _log(String message) => developer.log(message, name: 'SafeCore.HTTP');
