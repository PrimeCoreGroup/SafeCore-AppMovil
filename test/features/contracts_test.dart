// @pure-dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/security/roles.dart';
import 'package:safecore_mobile/features/configuration/data/models/configuration_mapper.dart';
import 'package:safecore_mobile/features/configuration/domain/entities/system_configuration.dart';
import 'package:safecore_mobile/features/devices/data/models/device_mapper.dart';
import 'package:safecore_mobile/features/devices/domain/entities/device.dart';
import 'package:safecore_mobile/features/emergency/data/models/emergency_mapper.dart';
import 'package:safecore_mobile/features/emergency/domain/entities/emergency.dart';
import 'package:safecore_mobile/features/notifications/data/models/notification_mapper.dart';
import 'package:safecore_mobile/features/notifications/domain/entities/app_notification.dart';
import 'package:safecore_mobile/features/risks/data/models/risk_mapper.dart';
import 'package:safecore_mobile/features/risks/domain/entities/risk_situation.dart';
import 'package:safecore_mobile/features/telemetry/data/models/reading_mapper.dart';
import 'package:safecore_mobile/features/telemetry/domain/entities/sensor_reading.dart';
import 'package:safecore_mobile/features/users/data/models/user_mapper.dart';
import 'package:safecore_mobile/features/users/domain/entities/managed_user.dart';
import 'package:safecore_mobile/shared/domain/health_status.dart';

