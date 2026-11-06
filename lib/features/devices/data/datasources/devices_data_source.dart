import '../../domain/entities/device.dart';

abstract interface class DevicesDataSource {
  Future<List<Device>> fetchAll();
  Future<ProvisionedDevice> create(DeviceDraft draft);
  Future<void> update(String id, DeviceDraft draft);
  Future<void> delete(String id);
  Future<ProvisionedDevice> rotateSecret(String id);
}
