import '../../../../core/utils/data_result.dart';
import '../entities/managed_user.dart';

abstract interface class UsersRepository {
  Future<DataResult<List<ManagedUser>>> getUsers();
  Future<ManagedUser> create(NewUserData data);

  /// Actualiza nombre, apellido y estado (no email, contraseña ni rol).
  Future<void> update(
    String id, {
    required String firstName,
    required String lastName,
    required UserStatus status,
  });
  Future<void> delete(String id);
}
