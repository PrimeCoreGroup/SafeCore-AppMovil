import 'dart:convert';

import '../../../../core/security/jwt_decoder.dart';
import '../../../../core/security/token_storage.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../shared/services/demo/demo_data_store.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/auth_validators.dart';
import '../datasources/auth_data_source.dart';
import '../models/auth_models.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthDataSource dataSource,
    required TokenStorage tokenStorage,
    required LocalCache cache,
    DemoDataStore? demoStore,
    DateTime Function()? clock,
  })  : _ds = dataSource,
        _tokens = tokenStorage,
        _cache = cache,
        _demo = demoStore,
        _clock = clock ?? DateTime.now;

  final AuthDataSource _ds;
  final TokenStorage _tokens;
  final LocalCache _cache;
  final DemoDataStore? _demo;
  final DateTime Function() _clock;

  DateTime? _expiry(String token, Duration? expiresIn) =>
      JwtDecoder.tryDecode(token)?.expiresAt ??
      (expiresIn == null ? null : _clock().add(expiresIn));

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final normalized = AuthValidators.normalizeEmail(email);
    final r = await _ds.login(normalized, password);
    // Solo se guarda el token y datos básicos; nunca la contraseña.
    await _tokens.writeToken(r.accessToken);
    await _tokens.writeUserJson(jsonEncode(UserMapper.toJson(r.user)));
    await _cache.write(CacheKeys.lastEmail, normalized);
    return AuthSession(
      user: r.user,
      token: r.accessToken,
      expiresAt: _expiry(r.accessToken, r.expiresIn),
      isDemo: _ds.isDemo,
    );
  }

  @override
  Future<AppUser> me() async {
    final user = await _ds.me();
    await _tokens.writeUserJson(jsonEncode(UserMapper.toJson(user)));
    return user;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _tokens.readToken();
    final userJson = await _tokens.readUserJson();
    if (token == null || userJson == null) return null;
    final claims = JwtDecoder.tryDecode(token);
    if (claims == null || claims.isExpired(now: _clock())) {
      await logout();
      return null;
    }
    final AppUser user;
    try {
      user = UserMapper.fromJson(asJson(jsonDecode(userJson)));
    } on FormatException {
      await logout();
      return null;
    }
    final demo = _demo;
    if (_ds.isDemo && demo != null) {
      demo.currentAccount = demo.accountFor(user.email);
      if (demo.currentAccount == null) {
        await logout();
        return null;
      }
    }
    return AuthSession(
      user: user,
      token: token,
      expiresAt: claims.expiresAt,
      isDemo: _ds.isDemo,
    );
  }

  @override
  Future<void> logout() async {
    await _tokens.clear();
    // Protección de datos: se borra el último estado conocido; se conservan
    // solo el tema y el último correo usado.
    final theme = await _cache.read(CacheKeys.themeMode);
    final email = await _cache.read(CacheKeys.lastEmail);
    await _cache.clear();
    if (theme != null) await _cache.write(CacheKeys.themeMode, theme.value);
    if (email != null) await _cache.write(CacheKeys.lastEmail, email.value);
    _demo?.currentAccount = null;
  }

  @override
  Future<String?> lastEmail() async {
    final v = (await _cache.read(CacheKeys.lastEmail))?.value;
    return v is String ? v : null;
  }
}
