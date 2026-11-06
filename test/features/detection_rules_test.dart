// @pure-dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/features/dashboard/domain/entities/backend_health.dart';
import 'package:safecore_mobile/features/dashboard/domain/services/system_assessor.dart';
import 'package:safecore_mobile/features/devices/domain/entities/device.dart';
import 'package:safecore_mobile/features/risks/domain/entities/risk_filter.dart';
import 'package:safecore_mobile/features/risks/domain/entities/risk_situation.dart';
import 'package:safecore_mobile/features/risks/domain/services/risk_rules.dart';
import 'package:safecore_mobile/features/telemetry/domain/entities/sensor_reading.dart';
import 'package:safecore_mobile/features/telemetry/domain/services/risk_evaluator.dart';
import 'package:safecore_mobile/features/telemetry/domain/services/telemetry_summary.dart';
import 'package:safecore_mobile/shared/domain/health_status.dart';

final now = DateTime(2026, 11, 6, 15);

SensorReading temp(double v, {DateTime? at, String dev = 'd1'}) =>
    SensorReading(
      id: 't$v',
      deviceId: dev,
      sensorType: SensorType.temperature,
      measuredValue: v,
      capturedAt: at ?? now,
    );

SensorReading gas(double v, {bool alarm = false}) => SensorReading(
      id: 'g$v',
      deviceId: 'd1',
      sensorType: SensorType.gas,
      measuredValue: v,
      digitalAlarm: alarm,
      capturedAt: now,
    );

SensorReading accel(double z) => SensorReading(
      id: 'a$z',
      deviceId: 'd1',
      sensorType: SensorType.accelerometer,
      axisX: 160,
      axisY: -80,
      axisZ: z,
      capturedAt: now,
    );

RiskSituation risk(
        {Severity sev = Severity.high,
        RiskStatus st = RiskStatus.open,
        String? dev = 'd1',
        RiskType type = RiskType.fire,
        DateTime? at}) =>
    RiskSituation(
        id: 'r${sev.name}${st.name}',
        riskType: type,
        status: st,
        severity: sev,
        detectedAt: at ?? now,
        deviceId: dev);

const dev = Device(
    id: 'd1',
    serialNumber: 'S1',
    name: 'N1',
    category: 'ESP32',
    connectivity: DeviceConnectivity.online);

