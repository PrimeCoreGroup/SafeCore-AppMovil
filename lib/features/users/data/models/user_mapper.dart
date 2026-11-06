import '../../../../core/security/roles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/managed_user.dart';

class ManagedUserMapper {
  const ManagedUserMapper._();

  static ManagedUser fromJson(Json j) {
    final roles = readStringList(j, 'roles');
    final single = readStringOrNull(j, 'role');
    return ManagedUser(
      id: readString(j, 'id'),
      email: readString(j, 'email'),
      firstName: readString(j, 'firstName'),
      lastName: readString(j, 'lastName'),
      status: enumFromApi(UserStatus.values, j['status'], UserStatus.active),
      roles: [
        ...roles.map(UserRole.fromApi),
        if (roles.isEmpty && single != null) UserRole.fromApi(single),
      ],
      createdAt: DateFormatter.tryParse(j['createdAt']),
    );
  }

  static Json toJson(ManagedUser u) => {
        'id': u.id,
        'email': u.email,
        'firstName': u.firstName,
        'lastName': u.lastName,
        'status': u.status.apiValue,
        'roles': u.roles.map((r) => r.apiValue).toList(),
        if (u.createdAt != null)
          'createdAt': u.createdAt!.toUtc().toIso8601String(),
      };

  static Json newToJson(NewUserData d) => {
        'email': d.email.trim().toLowerCase(),
        'password': d.password,
        'firstName': d.firstName.trim(),
        'lastName': d.lastName.trim(),
        'role': d.role.apiValue,
      };

  static List<ManagedUser> listFromJson(Object? raw) =>
      asJsonList(raw).map(fromJson).toList();
  static List<Json> listToJson(List<ManagedUser> l) => l.map(toJson).toList();
}
