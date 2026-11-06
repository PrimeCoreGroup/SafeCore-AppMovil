import '../../../core/errors/failures.dart';
import '../../../core/security/roles.dart';
import '../../../features/authentication/domain/entities/app_user.dart';
import '../../../features/configuration/domain/entities/system_configuration.dart';
import '../../../features/devices/domain/entities/device.dart';
import '../../../features/emergency/domain/entities/emergency.dart';
import '../../../features/notifications/domain/entities/app_notification.dart';
import '../../../features/risks/domain/entities/risk_situation.dart';
import '../../../features/telemetry/domain/entities/sensor_reading.dart';
import '../../../features/telemetry/domain/services/risk_evaluator.dart';
import '../../../features/users/domain/entities/managed_user.dart';
import '../../domain/health_status.dart';

class DemoAccount {
  const DemoAccount({required this.user, required this.description});
  final AppUser user;
  final String description;
  String get email => user.email;
}

/// Almacén de datos FICTICIOS del modo demostración.
///
/// Reproduce el modelo del backend SafeCore (dispositivos ESP32, lecturas,
/// riesgos, emergencias, notificaciones). Ningún dato proviene de hardware.
class DemoDataStore {
  DemoDataStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now {
    _seed();
  }

  final DateTime Function() _clock;
  DateTime get now => _clock();

  static const demoPassword = 'Demo-2026!';

  static final accounts = <DemoAccount>[
    const DemoAccount(
      user: AppUser(
        id: 'u-admin',
        email: 'admin@demo.safecore.pe',
        firstName: 'Carlos',
        lastName: 'López',
        roles: [UserRole.administrator],
      ),
      description: 'Administrador',
    ),
    const DemoAccount(
      user: AppUser(
        id: 'u-operator',
        email: 'operador@demo.safecore.pe',
        firstName: 'Ana',
        lastName: 'Pérez',
        roles: [UserRole.operator],
      ),
      description: 'Operador',
    ),
    const DemoAccount(
      user: AppUser(
        id: 'u-responder',
        email: 'respondedor@demo.safecore.pe',
        firstName: 'Luis',
        lastName: 'Torres',
        roles: [UserRole.responder],
      ),
      description: 'Respondedor',
    ),
    const DemoAccount(
      user: AppUser(
        id: 'u-resident',
        email: 'residente@demo.safecore.pe',
        firstName: 'Rosa',
        lastName: 'Quispe',
        roles: [UserRole.resident],
      ),
      description: 'Residente',
    ),
  ];

  DemoAccount? accountFor(String email) {
    final e = email.trim().toLowerCase();
    for (final a in accounts) {
      if (a.email == e) return a;
    }
    return null;
  }

  DemoAccount? currentAccount;

  final List<Device> devices = [];
  final List<SensorReading> readings = [];
  final List<RiskSituation> risks = [];
  final List<EmergencyProtocol> protocols = [];
  final List<EmergencyResponse> responses = [];
  final List<EmergencyAction> actions = [];
  final List<AppNotification> notifications = [];
  final List<ManagedUser> users = [];
  final List<SystemConfiguration> configurations = [];

  int _seq = 1000;
  String newId(String prefix) => '$prefix-${++_seq}';

  DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
      now.subtract(Duration(days: days, hours: hours, minutes: minutes));

