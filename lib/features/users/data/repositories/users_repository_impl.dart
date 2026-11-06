import '../../../../core/storage/cached_fetch.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/data_result.dart';
import '../../domain/entities/managed_user.dart';
import '../../domain/repositories/users_repository.dart';
import '../datasources/users_data_source.dart';
import '../models/user_mapper.dart';

class UsersRepositoryImpl implements UsersRepository {
  UsersRepositoryImpl(this._ds, this._cache,
      {required this.staleAfter, this.isDemo = false});

  final UsersDataSource _ds;
  final LocalCache _cache;
  final Duration staleAfter;
  final bool isDemo;

  @override
  Future<DataResult<List<ManagedUser>>> getUsers() => fetchWithCache(
        cache: _cache,
        key: CacheKeys.users,
        remote: _ds.fetchAll,
        toJson: ManagedUserMapper.listToJson,
        fromJson: ManagedUserMapper.listFromJson,
        staleAfter: staleAfter,
        remoteKind: isDemo ? DataSourceKind.demo : DataSourceKind.remote,
      );

  @override
  Future<ManagedUser> create(NewUserData data) => _ds.create(data);

  @override
  Future<void> update(
    String id, {
    required String firstName,
    required String lastName,
    required UserStatus status,
  }) =>
      _ds.update(id, firstName, lastName, status);

  @override
  Future<void> delete(String id) => _ds.delete(id);
}
