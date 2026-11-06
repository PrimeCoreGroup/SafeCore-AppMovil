import '../../domain/entities/sensor_reading.dart';

abstract interface class TelemetryDataSource {
  Future<List<SensorReading>> fetchLatest({int keep});
  Future<SensorReading> post(NewReading reading);
}
