import 'dart:math';

import '../../../../core/errors/failures.dart';
import '../../../../core/security/roles.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/device.dart';
import 'devices_data_source.dart';

class DevicesDemoDataSource extends DemoGateway implements DevicesDataSource {
  DevicesDemoDataSource(super.store, {required super.isOnline});

  static String _secret() {
    final r = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    return List.generate(40, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  Future<List<Device>> fetchAll() => call(() {
        require(Permission.viewOperations);
        return [...store.devices]
          ..sort((a, b) => a.serialNumber.compareTo(b.serialNumber));
      });

  @override
  Future<ProvisionedDevice> create(DeviceDraft d) => call(() {
        require(Permission.manageDevices);
        if (store.devices.any((x) => x.serialNumber == d.serialNumber.trim())) {
          throw const ConflictFailure(
              'Ya existe un dispositivo con ese número de serie.');
        }
        final device = Device(
          id: store.newId('dev'),
          serialNumber: d.serialNumber.trim(),
          name: d.name.trim(),
          category: d.category.trim(),
          connectivity: d.connectivity,
          createdAt: store.now,
        );
        store.devices.add(device);
        return ProvisionedDevice(device: device, secret: _secret());
      });

  @override
  Future<void> update(String id, DeviceDraft d) => call(() {
        require(Permission.manageDevices);
        final i = store.devices.indexWhere((x) => x.id == id);
        if (i < 0) throw const NotFoundFailure();
        if (store.devices.any(
            (x) => x.id != id && x.serialNumber == d.serialNumber.trim())) {
          throw const ConflictFailure(
              'Ya existe un dispositivo con ese número de serie.');
        }
        store.devices[i] = store.devices[i].copyWith(
          serialNumber: d.serialNumber.trim(),
          name: d.name.trim(),
          category: d.category.trim(),
          connectivity: d.connectivity,
        );
      });

  @override
  Future<void> delete(String id) => call(() {
        require(Permission.manageDevices);
        if (store.readings.any((r) => r.deviceId == id)) {
          throw const ConflictFailure(
            'El dispositivo tiene lecturas registradas y no se puede eliminar. '
            'Puedes marcarlo en mantenimiento o fuera de línea.',
          );
        }
        final before = store.devices.length;
        store.devices.removeWhere((x) => x.id == id);
        if (store.devices.length == before) throw const NotFoundFailure();
      });

  @override
  Future<ProvisionedDevice> rotateSecret(String id) => call(() {
        require(Permission.manageDevices);
        final d = store.devices.where((x) => x.id == id).firstOrNull;
        if (d == null) throw const NotFoundFailure();
        return ProvisionedDevice(device: d, secret: _secret());
      });
}
