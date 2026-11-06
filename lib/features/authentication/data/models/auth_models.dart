import '../../../../core/security/roles.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/app_user.dart';

class UserMapper {
  const UserMapper._();

  static AppUser fromJson(Json json) => AppUser(
        id: readString(json, 'id'),
        email: readString(json, 'email'),
        firstName: readString(json, 'firstName'),
        lastName: readString(json, 'lastName'),
        roles: readStringList(json, 'roles').map(UserRole.fromApi).toList(),
      );

  static Json toJson(AppUser u) => {
        'id': u.id,
        'email': u.email,
        'firstName': u.firstName,
        'lastName': u.lastName,
        'roles': u.roles.map((r) => r.apiValue).toList(),
      };
}

/// Respuesta de `POST /api/iam/auth/login`.
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final Duration? expiresIn;
  final AppUser user;

  factory LoginResponse.fromJson(Json json) {
    final token = asJson(json['token']);
    final seconds = readInt(token, 'expiresInSeconds');
    return LoginResponse(
      accessToken: readString(token, 'accessToken'),
      expiresIn: seconds == null ? null : Duration(seconds: seconds),
      user: UserMapper.fromJson(asJson(json['user'])),
    );
  }
}
