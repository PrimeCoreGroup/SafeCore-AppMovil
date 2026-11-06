import '../entities/app_user.dart';

abstract interface class AuthRepository {
  /// POST /api/iam/auth/login
  Future<AuthSession> login({required String email, required String password});

  /// GET /api/iam/auth/me — refresca nombre y roles.
  Future<AppUser> me();

  Future<AuthSession?> restoreSession();
  Future<void> logout();
  Future<String?> lastEmail();
}
