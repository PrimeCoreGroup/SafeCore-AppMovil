import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/roles.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../domain/entities/app_user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthState {
  const AuthState({required this.status, this.session, this.notice});
  const AuthState.checking() : this(status: AuthStatus.checking);

  final AuthStatus status;
  final AuthSession? session;
  final String? notice;

  AppUser? get user => session?.user;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Sesión con el backend: token JWT de 15 minutos sin refresh token.
/// Antes de expirar se ofrece renovar la sesión con la contraseña.
class AuthController extends Notifier<AuthState> {
  Timer? _expiryTimer;

  @override
  AuthState build() {
    final sub = ref
        .watch(sessionEventsProvider)
        .onSessionExpired
        .listen((_) => unawaited(handleSessionExpired()));
    ref.onDispose(() {
      unawaited(sub.cancel());
      _expiryTimer?.cancel();
    });
    unawaited(Future.microtask(_restore));
    return const AuthState.checking();
  }

  Future<void> _restore() async {
    try {
      final session = await ref.read(authRepositoryProvider).restoreSession();
      if (session == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      _setSession(session);
      unawaited(refreshProfile());
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// GET /api/iam/auth/me — actualiza nombre y roles vigentes.
  Future<void> refreshProfile() async {
    final current = state.session;
    if (current == null) return;
    try {
      final user = await ref.read(authRepositoryProvider).me();
      if (state.session?.token == current.token) {
        state = AuthState(
            status: AuthStatus.authenticated, session: current.withUser(user));
      }
    } catch (_) {
      // Sin conexión: se mantienen los datos guardados.
    }
  }

  void _setSession(AuthSession session) {
    state = AuthState(status: AuthStatus.authenticated, session: session);
    _expiryTimer?.cancel();
    final exp = session.expiresAt;
    if (exp != null) {
      final remaining = exp.difference(DateTime.now());
      _expiryTimer = Timer(
        remaining.isNegative ? Duration.zero : remaining,
        () => unawaited(handleSessionExpired()),
      );
    }
  }

  /// Devuelve null si tuvo éxito o el mensaje de error.
  Future<String?> login(String email, String password) async {
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      _setSession(session);
      await ref.read(auditLoggerProvider).log('auth.login');
      return null;
    } catch (e) {
      await ref.read(auditLoggerProvider).log('auth.login', result: 'error');
      return asFailure(e).message;
    }
  }

  /// Renueva el token antes de que expire, sin perder la pantalla actual.
  Future<String?> renew(String password) async {
    final email = state.user?.email;
    if (email == null) return 'No hay una sesión activa.';
    return login(email, password);
  }

  /// Activa/desactiva el modo demostración antes de iniciar sesión.
  void setDemo(bool value) {
    if (state.isAuthenticated) return;
    ref.read(isDemoProvider.notifier).state = value;
  }

  Future<void> logout({String? notice}) async {
    _expiryTimer?.cancel();
    await ref.read(auditLoggerProvider).log('auth.logout');
    await ref.read(authRepositoryProvider).logout();
    ref.read(isDemoProvider.notifier).state =
        ref.read(appConfigProvider).demoMode;
    state = AuthState(status: AuthStatus.unauthenticated, notice: notice);
  }

  Future<void> handleSessionExpired() async {
    if (state.status != AuthStatus.authenticated) return;
    await logout(notice: const SessionExpiredFailure().message);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

final currentUserProvider =
    Provider<AppUser?>((ref) => ref.watch(authControllerProvider).user);

final permissionsProvider = Provider<Set<Permission>>(
  (ref) => RolePermissions.forRoles(
      ref.watch(currentUserProvider)?.roles ?? const []),
);

final canProvider = Provider.family<bool, Permission>(
  (ref, p) => ref.watch(permissionsProvider).contains(p),
);

final lastEmailProvider = FutureProvider<String?>(
  (ref) => ref.watch(authRepositoryProvider).lastEmail(),
);
