import 'dart:math' as math;

/// Tipos de sensor admitidos por `POST /api/SensorReadings`.
enum SensorType {
  gas,
  temperature,
  accelerometer,
  gyroscope,
  unknown;

  String get label => switch (this) {
        SensorType.gas => 'Gas / humo (MQ-2)',
        SensorType.temperature => 'Temperatura (DS18B20)',
        SensorType.accelerometer => 'Acelerómetro (MPU6050)',
        SensorType.gyroscope => 'Giroscopio (MPU6050)',
        SensorType.unknown => 'Sensor',
      };

  String get shortLabel => switch (this) {
        SensorType.gas => 'Gas',
        SensorType.temperature => 'Temperatura',
        SensorType.accelerometer => 'Movimiento',
        SensorType.gyroscope => 'Giroscopio',
        SensorType.unknown => 'Otro',
      };

  String get apiValue => switch (this) {
        SensorType.gas => 'Gas',
        SensorType.temperature => 'Temperature',
        SensorType.accelerometer => 'Accelerometer',
        SensorType.gyroscope => 'Gyroscope',
        SensorType.unknown => 'Unknown',
      };

  bool get isVector =>
      this == SensorType.accelerometer || this == SensorType.gyroscope;
}

/// Lectura de telemetría IoT.
class SensorReading {
  const SensorReading({
    required this.id,
    required this.deviceId,
    required this.sensorType,
    required this.capturedAt,
    this.measuredValue,
    this.digitalAlarm,
    this.axisX,
    this.axisY,
    this.axisZ,
    this.unit,
    this.createdAt,
  });

  final String id;
  final String deviceId;
  final SensorType sensorType;
  final double? measuredValue;

  /// MQ-2: `true` = salida digital activa (MQ_DO en LOW).
  final bool? digitalAlarm;
  final double? axisX;
  final double? axisY;
  final double? axisZ;
  final String? unit;
  final DateTime capturedAt;
  final DateTime? createdAt;

  /// Valor -127 °C: error de lectura del DS18B20.
  bool get isSensorFault =>
      sensorType == SensorType.temperature && measuredValue == -127;

  /// Magnitud vectorial sqrt(x²+y²+z²) en cuentas crudas.
  double? get magnitude {
    final x = axisX, y = axisY, z = axisZ;
    if (x == null || y == null || z == null) return null;
    return math.sqrt(x * x + y * y + z * z);
  }

  /// Valor numérico representativo para gráficos.
  double? get plotValue => sensorType.isVector ? magnitude : measuredValue;

  String get displayValue {
    if (isSensorFault) return 'Falla del sensor';
    switch (sensorType) {
      case SensorType.temperature:
        final v = measuredValue;
        return v == null ? 'Sin lectura' : '${v.toStringAsFixed(1)} °C';
      case SensorType.gas:
        final v = measuredValue;
        final alarm = digitalAlarm == true ? ' · alarma digital' : '';
        return v == null ? 'Sin lectura' : '${v.toStringAsFixed(0)} ADC$alarm';
      case SensorType.accelerometer:
      case SensorType.gyroscope:
        final m = magnitude;
        return m == null ? 'Sin lectura' : '|a| ${m.toStringAsFixed(0)}';
      case SensorType.unknown:
        return measuredValue?.toString() ?? 'Sin lectura';
    }
  }
}

/// Lectura a registrar (pruebas de detección).
class NewReading {
  const NewReading({
    required this.deviceId,
    required this.sensorType,
    required this.capturedAt,
    this.measuredValue,
    this.digitalAlarm,
    this.axisX,
    this.axisY,
    this.axisZ,
    this.unit,
  });

  final String deviceId;
  final SensorType sensorType;
  final double? measuredValue;
  final bool? digitalAlarm;
  final double? axisX;
  final double? axisY;
  final double? axisZ;
  final String? unit;
  final DateTime capturedAt;
}
