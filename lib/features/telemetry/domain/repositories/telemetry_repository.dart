import '../../../../core/utils/data_result.dart';
import '../entities/sensor_reading.dart';

abstract interface class TelemetryRepository {
  /// Lecturas más recientes (todas los dispositivos).
  Future<DataResult<List<SensorReading>>> getLatestReadings();

  /// POST /api/SensorReadings (Administrator u Operator).
  Future<SensorReading> postReading(NewReading reading);
}
