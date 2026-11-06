import '../../../../shared/domain/health_status.dart';

enum RiskType {
  fire,
  gasOrSmoke,
  earthquake,
  sensorFault,
  unknown;

  String get label => switch (this) {
        RiskType.fire => 'Fuego / calor',
        RiskType.gasOrSmoke => 'Gas o humo',
        RiskType.earthquake => 'Sismo / impacto',
        RiskType.sensorFault => 'Falla de sensor',
        RiskType.unknown => 'Riesgo',
      };

  String get apiValue => switch (this) {
        RiskType.fire => 'Fire',
        RiskType.gasOrSmoke => 'GasOrSmoke',
        RiskType.earthquake => 'Earthquake',
        RiskType.sensorFault => 'SensorFault',
        RiskType.unknown => 'SensorFault',
      };

  static const selectable = [fire, gasOrSmoke, earthquake, sensorFault];
}

enum RiskStatus {
  open,
  acknowledged,
  resolved;

  String get label => switch (this) {
        RiskStatus.open => 'Abierto',
        RiskStatus.acknowledged => 'Reconocido',
        RiskStatus.resolved => 'Resuelto',
      };

  String get apiValue => switch (this) {
        RiskStatus.open => 'Open',
        RiskStatus.acknowledged => 'Acknowledged',
        RiskStatus.resolved => 'Resolved',
      };
}

enum RiskOrigin {
  sensor,
  manual,
  unknown;

  String get label => switch (this) {
        RiskOrigin.sensor => 'Detección automática (sensor)',
        RiskOrigin.manual => 'Registro manual',
        RiskOrigin.unknown => 'Sin información',
      };
}

/// Situación de riesgo (`/api/RiskSituations`).
class RiskSituation {
  const RiskSituation({
    required this.id,
    required this.riskType,
    required this.status,
    required this.severity,
    required this.detectedAt,
    this.origin = RiskOrigin.unknown,
    this.deviceId,
    this.alertUntil,
    this.createdAt,
  });

  final String id;
  final RiskType riskType;
  final RiskStatus status;
  final Severity severity;
  final DateTime detectedAt;
  final RiskOrigin origin;
  final String? deviceId;
  final DateTime? alertUntil;
  final DateTime? createdAt;

  bool get isActive => status != RiskStatus.resolved;
  String get shortId => id.length > 8 ? id.substring(0, 8).toUpperCase() : id;

  RiskSituation withStatus(RiskStatus s) => RiskSituation(
        id: id,
        riskType: riskType,
        status: s,
        severity: severity,
        detectedAt: detectedAt,
        origin: origin,
        deviceId: deviceId,
        alertUntil: alertUntil,
        createdAt: createdAt,
      );
}

/// Datos de alta/edición (PUT exige el cuerpo completo).
class RiskDraft {
  const RiskDraft({
    required this.riskType,
    required this.status,
    required this.severity,
    required this.detectedAt,
  });

  factory RiskDraft.from(RiskSituation r, {RiskStatus? status}) => RiskDraft(
        riskType: r.riskType,
        status: status ?? r.status,
        severity: r.severity,
        detectedAt: r.detectedAt,
      );

  final RiskType riskType;
  final RiskStatus status;
  final Severity severity;
  final DateTime detectedAt;
}