void main() {
  group('Evaluador (réplica de los umbrales del backend)', () {
    test('DS18B20: ≥ 40 °C fuego; -127 falla; menor normal', () {
      expect(RiskEvaluator.evaluate(temp(40), null), RiskType.fire);
      expect(RiskEvaluator.evaluate(temp(39.9), null), isNull);
      expect(RiskEvaluator.evaluate(temp(-127), null), RiskType.sensorFault);
    });

    test('MQ-2: salida digital o subida > 100 cuentas', () {
      expect(RiskEvaluator.evaluate(gas(900, alarm: true), null),
          RiskType.gasOrSmoke);
      expect(RiskEvaluator.evaluate(gas(1001), gas(900)), RiskType.gasOrSmoke);
      expect(RiskEvaluator.evaluate(gas(1000), gas(900)), isNull);
      expect(RiskEvaluator.evaluate(gas(2000), null), isNull);
    });

    test('MPU6050: cambio de magnitud > 200 cuentas', () {
      expect(RiskEvaluator.evaluate(accel(16600), accel(16300)),
          RiskType.earthquake);
      expect(RiskEvaluator.evaluate(accel(16450), accel(16300)), isNull);
    });

    test('lecturas normales resuelven fuego y gas', () {
      expect(RiskEvaluator.clears(RiskType.fire, temp(24)), isTrue);
      expect(RiskEvaluator.clears(RiskType.gasOrSmoke, gas(900)), isTrue);
      expect(RiskEvaluator.clears(RiskType.fire, temp(-127)), isFalse);
    });
  });

  group('Evaluación del sistema (nunca "sin riesgos" sin verificar)', () {
    final telemetry = TelemetrySummary.byDevice(
        [temp(24, at: now.subtract(const Duration(minutes: 1)))]);
    SystemAssessment assess({
      List<Device>? devices = const [dev],
      List<RiskSituation>? risks = const [],
      Map<String, DeviceTelemetry>? tel,
      bool online = true,
      bool stale = false,
      BackendHealth? health,
      bool noTelemetry = false,
    }) =>
        SystemAssessor.assess(
          devices: devices,
          risks: risks,
          telemetry: noTelemetry ? null : (tel ?? telemetry),
          health: health ?? BackendHealth(ready: true, checkedAt: now),
          canReachCloud: online,
          dataIsStale: stale,
          now: now,
        );

    test('todo verificado → sin riesgos activos', () {
      expect(assess().level, ProtectionLevel.clear);
    });

    test('sin conexión, datos viejos, BD caída o sin datos → no verificable',
        () {
      expect(assess(online: false).level, ProtectionLevel.unverified);
      expect(assess(stale: true).level, ProtectionLevel.unverified);
      expect(assess(health: BackendHealth(ready: false, checkedAt: now)).level,
          ProtectionLevel.unverified);
      expect(assess(devices: null).level, ProtectionLevel.unverified);
      expect(assess(devices: const []).level, ProtectionLevel.unverified);
      expect(assess(risks: null).level, ProtectionLevel.unverified);
    });

    test('riesgo alto o crítico activo → crítico, incluso sin conexión', () {
      final a = assess(risks: [risk()], online: false);
      expect(a.level, ProtectionLevel.critical);
      expect(a.reasons.last, contains('último estado conocido'));
      expect(
          assess(risks: [
            risk(sev: Severity.critical, st: RiskStatus.acknowledged)
          ]).level,
          ProtectionLevel.critical);
    });

    test('advertencias → requiere atención', () {
      expect(assess(risks: [risk(sev: Severity.medium)]).level,
          ProtectionLevel.attention);
      expect(assess(risks: [risk(st: RiskStatus.resolved)]).level,
          ProtectionLevel.clear);
      expect(assess(tel: const {}).level, ProtectionLevel.attention);
      expect(assess(noTelemetry: true).level, ProtectionLevel.attention);
      expect(
        assess(devices: [
          dev,
          const Device(
              id: 'd2',
              serialNumber: 'S2',
              name: 'N2',
              category: 'ESP32',
              connectivity: DeviceConnectivity.maintenance)
        ]).level,
        ProtectionLevel.attention,
      );
    });
  });

  group('Reglas e historial de riesgos', () {
    test('prioriza abiertos y urgentes', () {
      final list = RiskRules.active([
        risk(sev: Severity.low),
        risk(sev: Severity.critical, st: RiskStatus.acknowledged),
        risk(sev: Severity.critical),
        risk(st: RiskStatus.resolved),
      ]);
      expect(list.map((r) => '${r.severity.name}/${r.status.name}'),
          equals(['critical/open', 'low/open', 'critical/acknowledged']));
    });

    test('filtro por fecha, tipo, gravedad y estado', () {
      final items = [
        risk(type: RiskType.fire, at: DateTime(2026, 11, 6, 10)),
        risk(
            type: RiskType.gasOrSmoke,
            sev: Severity.low,
            at: DateTime(2026, 11, 4)),
        risk(
            type: RiskType.earthquake,
            st: RiskStatus.resolved,
            at: DateTime(2026, 10, 1)),
      ];
      expect(
          RiskFilter(from: DateTime(2026, 11, 4), to: DateTime(2026, 11, 6))
              .apply(items),
          hasLength(2));
      expect(
          const RiskFilter(types: {RiskType.earthquake})
              .apply(items)
              .single
              .riskType,
          RiskType.earthquake);
      expect(const RiskFilter(severities: {Severity.low}).apply(items),
          hasLength(1));
      expect(const RiskFilter(statuses: {RiskStatus.resolved}).apply(items),
          hasLength(1));
      expect(RiskRules.recommendationsFor(RiskType.gasOrSmoke).join(' '),
          contains('116'));
    });
  });

  test('Resumen de telemetría por dispositivo y silencio', () {
    final s = TelemetrySummary.byDevice([
      temp(23, at: now.subtract(const Duration(minutes: 30))),
      temp(25, at: now.subtract(const Duration(minutes: 2))),
      temp(22, at: now.subtract(const Duration(hours: 2)), dev: 'd2'),
    ]);
    expect(s['d1']!.latest(SensorType.temperature)!.measuredValue, 25);
    expect(s['d1']!.isSilent(now, const Duration(minutes: 15)), isFalse);
    expect(s['d2']!.isSilent(now, const Duration(minutes: 15)), isTrue);
  });
}
