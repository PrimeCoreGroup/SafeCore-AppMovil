import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/app_user.dart';
import '../models/auth_models.dart';
import 'auth_data_source.dart';

class AuthRemoteDataSource implements AuthDataSource {
  AuthRemoteDataSource(this._api);
  final ApiClient _api;

  @override
  bool get isDemo => false;

  @override
  Future<LoginResponse> login(String email, String password) async {
    try {
      final body = await _api.post(
        ApiEndpoints.login,
        body: {'email': email, 'password': password},
      );
      final r = LoginResponse.fromJson(asJson(body));
      if (r.accessToken.isEmpty) {
        throw const ServerFailure(
            'El servidor no devolvió un token de sesión.');
      }
      return r;
    } on SessionExpiredFailure {
      // En el login, 401 = credenciales inválidas o usuario inactivo.
      throw const InvalidCredentialsFailure(
        'Correo o contraseña incorrectos, o la cuenta no está activa.',
      );
    }
  }

  @override
  Future<AppUser> me() async =>
      UserMapper.fromJson(asJson(await _api.get(ApiEndpoints.me)));
}
