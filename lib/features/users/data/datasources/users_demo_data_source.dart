import '../../../../core/errors/failures.dart';
import '../../../../core/security/roles.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/managed_user.dart';
import '../../../authentication/domain/services/auth_validators.dart';
import 'users_data_source.dart';

class UsersDemoDataSource extends DemoGateway implements UsersDataSource {
  UsersDemoDataSource(super.store, {required super.isOnline});

  @override
  Future<List<ManagedUser>> fetchAll() => call(() {
        require(Permission.manageUsers);
        return [...store.users]..sort((a, b) => a.email.compareTo(b.email));
      });

  @override
  Future<ManagedUser> create(NewUserData d) => call(() {
        require(Permission.manageUsers);
        final pwError = AuthValidators.newPassword(d.password);
        if (pwError != null) {
          throw ValidationFailure(pwError, fieldErrors: {'password': pwError});
        }
        final email = d.email.trim().toLowerCase();
        if (store.users.any((u) => u.email == email)) {
          throw const ConflictFailure('Ya existe un usuario con ese correo.');
        }
        final u = ManagedUser(
          id: store.newId('u'),
          email: email,
          firstName: d.firstName.trim(),
          lastName: d.lastName.trim(),
          status: UserStatus.active,
          roles: [d.role],
          createdAt: store.now,
        );
        store.users.add(u);
        return u;
      });

  @override
  Future<void> update(
          String id, String firstName, String lastName, UserStatus status) =>
      call(() {
        require(Permission.manageUsers);
        final i = store.users.indexWhere((u) => u.id == id);
        if (i < 0) throw const NotFoundFailure();
        if (id == account.user.id && status == UserStatus.disabled) {
          throw const ConflictFailure(
              'No puedes deshabilitar tu propia cuenta.');
        }
        final u = store.users[i];
        store.users[i] = ManagedUser(
          id: id,
          email: u.email,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          status: status,
          roles: u.roles,
          createdAt: u.createdAt,
        );
      });

  @override
  Future<void> delete(String id) => call(() {
        require(Permission.manageUsers);
        if (id == account.user.id) {
          throw const ConflictFailure('No puedes eliminar tu propia cuenta.');
        }
        if (store.notifications.any((n) => n.recipientUserId == id)) {
          throw const ConflictFailure(
            'El usuario tiene notificaciones asociadas. Deshabilita la cuenta en su lugar.',
          );
        }
        store.users.removeWhere((u) => u.id == id);
      });
}
