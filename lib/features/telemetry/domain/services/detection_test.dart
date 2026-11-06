import 'dart:async';

import '../../../../core/errors/failures.dart';
import '../../../risks/domain/entities/risk_situation.dart';
import '../../../risks/domain/repositories/risks_repository.dart';
import '../entities/sensor_reading.dart';
import '../repositories/telemetry_repository.dart';
import 'risk_evaluator.dart';

/// Escenarios de prueba de la cadena de detección del backend.
enum DetectionScenario {
  highTemperature,
  gasAlarm,
  impact,
  clearConditions;

  String get label => switch (this) {
        DetectionScenario.highTemperature => 'Temperatura alta (fuego)',
        DetectionScenario.gasAlarm => 'Gas o humo',
        DetectionScenario.impact => 'Impacto / sismo',
        DetectionScenario.clearConditions => 'Condiciones normales',
      };

  String get description => switch (this) {
        DetectionScenario.highTemperature =>
          'Envía una lectura DS18B20 de 45 °C (umbral ≥ ${DetectionThresholds.fireCelsius.toStringAsFixed(0)} °C).',
        DetectionScenario.gasAlarm =>
          'Envía una lectura MQ-2 con la salida digital activa y +200 cuentas ADC.',
        DetectionScenario.impact =>
          'Envía una lectura base y otra con un cambio de magnitud de ~1500 cuentas.',
        DetectionScenario.clearConditions =>
          'Envía temperatura de 24 °C y gas sin alarma para que el backend resuelva riesgos automáticos.',
      };

  /// Riesgo que debería crear el backend (null = se espera resolución).
  RiskType? get expectedRisk => switch (this) {
        DetectionScenario.highTemperature => RiskType.fire,
        DetectionScenario.gasAlarm => RiskType.gasOrSmoke,
        DetectionScenario.impact => RiskType.earthquake,
        DetectionScenario.clearConditions => null,
      };

  /// Lecturas a enviar, en orden.
  List<NewReading> readings({
    required String deviceId,
    required DateTime now,
    SensorReading? lastGas,
    SensorReading? lastAccel,
  }) {
    final t = now.toUtc();
    switch (this) {
      case DetectionScenario.highTemperature:
        return [
          NewReading(
              deviceId: deviceId,
              sensorType: SensorType.temperature,
              measuredValue: 45,
              unit: 'C',
              capturedAt: t),
        ];
      case DetectionScenario.gasAlarm:
        final base = lastGas?.measuredValue ?? 900;
        return [
          NewReading(
            deviceId: deviceId,
            sensorType: SensorType.gas,
            measuredValue: (base + 200).clamp(0, 4095).toDouble(),
            digitalAlarm: true,
            unit: 'esp32-adc-counts',
            capturedAt: t,
          ),
        ];
      case DetectionScenario.impact:
        final x = lastAccel?.axisX ?? 160,
            y = lastAccel?.axisY ?? -80,
            z = lastAccel?.axisZ ?? 16300;
        return [
          NewReading(
              deviceId: deviceId,
              sensorType: SensorType.accelerometer,
              axisX: x,
              axisY: y,
              axisZ: z,
              unit: 'mpu6050-counts',
              capturedAt: t.subtract(const Duration(seconds: 1))),
          NewReading(
              deviceId: deviceId,
              sensorType: SensorType.accelerometer,
              axisX: x + 900,
              axisY: y - 600,
              axisZ: z - 1200,
              unit: 'mpu6050-counts',
              capturedAt: t),
        ];
      case DetectionScenario.clearConditions:
        return [
          NewReading(
              deviceId: deviceId,
              sensorType: SensorType.temperature,
              measuredValue: 24,
              unit: 'C',
              capturedAt: t),
          NewReading(
            deviceId: deviceId,
            sensorType: SensorType.gas,
            measuredValue:
                (lastGas?.measuredValue ?? 900).clamp(0, 4095).toDouble(),
            digitalAlarm: false,
            unit: 'esp32-adc-counts',
            capturedAt: t,
          ),
        ];
    }
  }
}

enum DetectionPhase {
  preparing,
  sending,
  accepted,
  evaluating,
  detected,
  alreadyActive,
  resolved,
  notConfirmed,
  failed;

