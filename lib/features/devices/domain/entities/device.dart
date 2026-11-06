/// Estado de conectividad declarado en el backend.
enum DeviceConnectivity {
  online,
  offline,
  degraded,
  maintenance,
  unknown;

  String get label => switch (this) {
        DeviceConnectivity.online => 'En línea',
        DeviceConnectivity.offline => 'Fuera de línea',
        DeviceConnectivity.degraded => 'Degradado',
        DeviceConnectivity.maintenance => 'Mantenimiento',
        DeviceConnectivity.unknown => 'Sin información',
      };

  String get apiValue => switch (this) {
        DeviceConnectivity.online => 'Online',
        DeviceConnectivity.offline => 'Offline',
        DeviceConnectivity.degraded => 'Degraded',
        DeviceConnectivity.maintenance => 'Maintenance',
        DeviceConnectivity.unknown => 'Offline',
      };

  static const editable = [online, offline, degraded, maintenance];
}

/// Dispositivo IoT (ESP32 / nodo Edge) registrado en el backend.
class Device {
  const Device({
    required this.id,
    required this.serialNumber,
    required this.name,
    required this.category,
    required this.connectivity,
    this.createdAt,
  });

  final String id;
  final String serialNumber;
  final String name;
  final String category;
  final DeviceConnectivity connectivity;
  final DateTime? createdAt;

  Device copyWith({
    String? serialNumber,
    String? name,
    String? category,
    DeviceConnectivity? connectivity,
  }) =>
      Device(
        id: id,
        serialNumber: serialNumber ?? this.serialNumber,
        name: name ?? this.name,
        category: category ?? this.category,
        connectivity: connectivity ?? this.connectivity,
        createdAt: createdAt,
      );
}

class DeviceDraft {
  const DeviceDraft({
    required this.serialNumber,
    required this.name,
    required this.category,
    required this.connectivity,
  });

  final String serialNumber;
  final String name;
  final String category;
  final DeviceConnectivity connectivity;

  static String? validateSerial(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa el número de serie.';
    if (s.length > 100) return 'Máximo 100 caracteres.';
    return null;
  }

  static String? validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa un nombre.';
    if (s.length > 100) return 'Máximo 100 caracteres.';
    return null;
  }

  static String? validateCategory(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa la categoría (p. ej. ESP32).';
    if (s.length > 50) return 'Máximo 50 caracteres.';
    return null;
  }
}

/// Resultado de alta o rotación: el secreto en claro solo se entrega una vez.
class ProvisionedDevice {
  const ProvisionedDevice({required this.device, required this.secret});
  final Device device;
  final String secret;
}
