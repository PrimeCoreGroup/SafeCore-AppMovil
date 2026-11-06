import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/managed_user.dart';
import '../models/user_mapper.dart';
import 'users_data_source.dart';

class UsersRemoteDataSource implements UsersDataSource {
  UsersRemoteDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<ManagedUser>> fetchAll() => fetchAllPages(
        (page, size) async => ManagedUserMapper.listFromJson(
          await _api
              .get(ApiEndpoints.users, query: {'page': page, 'pageSize': size}),
        ),
      );

  @override
  Future<ManagedUser> create(NewUserData d) async => ManagedUserMapper.fromJson(
        asJson(await _api.post(ApiEndpoints.users,
            body: ManagedUserMapper.newToJson(d))),
      );

  @override
  Future<void> update(
          String id, String firstName, String lastName, UserStatus status) =>
      _api.put(
        ApiEndpoints.user(id),
        body: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'status': status.apiValue,
        },
      );

  @override
  Future<void> delete(String id) => _api.delete(ApiEndpoints.user(id));
}
