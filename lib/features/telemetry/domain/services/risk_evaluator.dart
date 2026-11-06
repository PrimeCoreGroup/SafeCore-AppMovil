import '../../../risks/domain/entities/risk_situation.dart';
import '../entities/sensor_reading.dart';

/// Umbrales por defecto del backend (`SafetyThresholds`), que replican el
/// firmware compartido del ESP32. Los valores efectivos pueden cambiar en el
/// backend; la app los usa solo como referencia y para el modo demo.
class DetectionThresholds {
  const DetectionThresholds._();

  static const fireCelsius = 40.0;
  static const gasRiseAdcCounts = 100.0;
  static const impactDeltaCounts = 200.0;
  static const sensorFaultCelsius = -127.0;
  static const impactWindow = Duration(milliseconds: 1500);
}

/// Réplica local de la evaluación automática del backend.
///
/// Se usa para el modo demo y para explicar qué espera detectar cada prueba.
/// En modo conectado, la detección real la hace siempre el backend.
class RiskEvaluator {
  const RiskEvaluator._();

  /// [previous] = lectura anterior del mismo dispositivo y tipo.
  static RiskType? evaluate(SensorReading reading, SensorReading? previous) {
    switch (reading.sensorType) {
      case SensorType.temperature:
        final v = reading.measuredValue;
        if (v == null) return null;
        if (v == DetectionThresholds.sensorFaultCelsius) {
          return RiskType.sensorFault;
        }
        return v >= DetectionThresholds.fireCelsius ? RiskType.fire : null;
      case SensorType.gas:
        if (reading.digitalAlarm == true) return RiskType.gasOrSmoke;
        final v = reading.measuredValue;
        final p = previous?.measuredValue;
        if (v != null &&
            p != null &&
            v - p > DetectionThresholds.gasRiseAdcCounts) {
          return RiskType.gasOrSmoke;
        }
        return null;
      case SensorType.accelerometer:
        final m = reading.magnitude;
        final pm = previous?.magnitude;
        if (m != null &&
            pm != null &&
            (m - pm).abs() > DetectionThresholds.impactDeltaCounts) {
          return RiskType.earthquake;
        }
        return null;
      case SensorType.gyroscope:
      case SensorType.unknown:
        return null;
    }
  }

  /// La lectura indica que la condición terminó (resolución automática).
  static bool clears(RiskType type, SensorReading reading) => switch (type) {
        RiskType.fire => reading.sensorType == SensorType.temperature &&
            (reading.measuredValue ?? 999) < DetectionThresholds.fireCelsius &&
            !reading.isSensorFault,
        RiskType.sensorFault => reading.sensorType == SensorType.temperature &&
            !reading.isSensorFault,
        RiskType.gasOrSmoke =>
          reading.sensorType == SensorType.gas && reading.digitalAlarm == false,
        _ => false,
      };
}