  String get label => switch (this) {
        DetectionPhase.preparing => 'Preparando lecturas de prueba',
        DetectionPhase.sending => 'Enviando lecturas al servidor',
        DetectionPhase.accepted => 'Lecturas registradas por el servidor',
        DetectionPhase.evaluating => 'Esperando la evaluación de riesgos',
        DetectionPhase.detected =>
          'Riesgo detectado y registrado por el servidor',
        DetectionPhase.alreadyActive =>
          'Ya existía un riesgo activo de ese tipo (deduplicado)',
        DetectionPhase.resolved =>
          'El servidor resolvió los riesgos automáticos',
        DetectionPhase.notConfirmed =>
          'Sin confirmación del servidor en el tiempo esperado',
        DetectionPhase.failed => 'La prueba falló',
      };

  bool get isTerminal => index >= DetectionPhase.detected.index;
  bool get isSuccess =>
      this == DetectionPhase.detected ||
      this == DetectionPhase.alreadyActive ||
      this == DetectionPhase.resolved;

  static const timeline = [preparing, sending, accepted, evaluating];
}

class DetectionStatus {
  const DetectionStatus(this.phase, {this.message, this.riskId});
  final DetectionPhase phase;
  final String? message;
  final String? riskId;
}

/// Ejecuta la prueba: solo afirma la detección cuando el servidor devuelve
/// el riesgo creado (o resuelto). Nunca se marca éxito por haber enviado.
class DetectionTestRunner {
  DetectionTestRunner({
    required this.telemetry,
    required this.risks,
    this.pollInterval = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 20),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final TelemetryRepository telemetry;
  final RisksRepository risks;
  final Duration pollInterval;
  final Duration timeout;
  final DateTime Function() _clock;

  Stream<DetectionStatus> run({
    required DetectionScenario scenario,
    required String deviceId,
    SensorReading? lastGas,
    SensorReading? lastAccel,
  }) async* {
    yield const DetectionStatus(DetectionPhase.preparing);
    final List<RiskSituation> before;
    try {
      before = (await risks.getRisks()).data;
    } catch (e) {
      yield DetectionStatus(DetectionPhase.failed,
          message: asFailure(e).message);
      return;
    }
    final expected = scenario.expectedRisk;
    final activeBefore =
        before.where((r) => r.isActive && r.deviceId == deviceId).toList();

    yield const DetectionStatus(DetectionPhase.sending);
    try {
      for (final r in scenario.readings(
        deviceId: deviceId,
        now: _clock(),
        lastGas: lastGas,
        lastAccel: lastAccel,
      )) {
        await telemetry.postReading(r);
      }
    } catch (e) {
      yield DetectionStatus(
        DetectionPhase.failed,
        message: 'El servidor rechazó la lectura: ${asFailure(e).message}',
      );
      return;
    }
    yield const DetectionStatus(DetectionPhase.accepted);
    yield const DetectionStatus(DetectionPhase.evaluating);

    final started = _clock();
    while (_clock().difference(started) < timeout) {
      await Future<void>.delayed(pollInterval);
      List<RiskSituation> now;
      try {
        now = (await risks.getRisks()).data;
      } catch (_) {
        continue;
      }
      if (expected != null) {
        final created = now.where(
          (r) =>
              r.isActive &&
              r.deviceId == deviceId &&
              r.riskType == expected &&
              !before.any((b) => b.id == r.id),
        );
        if (created.isNotEmpty) {
          yield DetectionStatus(DetectionPhase.detected,
              riskId: created.first.id);
          return;
        }
        final existing = activeBefore.where((r) => r.riskType == expected);
        if (existing.isNotEmpty &&
            now.any((r) => r.id == existing.first.id && r.isActive)) {
          yield DetectionStatus(
            DetectionPhase.alreadyActive,
            riskId: existing.first.id,
            message: 'El backend no duplica riesgos activos del mismo tipo.',
          );
          return;
        }
      } else {
        final autoBefore = activeBefore.where((r) =>
            r.origin == RiskOrigin.sensor &&
            (r.riskType == RiskType.fire ||
                r.riskType == RiskType.gasOrSmoke ||
                r.riskType == RiskType.sensorFault));
        if (autoBefore.isEmpty) {
          yield const DetectionStatus(
            DetectionPhase.resolved,
            message:
                'No había riesgos automáticos activos; las lecturas normales quedaron registradas.',
          );
          return;
        }
        final stillActive =
            autoBefore.where((b) => now.any((r) => r.id == b.id && r.isActive));
        if (stillActive.isEmpty) {
          yield const DetectionStatus(DetectionPhase.resolved);
          return;
        }
      }
    }
    yield const DetectionStatus(
      DetectionPhase.notConfirmed,
      message:
          'Las lecturas se registraron, pero el servidor no informó el resultado '
          'esperado. Revisa el historial de riesgos antes de sacar conclusiones.',
    );
  }
}
