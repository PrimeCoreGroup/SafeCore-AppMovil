import '../../../../shared/domain/health_status.dart';
import 'risk_situation.dart';

/// Filtros del historial (US20): fecha, tipo, gravedad y estado.
class RiskFilter {
  const RiskFilter({
    this.from,
    this.to,
    this.types = const {},
    this.severities = const {},
    this.statuses = const {},
    this.deviceId,
  });

  final DateTime? from;
  final DateTime? to;
  final Set<RiskType> types;
  final Set<Severity> severities;
  final Set<RiskStatus> statuses;
  final String? deviceId;

  bool get isEmpty =>
      from == null &&
      to == null &&
      types.isEmpty &&
      severities.isEmpty &&
      statuses.isEmpty &&
      deviceId == null;

  int get activeCount =>
      (from != null || to != null ? 1 : 0) +
      (types.isNotEmpty ? 1 : 0) +
      (severities.isNotEmpty ? 1 : 0) +
      (statuses.isNotEmpty ? 1 : 0) +
      (deviceId != null ? 1 : 0);

  bool matches(RiskSituation r) {
    final d = r.detectedAt.toLocal();
    if (from != null &&
        d.isBefore(DateTime(from!.year, from!.month, from!.day))) {
      return false;
    }
    if (to != null &&
        !d.isBefore(DateTime(to!.year, to!.month, to!.day)
            .add(const Duration(days: 1)))) {
      return false;
    }
    if (types.isNotEmpty && !types.contains(r.riskType)) return false;
    if (severities.isNotEmpty && !severities.contains(r.severity)) return false;
    if (statuses.isNotEmpty && !statuses.contains(r.status)) return false;
    if (deviceId != null && r.deviceId != deviceId) return false;
    return true;
  }

  List<RiskSituation> apply(Iterable<RiskSituation> risks) =>
      risks.where(matches).toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

  RiskFilter copyWith({
    DateTime? from,
    DateTime? to,
    bool clearDates = false,
    Set<RiskType>? types,
    Set<Severity>? severities,
    Set<RiskStatus>? statuses,
  }) =>
      RiskFilter(
        from: clearDates ? null : (from ?? this.from),
        to: clearDates ? null : (to ?? this.to),
        types: types ?? this.types,
        severities: severities ?? this.severities,
        statuses: statuses ?? this.statuses,
        deviceId: deviceId,
      );
}
