import '../entities/sensor_reading.dart';

/// Resumen por dispositivo de las lecturas recientes.
class DeviceTelemetry {
  DeviceTelemetry(this.deviceId);

  final String deviceId;

  /// Series ordenadas de la más antigua a la más reciente, por tipo.
  final Map<SensorType, List<SensorReading>> series = {};

  SensorReading? latest(SensorType t) {
    final s = series[t];
    return (s == null || s.isEmpty) ? null : s.last;
  }

  DateTime? get lastSeen {
    DateTime? best;
    for (final s in series.values) {
      if (s.isEmpty) continue;
      final d = s.last.capturedAt;
      if (best == null || d.isAfter(best)) best = d;
    }
    return best;
  }

  /// Sin lecturas durante [window] (o nunca).
  bool isSilent(DateTime now, Duration window) {
    final l = lastSeen;
    return l == null || now.difference(l) > window;
  }
}

class TelemetrySummary {
  const TelemetrySummary._();

  static Map<String, DeviceTelemetry> byDevice(
    Iterable<SensorReading> readings, {
    int maxPointsPerSeries = 30,
  }) {
    final sorted = readings.toList()
      ..sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    final map = <String, DeviceTelemetry>{};
    for (final r in sorted) {
      final dt = map.putIfAbsent(r.deviceId, () => DeviceTelemetry(r.deviceId));
      (dt.series[r.sensorType] ??= []).add(r);
    }
    for (final dt in map.values) {
      for (final e in dt.series.entries) {
        if (e.value.length > maxPointsPerSeries) {
          e.value.removeRange(0, e.value.length - maxPointsPerSeries);
        }
      }
    }
    return map;
  }
}
