import '../../../devices/domain/entities/device.dart';
import '../../../risks/domain/entities/risk_situation.dart';
import '../../../telemetry/domain/services/telemetry_summary.dart';
import '../entities/backend_health.dart';

enum ProtectionLevel {
  clear,
  attention,
  critical,
  unverified;

  String get label => switch (this) {
        ProtectionLevel.clear => 'Sin riesgos activos',
        ProtectionLevel.attention => 'Requiere atención',
        ProtectionLevel.critical => 'Crítico · Requiere revisión',
        ProtectionLevel.unverified => 'No verificable',
      };
}

class SystemAssessment {
  const SystemAssessment({
    required this.level,
    required this.reasons,
    required this.onlineDevices,
    required this.totalDevices,
    required this.openRisks,
    required this.urgentRisks,
    required this.silentDevices,
  });

  final ProtectionLevel level;
  final List<String> reasons;
  final int onlineDevices;
  final int totalDevices;
  final int openRisks;
  final int urgentRisks;
  final int silentDevices;
}

/// Evalúa el estado general a partir de los datos del backend.
///
/// Reglas de seguridad:
/// * Nunca indica "Sin riesgos activos" si faltan datos, si la información es
///   antigua, si no hay conexión o si el backend no está listo.
/// * Un riesgo urgente conocido prevalece aunque los datos sean del último
///   estado conocido.
/// * El backend no verifica actuadores: el nivel describe la telemetría y
///   los riesgos registrados, no la ejecución física de protocolos.
class SystemAssessor {
  const SystemAssessor._();

  static const silenceWindow = Duration(minutes: 15);

  static SystemAssessment assess({
    required List<Device>? devices,
    required List<RiskSituation>? risks,
    required Map<String, DeviceTelemetry>? telemetry,
    required BackendHealth? health,
    required bool canReachCloud,
    required bool dataIsStale,
    required DateTime now,
  }) {
    final reasons = <String>[];
    final deviceList = devices ?? const <Device>[];
    final active = (risks ?? const <RiskSituation>[]).where((r) => r.isActive);
    final urgent = active.where((r) => r.severity.isUrgent).length;
    final openCount = active.length;
    final online = deviceList
        .where((d) => d.connectivity == DeviceConnectivity.online)
        .length;
    final silent = telemetry == null
        ? 0
        : deviceList
            .where((d) => d.connectivity == DeviceConnectivity.online)
            .where(
              (d) => telemetry[d.id]?.isSilent(now, silenceWindow) ?? true,
            )
            .length;

    SystemAssessment build(ProtectionLevel level) => SystemAssessment(
          level: level,
          reasons: List.unmodifiable(reasons),
          onlineDevices: online,
          totalDevices: deviceList.length,
          openRisks: openCount,
          urgentRisks: urgent,
          silentDevices: silent,
        );

    // 1. Riesgos urgentes.
    if (urgent > 0) {
      reasons.add('$urgent riesgo(s) de gravedad alta o crítica sin resolver.');
      if (!canReachCloud || dataIsStale) {
        reasons.add('Datos del último estado conocido; pueden haber cambiado.');
      }
      return build(ProtectionLevel.critical);
    }

    // 2. Verificabilidad.
    if (!canReachCloud) {
      reasons.add(
          'Sin conexión con la nube: no se puede verificar el estado actual.');
    } else if (dataIsStale) {
      reasons.add('La información está desactualizada.');
    }
    if (health != null && !health.ready) {
      reasons.add(
          'El servidor de SafeCore no está listo (base de datos no disponible).');
    }
    if (devices == null) {
      reasons.add('No se pudo consultar el inventario de dispositivos.');
    } else if (deviceList.isEmpty) {
      reasons.add('No hay dispositivos registrados.');
    }
    if (risks == null) {
      reasons.add('No se pudo consultar las situaciones de riesgo.');
    }
    if (reasons.isNotEmpty) return build(ProtectionLevel.unverified);

    // 3. Advertencias.
    if (openCount > 0) {
      reasons.add('$openCount riesgo(s) abiertos o reconocidos sin resolver.');
    }
    final notOnline = deviceList.length - online;
    if (notOnline > 0) {
      reasons.add(
          '$notOnline dispositivo(s) fuera de línea, degradados o en mantenimiento.');
    }
    if (silent > 0) {
      reasons.add(
          '$silent dispositivo(s) sin lecturas en los últimos ${silenceWindow.inMinutes} min.');
    }
    if (telemetry == null) reasons.add('Sin acceso a lecturas recientes.');
    if (reasons.isNotEmpty) return build(ProtectionLevel.attention);

    reasons.add(
        'Sin riesgos abiertos, dispositivos en línea y reportando lecturas.');
    return build(ProtectionLevel.clear);
  }
}
