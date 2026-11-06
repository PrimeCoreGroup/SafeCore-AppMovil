import '../../../../core/security/roles.dart';

enum UserStatus {
  active,
  disabled;

  String get label => this == active ? 'Activo' : 'Deshabilitado';
  String get apiValue => this == active ? 'Active' : 'Disabled';
}

/// Usuario administrado (`/api/users`, solo Administrator).
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    required this.roles,
    this.createdAt,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final UserStatus status;
  final List<UserRole> roles;
  final DateTime? createdAt;

  String get fullName {
    final n = '$firstName $lastName'.trim();
    return n.isEmpty ? email : n;
  }
}

class NewUserData {
  const NewUserData({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final UserRole role;
}
