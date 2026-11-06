import '../../../../core/utils/data_result.dart';
import '../entities/device.dart';

abstract interface class DevicesRepository {
  Future<DataResult<List<Device>>> getDevices();
  Future<ProvisionedDevice> create(DeviceDraft draft);
  Future<void> update(String id, DeviceDraft draft);
  Future<void> delete(String id);
  Future<ProvisionedDevice> rotateSecret(String id);
}
