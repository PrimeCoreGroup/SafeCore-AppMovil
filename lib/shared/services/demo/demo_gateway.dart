import '../../../core/errors/failures.dart';
import '../../../core/security/roles.dart';
import 'demo_data_store.dart';

/// Base de las fuentes de datos de demostración.
///
/// Emula el backend: latencia, falta de conexión y validación de permisos
/// por rol (403). Los datos son ficticios y se identifican como tales.
abstract class DemoGateway {
  DemoGateway(
    this.store, {
    required this.isOnline,
    this.latency = const Duration(milliseconds: 350),
  });

  final DemoDataStore store;
  final bool Function() isOnline;
  final Duration latency;

  /// Notifica si la "nube" demo fue alcanzable (alimenta el modo offline).
  void Function(bool cloudReachable)? onReachability;

  Future<T> call<T>(T Function() body) async {
    await Future<void>.delayed(latency);
    if (!isOnline()) {
      onReachability?.call(false);
      throw const NetworkFailure();
    }
    onReachability?.call(true);
    return body();
  }

  DemoAccount get account {
    final a = store.currentAccount;
    if (a == null) throw const SessionExpiredFailure();
    return a;
  }

  /// Equivalente a la autorización por rol del backend.
  void require(Permission permission) {
    if (!RolePermissions.can(account.user.roles, permission)) {
      throw const ForbiddenFailure(
        'Tu rol no tiene acceso a esta información o acción.',
      );
    }
  }
}
