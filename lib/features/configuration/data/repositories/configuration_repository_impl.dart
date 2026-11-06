import '../../../../core/storage/cached_fetch.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/data_result.dart';
import '../../domain/entities/system_configuration.dart';
import '../../domain/repositories/configuration_repository.dart';
import '../datasources/configuration_data_source.dart';
import '../models/configuration_mapper.dart';

class ConfigurationRepositoryImpl implements ConfigurationRepository {
  ConfigurationRepositoryImpl(this._ds, this._cache,
      {required this.staleAfter, this.isDemo = false});

  final ConfigurationDataSource _ds;
  final LocalCache _cache;
  final Duration staleAfter;
  final bool isDemo;

  @override
  Future<DataResult<List<SystemConfiguration>>> getAll() => fetchWithCache(
        cache: _cache,
        key: CacheKeys.configurations,
        remote: () async => (await _ds.fetchAll())
          ..sort((a, b) => b.version.compareTo(a.version)),
        toJson: ConfigurationMapper.listToJson,
        fromJson: ConfigurationMapper.listFromJson,
        staleAfter: staleAfter,
        remoteKind: isDemo ? DataSourceKind.demo : DataSourceKind.remote,
      );

  @override
  Future<SystemConfiguration> create(ConfigurationDraft d) => _ds.create(d);

  @override
  Future<void> update(String id, ConfigurationDraft d) => _ds.update(id, d);
}
