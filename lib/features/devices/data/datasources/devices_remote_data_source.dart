import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/device.dart';
import '../models/device_mapper.dart';
import 'devices_data_source.dart';

class DevicesRemoteDataSource implements DevicesDataSource {
  DevicesRemoteDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<Device>> fetchAll() => fetchAllPages(
        (page, size) async => DeviceMapper.listFromJson(
          await _api.get(
            ApiEndpoints.devices,
            query: {'page': page, 'pageSize': size},
          ),
        ),
      );

  @override
  Future<ProvisionedDevice> create(DeviceDraft draft) async =>
      DeviceMapper.provisionedFromJson(
        await _api.post(ApiEndpoints.devices,
            body: DeviceMapper.draftToJson(draft)),
      );

  @override
  Future<void> update(String id, DeviceDraft draft) =>
      _api.put(ApiEndpoints.device(id), body: DeviceMapper.draftToJson(draft));

  @override
  Future<void> delete(String id) => _api.delete(ApiEndpoints.device(id));

  @override
  Future<ProvisionedDevice> rotateSecret(String id) async =>
      DeviceMapper.provisionedFromJson(
        await _api.post(ApiEndpoints.rotateSecret(id)),
      );
}
