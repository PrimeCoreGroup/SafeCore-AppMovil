import '../../../../core/security/roles.dart';

/// Usuario autenticado (`user` de `/api/iam/auth/login` y `/me`).
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final List<UserRole> roles;

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? email : n;
  }

  String get displayFirstName =>
      firstName.trim().isEmpty ? email.split('@').first : firstName.trim();

  String get initials {
    final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  UserRole get primaryRole => RolePermissions.primary(roles);

  bool get isResidentOnly =>
      roles.isNotEmpty && roles.every((r) => r == UserRole.resident);
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    this.expiresAt,
    this.isDemo = false,
  });

  final AppUser user;
  final String token;
  final DateTime? expiresAt;
  final bool isDemo;

  AuthSession withUser(AppUser u) =>
      AuthSession(user: u, token: token, expiresAt: expiresAt, isDemo: isDemo);
}