  void _seed() {
    devices.addAll([
      Device(
        id: 'dev-001',
        serialNumber: 'SC-LAB-001',
        name: 'Nodo Torre Norte',
        category: 'ESP32',
        connectivity: DeviceConnectivity.online,
        createdAt: _ago(days: 40),
      ),
      Device(
        id: 'dev-002',
        serialNumber: 'SC-LAB-002',
        name: 'Nodo Cocina comunal',
        category: 'ESP32',
        connectivity: DeviceConnectivity.online,
        createdAt: _ago(days: 40),
      ),
      Device(
        id: 'dev-003',
        serialNumber: 'SC-LAB-003',
        name: 'Nodo Sótano',
        category: 'ESP32',
        connectivity: DeviceConnectivity.degraded,
        createdAt: _ago(days: 25),
      ),
    ]);

    // Series de 40 minutos (1 lectura/min) para los nodos 1 y 2.
    for (var m = 40; m >= 0; m--) {
      final t = _ago(minutes: m);
      for (final d in ['dev-001', 'dev-002']) {
        final k = d == 'dev-001' ? 0.0 : 1.5;
        readings.add(
          SensorReading(
            id: newId('rd'),
            deviceId: d,
            sensorType: SensorType.temperature,
            measuredValue: 23.5 + k + (m % 5) * 0.2,
            unit: 'C',
            capturedAt: t,
          ),
        );
        final spike = d == 'dev-002' && m <= 10;
        readings.add(
          SensorReading(
            id: newId('rd'),
            deviceId: d,
            sensorType: SensorType.gas,
            measuredValue: spike ? 1840 - m * 12.0 : 900 + (m % 7) * 9.0,
            digitalAlarm: spike && m <= 6,
            unit: 'esp32-adc-counts',
            capturedAt: t,
          ),
        );
        readings.add(
          SensorReading(
            id: newId('rd'),
            deviceId: d,
            sensorType: SensorType.accelerometer,
            axisX: 160.0 + (m % 3) * 4,
            axisY: -80.0 - (m % 4) * 3,
            axisZ: 16300.0 + (m % 5) * 6,
            unit: 'mpu6050-counts',
            capturedAt: t,
          ),
        );
      }
    }
    // Nodo 3: falla del DS18B20 hace 3 horas y luego sin lecturas.
    readings.add(
      SensorReading(
        id: newId('rd'),
        deviceId: 'dev-003',
        sensorType: SensorType.temperature,
        measuredValue: -127,
        unit: 'C',
        capturedAt: _ago(hours: 3),
      ),
    );

    risks.addAll([
      RiskSituation(
        id: 'risk-gas-01',
        riskType: RiskType.gasOrSmoke,
        status: RiskStatus.open,
        severity: Severity.high,
        detectedAt: _ago(minutes: 6),
        origin: RiskOrigin.sensor,
        deviceId: 'dev-002',
        createdAt: _ago(minutes: 6),
      ),
      RiskSituation(
        id: 'risk-fault-01',
        riskType: RiskType.sensorFault,
        status: RiskStatus.acknowledged,
        severity: Severity.low,
        detectedAt: _ago(hours: 3),
        origin: RiskOrigin.sensor,
        deviceId: 'dev-003',
        createdAt: _ago(hours: 3),
      ),
      RiskSituation(
        id: 'risk-fire-01',
        riskType: RiskType.fire,
        status: RiskStatus.resolved,
        severity: Severity.medium,
        detectedAt: _ago(days: 1, hours: 2),
        origin: RiskOrigin.sensor,
        deviceId: 'dev-001',
        createdAt: _ago(days: 1, hours: 2),
      ),
      RiskSituation(
        id: 'risk-quake-01',
        riskType: RiskType.earthquake,
        status: RiskStatus.resolved,
        severity: Severity.critical,
        detectedAt: _ago(days: 5),
        origin: RiskOrigin.manual,
        createdAt: _ago(days: 5),
      ),
    ]);

    protocols.addAll(const [
      EmergencyProtocol(
          id: 'pr-fire',
          name: 'Evacuación por incendio',
          emergencyType: 'Fire',
          isActive: true),
      EmergencyProtocol(
          id: 'pr-gas',
          name: 'Fuga de gas',
          emergencyType: 'GasOrSmoke',
          isActive: true),
      EmergencyProtocol(
          id: 'pr-quake',
          name: 'Sismo: evacuación y corte',
          emergencyType: 'Earthquake',
          isActive: true),
      EmergencyProtocol(
          id: 'pr-old',
          name: 'Protocolo 2024 (archivado)',
          emergencyType: 'Fire',
          isActive: false),
    ]);

    responses.addAll([
      EmergencyResponse(
        id: 'resp-gas-01',
        protocolId: 'pr-gas',
        emergencyType: 'GasOrSmoke',
        riskSituationId: 'risk-gas-01',
        status: ResponseStatus.inProgress,
        createdAt: _ago(minutes: 5),
      ),
      EmergencyResponse(
        id: 'resp-quake-01',
        protocolId: 'pr-quake',
        emergencyType: 'Earthquake',
        riskSituationId: 'risk-quake-01',
        status: ResponseStatus.resolved,
        createdAt: _ago(days: 5),
      ),
    ]);

    actions.addAll([
      EmergencyAction(
        id: 'act-01',
        emergencyResponseId: 'resp-gas-01',
        actuatorType: 'Valve',
        instruction: 'Cerrar válvula de gas según protocolo local.',
        status: ActionStatus.dispatched,
        createdAt: _ago(minutes: 5),
      ),
      EmergencyAction(
        id: 'act-02',
        emergencyResponseId: 'resp-gas-01',
        actuatorType: 'Relay',
        instruction: 'Verificar corte eléctrico de la cocina comunal.',
        status: ActionStatus.completed,
        createdAt: _ago(minutes: 4),
      ),
      EmergencyAction(
        id: 'act-03',
        emergencyResponseId: 'resp-gas-01',
        actuatorType: 'Light',
        instruction: 'Confirmar iluminación de la ruta de evacuación.',
        status: ActionStatus.pending,
        createdAt: _ago(minutes: 3),
      ),
    ]);

    notifications.addAll([
      AppNotification(
        id: 'nt-01',
        recipientUserId: 'u-resident',
        title: 'Alerta de gas en cocina comunal',
        body:
            'Se detectó gas o humo en la cocina comunal. Sigue las indicaciones del personal y evita usar fuego.',
        channel: NotificationChannel.push,
        status: DeliveryStatus.delivered,
        createdAt: _ago(minutes: 5),
      ),
      AppNotification(
        id: 'nt-02',
        recipientUserId: 'u-admin',
        title: 'Sensor con falla en el sótano',
        body:
            'El DS18B20 del Nodo Sótano reportó -127 °C (sensor desconectado).',
        channel: NotificationChannel.email,
        status: DeliveryStatus.pending,
        createdAt: _ago(hours: 3),
      ),
      AppNotification(
        id: 'nt-03',
        recipientUserId: 'u-resident',
        title: 'Simulacro programado',
        body: 'El viernes a las 10:00 se realizará un simulacro de evacuación.',
        channel: NotificationChannel.push,
        status: DeliveryStatus.delivered,
        createdAt: _ago(days: 2),
      ),
    ]);

    for (final a in accounts) {
      users.add(
        ManagedUser(
          id: a.user.id,
          email: a.email,
          firstName: a.user.firstName,
          lastName: a.user.lastName,
          status: UserStatus.active,
          roles: a.user.roles,
          createdAt: _ago(days: 60),
        ),
      );
    }

    configurations.addAll([
      SystemConfiguration(
        id: 'cfg-1',
        version: 1,
        syncStatus: SyncStatus.synced,
        lastSyncedAt: _ago(days: 10),
      ),
      const SystemConfiguration(
          id: 'cfg-2', version: 2, syncStatus: SyncStatus.pending),
    ]);
  }

