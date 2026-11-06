import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/device.dart';

class DeviceMapper {
  const DeviceMapper._();

  static Device fromJson(Json j) => Device(
        id: readString(j, 'id'),
        serialNumber: readString(j, 'serialNumber'),
        name: readString(j, 'name', 'Dispositivo'),
        category: readString(j, 'category'),
        connectivity: enumFromApi(
          DeviceConnectivity.values,
          j['connectivityStatus'],
          DeviceConnectivity.unknown,
        ),
        createdAt: DateFormatter.tryParse(j['createdAt']),
      );

  static Json toJson(Device d) => {
        'id': d.id,
        'serialNumber': d.serialNumber,
        'name': d.name,
        'category': d.category,
        'connectivityStatus': d.connectivity.apiValue,
        if (d.createdAt != null)
          'createdAt': d.createdAt!.toUtc().toIso8601String(),
      };

  static Json draftToJson(DeviceDraft d) => {
        'serialNumber': d.serialNumber.trim(),
        'name': d.name.trim(),
        'category': d.category.trim(),
        'connectivityStatus': d.connectivity.apiValue,
      };

  /// `{ "device": {...}, "deviceSecret": "..." }`
  static ProvisionedDevice provisionedFromJson(Object? raw) {
    final j = asJson(raw);
    return ProvisionedDevice(
      device: fromJson(asJson(j['device'])),
      secret: readString(j, 'deviceSecret'),
    );
  }

  static List<Device> listFromJson(Object? raw) =>
      asJsonList(raw).map(fromJson).toList();
  static List<Json> listToJson(List<Device> l) => l.map(toJson).toList();
}
