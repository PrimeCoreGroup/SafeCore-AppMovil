import 'package:dio/dio.dart';

import '../errors/failures.dart';
import '../utils/json_utils.dart';

typedef ReachabilityCallback = void Function(bool cloudReachable);

/// Cliente REST de alto nivel sobre Dio.
///
/// * Traduce [DioException] a [Failure] controlados.
/// * Informa si la nube es alcanzable (para el modo offline).
/// * Desempaqueta respuestas `{data: ...}`.
class ApiClient {
  ApiClient(this._dio, {this.onReachability});

  final Dio _dio;
  final ReachabilityCallback? onReachability;

  Future<Object?> get(String path, {Map<String, Object?>? query}) =>
      _send(() => _dio.get<Object?>(path, queryParameters: _clean(query)));

  Future<Object?> post(String path, {Object? body}) =>
      _send(() => _dio.post<Object?>(path, data: body));

  Future<Object?> patch(String path, {Object? body}) =>
      _send(() => _dio.patch<Object?>(path, data: body));

  Future<Object?> put(String path, {Object? body}) =>
      _send(() => _dio.put<Object?>(path, data: body));

  Future<Object?> delete(String path) =>
      _send(() => _dio.delete<Object?>(path));

  Map<String, Object?>? _clean(Map<String, Object?>? q) {
    if (q == null) return null;
    return Map.fromEntries(q.entries.where((e) => e.value != null));
  }

  Future<Object?> _send(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      onReachability?.call(true);
      return unwrapData(response.data);
    } on DioException catch (e) {
      final failure = mapDioException(e);
      if (isConnectivityFailure(failure)) {
        onReachability?.call(false);
      } else {
        // Hubo respuesta HTTP: la nube es alcanzable.
        onReachability?.call(true);
      }
      throw failure;
    }
  }
}

/// Conversión de errores de red/HTTP a errores de dominio.
Failure mapDioException(DioException e) {
  final inner = e.error;
  if (inner is Failure) return inner;

  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();

    case DioExceptionType.connectionError:
      return const NetworkFailure();

    case DioExceptionType.badCertificate:
      return const NetworkFailure(
        'No se pudo establecer una conexión segura con el servidor.',
      );

    case DioExceptionType.cancel:
      return const UnknownFailure('La solicitud fue cancelada.');

    case DioExceptionType.badResponse:
      return mapHttpStatus(e.response?.statusCode, e.response?.data);

    case DioExceptionType.unknown:
      return const NetworkFailure();
  }
}

Failure mapHttpStatus(int? status, Object? body) {
  final json = asJson(body);
  final fieldErrors = _validationErrors(json['errors']);
  final serverMessage = readStringOrNull(json, 'message') ??
      readStringOrNull(json, 'detail') ??
      (fieldErrors.isNotEmpty ? fieldErrors.values.first : null) ??
      readStringOrNull(json, 'title');
  switch (status) {
    case 400:
    case 422:
      return ValidationFailure(
        serverMessage ?? 'Los datos enviados no son válidos.',
        fieldErrors: fieldErrors,
      );
    case 401:
      return const SessionExpiredFailure();
    case 403:
      return const ForbiddenFailure(
        'Tu rol no tiene acceso a esta información o acción.',
      );
    case 404:
      return const NotFoundFailure();
    case 409:
      return ConflictFailure(
        serverMessage ??
            'La operación entra en conflicto con datos existentes.',
      );
    case 429:
      return const TooManyRequestsFailure();
    case 503:
      return const ServiceUnavailableFailure();
    default:
      if (status != null && status >= 500) {
        return ServerFailure(
          'El servidor presentó un error ($status). Intenta nuevamente.',
          status,
        );
      }
      return ServerFailure('Respuesta inesperada del servidor.', status);
  }
}

/// Soporta `ValidationProblemDetails` de ASP.NET (`{"errors": {"Campo":
/// ["mensaje"]}}`) y la forma lista `[{"field", "message"}]`.
Map<String, String> _validationErrors(Object? raw) {
  final result = <String, String>{};
  if (raw is Map) {
    raw.forEach((key, value) {
      final first = value is List && value.isNotEmpty ? value.first : value;
      if (first != null) {
        final k = key.toString();
        final field = k.isEmpty ? k : k[0].toLowerCase() + k.substring(1);
        result[field] = first.toString();
      }
    });
  } else if (raw is List) {
    for (final err in asJsonList(raw)) {
      final field = readStringOrNull(err, 'field');
      final msg = readStringOrNull(err, 'message');
      if (field != null && msg != null) result[field] = msg;
    }
  }
  return result;
}
