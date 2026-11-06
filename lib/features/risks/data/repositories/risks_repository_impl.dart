import '../../../../core/storage/cached_fetch.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/data_result.dart';
import '../../domain/entities/risk_situation.dart';
import '../../domain/repositories/risks_repository.dart';
import '../datasources/risks_data_source.dart';
import '../models/risk_mapper.dart';

class RisksRepositoryImpl implements RisksRepository {
  RisksRepositoryImpl(this._ds, this._cache,
      {required this.staleAfter, this.isDemo = false});

  final RisksDataSource _ds;
  final LocalCache _cache;
  final Duration staleAfter;
  final bool isDemo;

  @override
  Future<DataResult<List<RiskSituation>>> getRisks() => fetchWithCache(
        cache: _cache,
        key: CacheKeys.risks,
        remote: _ds.fetchAll,
        toJson: RiskMapper.listToJson,
        fromJson: RiskMapper.listFromJson,
        staleAfter: staleAfter,
        remoteKind: isDemo ? DataSourceKind.demo : DataSourceKind.remote,
      );

  @override
  Future<RiskSituation> create(RiskDraft draft) => _ds.create(draft);

  /// Nunca se cambia el estado localmente sin la confirmación del backend.
  @override
  Future<void> update(String id, RiskDraft draft) => _ds.update(id, draft);

  @override
  Future<void> delete(String id) => _ds.delete(id);
}