  /// Registra una lectura aplicando las validaciones y la evaluación
  /// automática del backend (deduplicación y resolución incluidas).
  SensorReading ingest(NewReading r) {
    if (!devices.any((d) => d.id == r.deviceId)) {
      throw const ValidationFailure('El dispositivo no existe.');
    }
    if (r.capturedAt.isAfter(now.add(const Duration(minutes: 5)))) {
      throw const ValidationFailure(
        'capturedAt no puede estar más de 5 minutos en el futuro.',
      );
    }
    if (r.sensorType == SensorType.gas) {
      final v = r.measuredValue;
      if (v == null || v < 0 || v > 4095 || r.digitalAlarm == null) {
        throw const ValidationFailure(
          'Gas requiere measuredValue (0–4095) y digitalAlarm.',
        );
      }
    } else if (r.sensorType.isVector) {
      if (r.axisX == null || r.axisY == null || r.axisZ == null) {
        throw const ValidationFailure('Se requieren los ejes X, Y y Z.');
      }
    } else if (r.measuredValue == null) {
      throw const ValidationFailure('measuredValue es obligatorio.');
    }

    final reading = SensorReading(
      id: newId('rd'),
      deviceId: r.deviceId,
      sensorType: r.sensorType,
      measuredValue: r.measuredValue,
      digitalAlarm: r.digitalAlarm,
      axisX: r.axisX,
      axisY: r.axisY,
      axisZ: r.axisZ,
      unit: r.unit,
      capturedAt: r.capturedAt,
      createdAt: now,
    );
    final previous = readings
        .where((x) => x.deviceId == r.deviceId && x.sensorType == r.sensorType)
        .fold<SensorReading?>(
          null,
          (best, x) =>
              best == null || x.capturedAt.isAfter(best.capturedAt) ? x : best,
        );
    readings.add(reading);

    final detected = RiskEvaluator.evaluate(reading, previous);
    if (detected != null) {
      final duplicate = risks.any(
        (x) => x.isActive && x.deviceId == r.deviceId && x.riskType == detected,
      );
      if (!duplicate) {
        risks.add(
          RiskSituation(
            id: newId('risk'),
            riskType: detected,
            status: RiskStatus.open,
            severity: switch (detected) {
              RiskType.earthquake => Severity.critical,
              RiskType.fire || RiskType.gasOrSmoke => Severity.high,
              _ => Severity.medium,
            },
            detectedAt: reading.capturedAt,
            origin: RiskOrigin.sensor,
            deviceId: r.deviceId,
            alertUntil: detected == RiskType.earthquake
                ? reading.capturedAt.add(DetectionThresholds.impactWindow)
                : null,
            createdAt: now,
          ),
        );
      }
    } else {
      for (var i = 0; i < risks.length; i++) {
        final x = risks[i];
        if (x.isActive &&
            x.origin == RiskOrigin.sensor &&
            x.deviceId == r.deviceId &&
            RiskEvaluator.clears(x.riskType, reading)) {
          risks[i] = x.withStatus(RiskStatus.resolved);
        }
      }
    }
    return reading;
  }
}
