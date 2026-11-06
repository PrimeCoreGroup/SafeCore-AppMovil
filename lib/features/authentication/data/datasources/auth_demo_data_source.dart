import '../../../../core/errors/failures.dart';
import '../../../../core/security/jwt_decoder.dart';
import '../../../../shared/services/demo/demo_data_store.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/app_user.dart';
import '../models/auth_models.dart';
import 'auth_data_source.dart';

/// Login ficticio con tokens sin firma y la misma duración del backend
/// (15 minutos) para ejercitar el control de expiración.
class AuthDemoDataSource extends DemoGateway implements AuthDataSource {
  AuthDemoDataSource(
    super.store, {
    required super.isOnline,
    this.sessionDuration = const Duration(minutes: 15),
  });

  final Duration sessionDuration;

  @override
  bool get isDemo => true;

  @override
  Future<LoginResponse> login(String email, String password) => call(() {
        final a = store.accountFor(email);
        if (a == null || password != DemoDataStore.demoPassword) {
          throw const InvalidCredentialsFailure(
            'Correo o contraseña incorrectos, o la cuenta no está activa.',
          );
        }
        store.currentAccount = a;
        return LoginResponse(
          accessToken: JwtDecoder.buildUnsignedDemoToken(
            subject: a.user.id,
            expiresAt: store.now.add(sessionDuration),
          ),
          expiresIn: sessionDuration,
          user: a.user,
        );
      });

  @override
  Future<AppUser> me() => call(() => account.user);
}
