import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/sensor_reading.dart';

class ReadingMapper {
  const ReadingMapper._();

  static SensorReading fromJson(Json j) => SensorReading(
        id: readString(j, 'id'),
        deviceId: readString(j, 'deviceId'),
        sensorType:
            enumFromApi(SensorType.values, j['sensorType'], SensorType.unknown),
        measuredValue: readDouble(j, 'measuredValue'),
        digitalAlarm:
            j['digitalAlarm'] is bool ? j['digitalAlarm'] as bool : null,
        axisX: readDouble(j, 'axisX'),
        axisY: readDouble(j, 'axisY'),
        axisZ: readDouble(j, 'axisZ'),
        unit: readStringOrNull(j, 'unit'),
        capturedAt: DateFormatter.tryParse(j['capturedAt']) ??
            DateFormatter.tryParse(j['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        createdAt: DateFormatter.tryParse(j['createdAt']),
      );

  static Json toJson(SensorReading r) => {
        'id': r.id,
        'deviceId': r.deviceId,
        'sensorType': r.sensorType.apiValue,
        if (r.measuredValue != null) 'measuredValue': r.measuredValue,
        if (r.digitalAlarm != null) 'digitalAlarm': r.digitalAlarm,
        if (r.axisX != null) 'axisX': r.axisX,
        if (r.axisY != null) 'axisY': r.axisY,
        if (r.axisZ != null) 'axisZ': r.axisZ,
        if (r.unit != null) 'unit': r.unit,
        'capturedAt': r.capturedAt.toUtc().toIso8601String(),
        if (r.createdAt != null)
          'createdAt': r.createdAt!.toUtc().toIso8601String(),
      };

  /// Cuerpo de `POST /api/SensorReadings` según el tipo de sensor.
  static Json newToJson(NewReading r) => {
        'deviceId': r.deviceId,
        'sensorType': r.sensorType.apiValue,
        if (!r.sensorType.isVector) 'measuredValue': r.measuredValue,
        if (r.sensorType == SensorType.gas)
          'digitalAlarm': r.digitalAlarm ?? false,
        if (r.sensorType.isVector) ...{
          'axisX': r.axisX?.round(),
          'axisY': r.axisY?.round(),
          'axisZ': r.axisZ?.round(),
        },
        if (r.unit != null) 'unit': r.unit,
        'capturedAt': r.capturedAt.toUtc().toIso8601String(),
      };

  static List<SensorReading> listFromJson(Object? raw) =>
      asJsonList(raw).map(fromJson).toList();
  static List<Json> listToJson(List<SensorReading> l) => l.map(toJson).toList();
}
