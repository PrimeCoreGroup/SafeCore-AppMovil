import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/json_utils.dart';
import '../../../../shared/domain/health_status.dart';
import '../../domain/entities/risk_situation.dart';

class RiskMapper {
  const RiskMapper._();

  static RiskSituation fromJson(Json j) => RiskSituation(
        id: readString(j, 'id'),
        riskType: enumFromApi(RiskType.values, j['riskType'], RiskType.unknown),
        status: enumFromApi(RiskStatus.values, j['status'], RiskStatus.open),
        severity: Severity.fromApi(j['severity']),
        detectedAt: DateFormatter.tryParse(j['detectedAt']) ??
            DateFormatter.tryParse(j['createdAt']) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        origin: enumFromApi(RiskOrigin.values, j['origin'], RiskOrigin.unknown),
        deviceId: readStringOrNull(j, 'deviceId'),
        alertUntil: DateFormatter.tryParse(j['alertUntil']),
        createdAt: DateFormatter.tryParse(j['createdAt']),
      );

  static Json toJson(RiskSituation r) => {
        'id': r.id,
        'riskType': r.riskType.apiValue,
        'status': r.status.apiValue,
        'severity': r.severity.apiValue,
        'detectedAt': r.detectedAt.toUtc().toIso8601String(),
        'origin': switch (r.origin) {
          RiskOrigin.sensor => 'Sensor',
          RiskOrigin.manual => 'Manual',
          RiskOrigin.unknown => null,
        },
        if (r.deviceId != null) 'deviceId': r.deviceId,
        if (r.alertUntil != null)
          'alertUntil': r.alertUntil!.toUtc().toIso8601String(),
        if (r.createdAt != null)
          'createdAt': r.createdAt!.toUtc().toIso8601String(),
      };

  static Json draftToJson(RiskDraft d) => {
        'riskType': d.riskType.apiValue,
        'status': d.status.apiValue,
        'severity': d.severity.apiValue,
        'detectedAt': d.detectedAt.toUtc().toIso8601String(),
      };

  static List<RiskSituation> listFromJson(Object? raw) =>
      asJsonList(raw).map(fromJson).toList();
  static List<Json> listToJson(List<RiskSituation> l) => l.map(toJson).toList();
}