/// Contratos tomados de los ejemplos del README del backend.
void main() {
  test('Dispositivo: alta devuelve {device, deviceSecret}', () {
    final p = DeviceMapper.provisionedFromJson({
      'device': {
        'id': 'd1',
        'serialNumber': 'SC-LAB-001',
        'name': 'Sensor laboratorio',
        'category': 'ESP32',
        'connectivityStatus': 'Online',
        'createdAt': '2026-11-06T14:30:00Z',
      },
      'deviceSecret': 's3cr3t',
    });
    expect(p.secret, 's3cr3t');
    expect(p.device.connectivity, DeviceConnectivity.online);
    expect(
      DeviceMapper.draftToJson(const DeviceDraft(
        serialNumber: ' SC-LAB-001 ',
        name: 'Sensor laboratorio',
        category: 'ESP32',
        connectivity: DeviceConnectivity.maintenance,
      )),
      equals({
        'serialNumber': 'SC-LAB-001',
        'name': 'Sensor laboratorio',
        'category': 'ESP32',
        'connectivityStatus': 'Maintenance',
      }),
    );
  });

  test('Lecturas: cuerpos de POST según el tipo de sensor', () {
    final t = DateTime.utc(2026, 11, 6, 14, 30);
    expect(
      ReadingMapper.newToJson(NewReading(
        deviceId: 'd1',
        sensorType: SensorType.gas,
        measuredValue: 1840,
        digitalAlarm: false,
        unit: 'esp32-adc-counts',
        capturedAt: t,
      )),
      equals({
        'deviceId': 'd1',
        'sensorType': 'Gas',
        'measuredValue': 1840.0,
        'digitalAlarm': false,
        'unit': 'esp32-adc-counts',
        'capturedAt': '2026-11-06T14:30:00.000Z',
      }),
    );
    final accel = ReadingMapper.newToJson(NewReading(
      deviceId: 'd1',
      sensorType: SensorType.accelerometer,
      axisX: 160,
      axisY: -80,
      axisZ: 16300,
      unit: 'mpu6050-counts',
      capturedAt: t,
    ));
    expect(accel['axisZ'], 16300);
    expect(accel.containsKey('measuredValue'), isFalse);
    expect(accel.containsKey('digitalAlarm'), isFalse);
    final temp = ReadingMapper.newToJson(NewReading(
      deviceId: 'd1',
      sensorType: SensorType.temperature,
      measuredValue: 24.6,
      unit: 'C',
      capturedAt: t,
    ));
    expect(temp.containsKey('digitalAlarm'), isFalse);
  });

  test('Lectura: magnitud del acelerómetro y falla DS18B20', () {
    final r = ReadingMapper.fromJson({
      'id': 'r1',
      'deviceId': 'd1',
      'sensorType': 'Accelerometer',
      'axisX': 160,
      'axisY': -80,
      'axisZ': 16300,
      'capturedAt': '2026-11-05T20:45:00Z',
    });
    expect(r.magnitude, closeTo(16300.98, 0.1));
    final fault = ReadingMapper.fromJson({
      'id': 'r2',
      'deviceId': 'd1',
      'sensorType': 'Temperature',
      'measuredValue': -127,
      'capturedAt': '2026-11-05T20:45:00Z',
    });
    expect(fault.isSensorFault, isTrue);
    expect(fault.displayValue, 'Falla del sensor');
  });

  test('Riesgo: tipos, gravedad y PUT con cuerpo completo', () {
    final r = RiskMapper.fromJson({
      'id': 'k1',
      'riskType': 'GasOrSmoke',
      'status': 'Open',
      'severity': 'High',
      'detectedAt': '2026-11-06T14:30:00Z',
      'origin': 'Sensor',
      'deviceId': 'd1',
      'alertUntil': '2026-11-06T14:30:01.500Z',
    });
    expect(r.riskType, RiskType.gasOrSmoke);
    expect(r.severity, Severity.high);
    expect(r.origin, RiskOrigin.sensor);
    expect(
      RiskMapper.draftToJson(
          RiskDraft.from(r, status: RiskStatus.acknowledged)),
      equals({
        'riskType': 'GasOrSmoke',
        'status': 'Acknowledged',
        'severity': 'High',
        'detectedAt': '2026-11-06T14:30:00.000Z',
      }),
    );
  });

  test('Emergencias: protocolos, respuestas y acciones', () {
    final resp = EmergencyMapper.responseFromJson({
      'id': 'e1',
      'protocolId': 'p1',
      'emergencyType': 'Fire',
      'riskSituationId': 'k1',
      'status': 'InProgress',
    });
    expect(resp.status, ResponseStatus.inProgress);
    expect(
      EmergencyMapper.actionDraftToJson(const ActionDraft(
        emergencyResponseId: 'e1',
        actuatorType: 'Valve',
        instruction: 'Cerrar válvula de gas según protocolo local',
        status: ActionStatus.pending,
      )),
      equals({
        'emergencyResponseId': 'e1',
        'actuatorType': 'Valve',
        'instruction': 'Cerrar válvula de gas según protocolo local',
        'status': 'Pending',
      }),
    );
    expect(
      EmergencyMapper.protocolFromJson({
        'id': 'p',
        'name': 'Evacuación',
        'emergencyType': 'Fire',
        'isActive': true
      }).isActive,
      isTrue,
    );
  });

  test('Usuarios: respuesta con roles y alta con un rol', () {
    final u = ManagedUserMapper.fromJson({
      'id': 'u1',
      'email': 'operador@example.com',
      'firstName': 'Ana',
      'lastName': 'Pérez',
      'status': 'Disabled',
      'roles': ['Operator'],
    });
    expect(u.status, UserStatus.disabled);
    expect(u.roles, equals([UserRole.operator]));
    expect(
      ManagedUserMapper.newToJson(const NewUserData(
        email: 'Operador@Example.com ',
        password: 'ContraseñaDePrueba-2026!',
        firstName: 'Ana',
        lastName: 'Pérez',
        role: UserRole.operator,
      ))['role'],
      'Operator',
    );
  });

  test('Notificaciones y configuración', () {
    final n = NotificationMapper.fromJson({
      'id': 'n1',
      'recipientUserId': 'u1',
      'title': 'Alerta de gas',
      'body': '...',
      'channel': 'Sms',
      'status': 'Delivered',
    });
    expect(n.channel, NotificationChannel.sms);
    expect(n.status, DeliveryStatus.delivered);
    expect(n.looksUrgent, isTrue);
    final c = ConfigurationMapper.fromJson({
      'id': 'c1',
      'version': 3,
      'syncStatus': 'Synced',
      'lastSyncedAt': null
    });
    expect(c.version, 3);
    expect(c.syncStatus, SyncStatus.synced);
    expect(
        ConfigurationMapper.draftToJson(const ConfigurationDraft(
            version: 4, syncStatus: SyncStatus.pending))['lastSyncedAt'],
        isNull);
  });
}
