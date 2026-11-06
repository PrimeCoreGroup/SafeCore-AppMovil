import '../../domain/entities/managed_user.dart';

abstract interface class UsersDataSource {
  Future<List<ManagedUser>> fetchAll();
  Future<ManagedUser> create(NewUserData d);
  Future<void> update(
      String id, String firstName, String lastName, UserStatus status);
  Future<void> delete(String id);
}
