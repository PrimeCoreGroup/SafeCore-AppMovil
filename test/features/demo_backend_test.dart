// @pure-dart
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/core/errors/failures.dart';
import 'package:safecore_mobile/core/security/jwt_decoder.dart';
import 'package:safecore_mobile/core/security/token_storage.dart';
import 'package:safecore_mobile/core/storage/local_cache.dart';
import 'package:safecore_mobile/core/utils/data_result.dart';
import 'package:safecore_mobile/features/authentication/data/datasources/auth_demo_data_source.dart';
import 'package:safecore_mobile/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:safecore_mobile/features/authentication/domain/services/auth_validators.dart';
import 'package:safecore_mobile/features/devices/data/datasources/devices_demo_data_source.dart';
import 'package:safecore_mobile/features/devices/domain/entities/device.dart';
import 'package:safecore_mobile/features/emergency/data/datasources/emergency_demo_data_source.dart';
import 'package:safecore_mobile/features/emergency/domain/entities/emergency.dart';
import 'package:safecore_mobile/features/notifications/data/datasources/notifications_demo_data_source.dart';
import 'package:safecore_mobile/features/risks/data/datasources/risks_demo_data_source.dart';
import 'package:safecore_mobile/features/risks/data/repositories/risks_repository_impl.dart';
import 'package:safecore_mobile/features/risks/domain/entities/risk_situation.dart';
import 'package:safecore_mobile/features/telemetry/data/datasources/telemetry_demo_data_source.dart';
import 'package:safecore_mobile/features/telemetry/data/repositories/telemetry_repository_impl.dart';
import 'package:safecore_mobile/features/telemetry/domain/entities/sensor_reading.dart';
import 'package:safecore_mobile/features/telemetry/domain/services/detection_test.dart';
import 'package:safecore_mobile/features/users/data/datasources/users_demo_data_source.dart';
import 'package:safecore_mobile/features/users/domain/entities/managed_user.dart';
import 'package:safecore_mobile/core/security/roles.dart';
import 'package:safecore_mobile/shared/services/demo/demo_data_store.dart';

import '../helpers/test_clock.dart';

