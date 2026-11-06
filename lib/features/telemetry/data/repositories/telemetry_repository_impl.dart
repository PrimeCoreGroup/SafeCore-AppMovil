import '../../../../core/storage/cached_fetch.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/data_result.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../domain/repositories/telemetry_repository.dart';
import '../datasources/telemetry_data_source.dart';
import '../models/reading_mapper.dart';

class TelemetryRepositoryImpl implements TelemetryRepository {
  TelemetryRepositoryImpl(this._ds, this._cache,
      {required this.staleAfter, this.isDemo = false});

  final TelemetryDataSource _ds;
  final LocalCache _cache;
  final Duration staleAfter;
  final bool isDemo;

  @override
  Future<DataResult<List<SensorReading>>> getLatestReadings() => fetchWithCache(
        cache: _cache,
        key: CacheKeys.readings,
        remote: () => _ds.fetchLatest(keep: 600),
        toJson: ReadingMapper.listToJson,
        fromJson: ReadingMapper.listFromJson,
        staleAfter: staleAfter,
        remoteKind: isDemo ? DataSourceKind.demo : DataSourceKind.remote,
      );

  @override
  Future<SensorReading> postReading(NewReading reading) => _ds.post(reading);
}
