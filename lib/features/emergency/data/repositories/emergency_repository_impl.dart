import '../../../../core/storage/cached_fetch.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/data_result.dart';
import '../../domain/entities/emergency.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_data_source.dart';
import '../models/emergency_mapper.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  EmergencyRepositoryImpl(this._ds, this._cache,
      {required this.staleAfter, this.isDemo = false});

  final EmergencyDataSource _ds;
  final LocalCache _cache;
  final Duration staleAfter;
  final bool isDemo;

  @override
  Future<DataResult<EmergencyData>> getAll() => fetchWithCache(
        cache: _cache,
        key: CacheKeys.responses,
        remote: _ds.fetchAll,
        toJson: EmergencyMapper.dataToJson,
        fromJson: EmergencyMapper.dataFromJson,
        staleAfter: staleAfter,
        remoteKind: isDemo ? DataSourceKind.demo : DataSourceKind.remote,
      );

  @override
  Future<EmergencyProtocol> createProtocol(ProtocolDraft d) =>
      _ds.createProtocol(d);
  @override
  Future<void> updateProtocol(String id, ProtocolDraft d) =>
      _ds.updateProtocol(id, d);
  @override
  Future<void> deleteProtocol(String id) => _ds.deleteProtocol(id);
  @override
  Future<EmergencyResponse> createResponse(ResponseDraft d) =>
      _ds.createResponse(d);
  @override
  Future<void> updateResponse(String id, ResponseDraft d) =>
      _ds.updateResponse(id, d);
  @override
  Future<EmergencyAction> createAction(ActionDraft d) => _ds.createAction(d);
  @override
  Future<void> updateAction(String id, ActionDraft d) =>
      _ds.updateAction(id, d);
}