void main() {
  late TestClock clock;
  late DemoDataStore store;
  var online = true;
  const stale = Duration(minutes: 5);

  void loginAs(String email) => store.currentAccount = store.accountFor(email);

  setUp(() {
    online = true;
    clock = TestClock(DateTime.now());
    store = DemoDataStore(clock: clock.call);
    loginAs('admin@demo.safecore.pe');
  });

  group('Validaciones de cuenta', () {
    test(
        'política de contraseñas del backend (12–128, mayús., minús., número, símbolo)',
        () {
      expect(AuthValidators.newPassword('Corta-1a'), contains('12'));
      expect(AuthValidators.newPassword('sinmayusculas-2026!'),
          contains('mayúscula'));
      expect(AuthValidators.newPassword('SINMINUSCULAS-2026!'),
          contains('minúscula'));
      expect(
          AuthValidators.newPassword('SinNumeros-Aqui!'), contains('número'));
      expect(
          AuthValidators.newPassword('SinSimbolo2026Ab'), contains('símbolo'));
      expect(AuthValidators.newPassword('ContraseñaDePrueba-2026!'), isNull);
      expect(AuthValidators.email('ana@example.com'), isNull);
      expect(AuthValidators.email('ana@'), isNotNull);
    });
  });

  group('Sesión (demo, mismas reglas que el backend)', () {
    late InMemoryTokenStorage tokens;
    late InMemoryLocalCache cache;
    late AuthRepositoryImpl repo;

    setUp(() {
      store.currentAccount = null;
      tokens = InMemoryTokenStorage();
      cache = InMemoryLocalCache();
      repo = AuthRepositoryImpl(
        dataSource: AuthDemoDataSource(store, isOnline: () => online),
        tokenStorage: tokens,
        cache: cache,
        demoStore: store,
        clock: clock.call,
      );
    });

    test('login guarda el token (15 min) y el último correo', () async {
      final s = await repo.login(
          email: ' Admin@Demo.SafeCore.pe ',
          password: DemoDataStore.demoPassword);
      expect(s.user.roles, equals([UserRole.administrator]));
      expect(s.expiresAt!.difference(clock.now).inMinutes,
          inInclusiveRange(14, 15));
      expect(await tokens.readToken(), s.token);
      expect(await repo.lastEmail(), 'admin@demo.safecore.pe');
    });

    test('credenciales inválidas', () async {
      await expectLater(
        () => repo.login(email: 'admin@demo.safecore.pe', password: 'x'),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('sesión expirada no se restaura', () async {
      await repo.login(
          email: 'operador@demo.safecore.pe',
          password: DemoDataStore.demoPassword);
      expect((await repo.restoreSession())?.user.firstName, 'Ana');
      clock.advance(const Duration(minutes: 16));
      expect(await repo.restoreSession(), isNull);
      expect(await tokens.readToken(), isNull);
    });

    test('cerrar sesión borra datos, conserva tema y correo', () async {
      await repo.login(
          email: 'admin@demo.safecore.pe',
          password: DemoDataStore.demoPassword);
      await cache.write(CacheKeys.risks, [1]);
      await cache.write(CacheKeys.themeMode, 'dark');
      await repo.logout();
      expect(await cache.read(CacheKeys.risks), isNull);
      expect((await cache.read(CacheKeys.themeMode))?.value, 'dark');
      expect(await repo.lastEmail(), 'admin@demo.safecore.pe');
      expect(JwtDecoder.tryDecode('x'), isNull);
    });
  });

  group('Autorización por rol (403 como en el backend)', () {
    test('residente: no ve dispositivos, sí sus notificaciones', () async {
      loginAs('residente@demo.safecore.pe');
      await expectLater(
        () => DevicesDemoDataSource(store, isOnline: () => true).fetchAll(),
        throwsA(isA<ForbiddenFailure>()),
      );
      final mine =
          await NotificationsDemoDataSource(store, isOnline: () => true)
              .fetchMine();
      expect(mine, isNotEmpty);
      expect(mine.every((n) => n.recipientUserId == 'u-resident'), isTrue);
    });

    test('respondedor: no cambia riesgos ni publica lecturas', () async {
      loginAs('respondedor@demo.safecore.pe');
      final risks = RisksDemoDataSource(store, isOnline: () => true);
      final r = (await risks.fetchAll()).first;
      await expectLater(
        () =>
            risks.update(r.id, RiskDraft.from(r, status: RiskStatus.resolved)),
        throwsA(isA<ForbiddenFailure>()),
      );
      await expectLater(
        () => TelemetryDemoDataSource(store, isOnline: () => true).post(
          NewReading(
              deviceId: 'dev-001',
              sensorType: SensorType.temperature,
              measuredValue: 20,
              capturedAt: clock.now),
        ),
        throwsA(isA<ForbiddenFailure>()),
      );
    });

    test('operador: no crea usuarios ni dispositivos', () async {
      loginAs('operador@demo.safecore.pe');
      await expectLater(
        () => UsersDemoDataSource(store, isOnline: () => true).fetchAll(),
        throwsA(isA<ForbiddenFailure>()),
      );
      await expectLater(
        () => DevicesDemoDataSource(store, isOnline: () => true)
            .create(const DeviceDraft(
          serialNumber: 'X',
          name: 'X',
          category: 'ESP32',
          connectivity: DeviceConnectivity.offline,
        )),
        throwsA(isA<ForbiddenFailure>()),
      );
    });
  });

  group('Reglas de integridad del backend', () {
    test('alta de dispositivo entrega secreto; serial duplicado = 409',
        () async {
      final ds = DevicesDemoDataSource(store, isOnline: () => true);
      const draft = DeviceDraft(
          serialNumber: 'SC-NEW-1',
          name: 'Nuevo',
          category: 'ESP32',
          connectivity: DeviceConnectivity.offline);
      final p = await ds.create(draft);
      expect(p.secret.length, greaterThanOrEqualTo(32));
      await expectLater(
          () => ds.create(draft), throwsA(isA<ConflictFailure>()));
      await expectLater(
          () => ds.delete('dev-001'), throwsA(isA<ConflictFailure>()));
      await ds.delete(p.device.id);
    });

    test('usuarios: contraseña débil 400; no puede deshabilitarse a sí mismo',
        () async {
      final ds = UsersDemoDataSource(store, isOnline: () => true);
      await expectLater(
        () => ds.create(const NewUserData(
            email: 'x@y.pe',
            password: 'debil',
            firstName: 'X',
            lastName: 'Y',
            role: UserRole.resident)),
        throwsA(isA<ValidationFailure>()),
      );
      await expectLater(
          () => ds.update('u-admin', 'C', 'L', UserStatus.disabled),
          throwsA(isA<ConflictFailure>()));
      await expectLater(
          () => ds.delete('u-resident'), throwsA(isA<ConflictFailure>()));
    });

    test('respuesta solo con protocolo activo y riesgo existente', () async {
      final ds = EmergencyDemoDataSource(store, isOnline: () => true);
      await expectLater(
        () => ds.createResponse(const ResponseDraft(
            protocolId: 'pr-old',
            emergencyType: 'Fire',
            riskSituationId: 'risk-fire-01',
            status: ResponseStatus.open)),
        throwsA(isA<ValidationFailure>()),
      );
      final r = await ds.createResponse(const ResponseDraft(
          protocolId: 'pr-fire',
          emergencyType: 'Fire',
          riskSituationId: 'risk-fire-01',
          status: ResponseStatus.open));
      expect(r.status, ResponseStatus.open);
      await expectLater(
          () => ds.deleteProtocol('pr-gas'), throwsA(isA<ConflictFailure>()));
    });

    test('ingesta: valida, detecta, deduplica y resuelve', () {
      expect(
        () => store.ingest(NewReading(
            deviceId: 'dev-001',
            sensorType: SensorType.gas,
            measuredValue: 5000,
            digitalAlarm: false,
            capturedAt: clock.now)),
        throwsA(isA<ValidationFailure>()),
      );
      expect(
        () => store.ingest(NewReading(
            deviceId: 'dev-001',
            sensorType: SensorType.temperature,
            measuredValue: 20,
            capturedAt: clock.now.add(const Duration(minutes: 6)))),
        throwsA(isA<ValidationFailure>()),
      );
      int fires() => store.risks
          .where((r) =>
              r.isActive &&
              r.deviceId == 'dev-001' &&
              r.riskType == RiskType.fire)
          .length;
      store.ingest(NewReading(
          deviceId: 'dev-001',
          sensorType: SensorType.temperature,
          measuredValue: 45,
          capturedAt: clock.now));
      expect(fires(), 1);
      store.ingest(NewReading(
          deviceId: 'dev-001',
          sensorType: SensorType.temperature,
          measuredValue: 47,
          capturedAt: clock.now));
      expect(fires(), 1);
      store.ingest(NewReading(
          deviceId: 'dev-001',
          sensorType: SensorType.temperature,
          measuredValue: 24,
          capturedAt: clock.now));
      expect(fires(), 0);
    });
  });

  group('Prueba de detección (solo confirma con respuesta del servidor)', () {
    DetectionTestRunner runner() => DetectionTestRunner(
          telemetry: TelemetryRepositoryImpl(
              TelemetryDemoDataSource(store, isOnline: () => online),
              InMemoryLocalCache(),
              staleAfter: stale),
          risks: RisksRepositoryImpl(
              RisksDemoDataSource(store, isOnline: () => online),
              InMemoryLocalCache(),
              staleAfter: stale),
          pollInterval: Duration.zero,
          timeout: const Duration(seconds: 3),
        );

    test('temperatura alta → riesgo de fuego registrado', () async {
      final phases = await runner()
          .run(scenario: DetectionScenario.highTemperature, deviceId: 'dev-001')
          .toList();
      expect(phases.last.phase, DetectionPhase.detected);
      expect(phases.last.riskId, isNotNull);
      expect(phases.map((s) => s.phase), contains(DetectionPhase.accepted));
    });

    test('gas con riesgo ya activo → deduplicado', () async {
      final last = await runner()
          .run(scenario: DetectionScenario.gasAlarm, deviceId: 'dev-002')
          .last;
      expect(last.phase, DetectionPhase.alreadyActive);
      expect(last.riskId, 'risk-gas-01');
    });

    test('impacto → riesgo de sismo', () async {
      final last = await runner()
          .run(scenario: DetectionScenario.impact, deviceId: 'dev-001')
          .last;
      expect(last.phase, DetectionPhase.detected);
    });

    test('condiciones normales resuelven riesgos automáticos', () async {
      final last = await runner()
          .run(scenario: DetectionScenario.clearConditions, deviceId: 'dev-002')
          .last;
      expect(last.phase, DetectionPhase.resolved);
      expect(store.risks.firstWhere((r) => r.id == 'risk-gas-01').status,
          RiskStatus.resolved);
    });

    test('sin permiso o sin conexión → falla, nunca éxito', () async {
      loginAs('respondedor@demo.safecore.pe');
      final a = await runner()
          .run(scenario: DetectionScenario.highTemperature, deviceId: 'dev-001')
          .last;
      expect(a.phase, DetectionPhase.failed);
      loginAs('admin@demo.safecore.pe');
      online = false;
      final b = await runner()
          .run(scenario: DetectionScenario.highTemperature, deviceId: 'dev-001')
          .last;
      expect(b.phase, DetectionPhase.failed);
    });

    test('caché offline: riesgos desde el último estado conocido', () async {
      final repo = RisksRepositoryImpl(
          RisksDemoDataSource(store, isOnline: () => online),
          InMemoryLocalCache(),
          staleAfter: stale);
      await repo.getRisks();
      online = false;
      final r = await repo.getRisks();
      expect(r.source, DataSourceKind.cache);
    });
  });
}
