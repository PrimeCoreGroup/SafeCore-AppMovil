import '../../../../core/security/roles.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/sensor_reading.dart';
import 'telemetry_data_source.dart';

class TelemetryDemoDataSource extends DemoGateway
    implements TelemetryDataSource {
  TelemetryDemoDataSource(super.store, {required super.isOnline});

  @override
  Future<List<SensorReading>> fetchLatest({int keep = 500}) => call(() {
        require(Permission.viewOperations);
        final sorted = [...store.readings]
          ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
        return sorted.take(keep).toList();
      });

  @override
  Future<SensorReading> post(NewReading reading) => call(() {
        require(Permission.postReadings);
        return store.ingest(reading);
      });
}
