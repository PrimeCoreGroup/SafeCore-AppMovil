import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/sensor_reading.dart';
import '../models/reading_mapper.dart';
import 'telemetry_data_source.dart';

class TelemetryRemoteDataSource implements TelemetryDataSource {
  TelemetryRemoteDataSource(this._api);
  final ApiClient _api;

  /// La API no filtra por dispositivo ni documenta el orden: se obtienen las
  /// páginas más recientes con [fetchNewest].
  @override
  Future<List<SensorReading>> fetchLatest({int keep = 500}) => fetchNewest(
        (page, size) async => ReadingMapper.listFromJson(
          await _api.get(
            ApiEndpoints.sensorReadings,
            query: {'page': page, 'pageSize': size},
          ),
        ),
        (r) => r.capturedAt,
        keep: keep,
      );

  @override
  Future<SensorReading> post(NewReading reading) async =>
      ReadingMapper.fromJson(
        asJson(
          await _api.post(
            ApiEndpoints.sensorReadings,
            body: ReadingMapper.newToJson(reading),
          ),
        ),
      );
}
