import '../../../../core/storage/cached_fetch.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/data_result.dart';
import '../../domain/entities/device.dart';
import '../../domain/repositories/devices_repository.dart';
import '../datasources/devices_data_source.dart';
import '../models/device_mapper.dart';

class DevicesRepositoryImpl implements DevicesRepository {
  DevicesRepositoryImpl(this._ds, this._cache,
      {required this.staleAfter, this.isDemo = false});

  final DevicesDataSource _ds;
  final LocalCache _cache;
  final Duration staleAfter;
  final bool isDemo;

  @override
  Future<DataResult<List<Device>>> getDevices() => fetchWithCache(
        cache: _cache,
        key: CacheKeys.devices,
        remote: _ds.fetchAll,
        toJson: DeviceMapper.listToJson,
        fromJson: DeviceMapper.listFromJson,
        staleAfter: staleAfter,
        remoteKind: isDemo ? DataSourceKind.demo : DataSourceKind.remote,
      );

  /// El secreto devuelto NO se almacena en ningún sitio.
  @override
  Future<ProvisionedDevice> create(DeviceDraft draft) => _ds.create(draft);

  @override
  Future<void> update(String id, DeviceDraft draft) => _ds.update(id, draft);

  @override
  Future<void> delete(String id) => _ds.delete(id);

  @override
  Future<ProvisionedDevice> rotateSecret(String id) => _ds.rotateSecret(id);
}
