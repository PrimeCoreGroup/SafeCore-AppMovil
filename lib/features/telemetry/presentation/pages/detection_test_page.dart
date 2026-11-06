import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/tinted_card.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../devices/presentation/widgets/device_widgets.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../domain/services/detection_test.dart';

/// Pruebas de la cadena de detección (sustituye a los simulacros remotos:
/// el backend no acciona actuadores).
class DetectionTestPage extends ConsumerStatefulWidget {
  const DetectionTestPage({super.key});

  @override
  ConsumerState<DetectionTestPage> createState() => _DetectionTestPageState();
}

class _DetectionTestPageState extends ConsumerState<DetectionTestPage> {
  String? _deviceId;
  DetectionScenario _scenario = DetectionScenario.highTemperature;
  final List<DetectionStatus> _log = [];
  StreamSubscription<DetectionStatus>? _sub;

  bool get _running => _log.isNotEmpty && !_log.last.phase.isTerminal;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start(Device device) async {
    final demo = ref.read(isDemoProvider);
    final ok = await showCriticalConfirmDialog(
      context,
      title: '¿Ejecutar "${_scenario.label}"?',
      warning: '${_scenario.description}\n\n'
          'Las lecturas se guardarán en el servidor como telemetría real de '
          '"${device.name}" y pueden crear un riesgo que deberás resolver después. '
          'No se acciona ningún actuador: relé, buzzer y luces los controla el ESP32.'
          '${demo ? '\n\nModo demostración: los datos son ficticios.' : ''}',
      acknowledgement:
          'Entiendo que se registrarán lecturas de prueba en el servidor.',
      confirmLabel: 'Ejecutar prueba',
    );
    if (!ok || !mounted) return;
    if (!ref.read(connectivityProvider).canReachCloud) {
      showSnack(context, kOfflineActionMessage, error: true);
      return;
    }
    final telemetry = ref.read(telemetryByDeviceProvider)?[device.id];
    final runner = DetectionTestRunner(
      telemetry: ref.read(telemetryRepositoryProvider),
      risks: ref.read(risksRepositoryProvider),
      pollInterval: Duration(seconds: demo ? 1 : 2),
    );
    setState(_log.clear);
    await ref
        .read(auditLoggerProvider)
        .log('detectionTest.${_scenario.name}', resourceId: device.id);
    await _sub?.cancel();
    _sub = runner
        .run(
      scenario: _scenario,
      deviceId: device.id,
      lastGas: telemetry?.latest(SensorType.gas),
      lastAccel: telemetry?.latest(SensorType.accelerometer),
    )
        .listen((s) {
      if (!mounted) return;
      setState(() => _log.add(s));
      if (s.phase.isTerminal) {
        refreshOperational(ref.invalidate);
        unawaited(ref.read(auditLoggerProvider).log(
              'detectionTest.result',
              resourceId: device.id,
              result: s.phase.name,
            ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final online = ref.watch(connectivityProvider).canReachCloud;
    return ScPage(
      title: 'Prueba de detección',
      subtitle: 'Verifica que el servidor detecte y registre riesgos',
      children: [
        const InfoNote(
          title: 'Qué verifica esta prueba',
          message:
              'Envía lecturas de prueba y espera a que el backend cree (o resuelva) '
              'el riesgo correspondiente. El éxito solo se indica cuando el servidor lo '
              'confirma. No prueba actuadores físicos.',
        ),
        if (_log.isNotEmpty) ...[
          kGap,
          _Progress(
              log: _log, onClose: _running ? null : () => setState(_log.clear))
        ],
        const SectionHeader('1. Dispositivo', icon: Icons.memory_rounded),
        AsyncValueView(
          value: devices,
          onRetry: () => ref.invalidate(devicesProvider),
          data: (r) => r.data.isEmpty
              ? const EmptyView(
                  title: 'Sin dispositivos',
                  message: 'Registra un dispositivo primero.')
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in r.data)
                      ChoiceChip(
                        avatar:
                            Icon(connectivityIcon(d.connectivity), size: 16),
                        label: Text('${d.name} · ${d.serialNumber}'),
                        selected: _deviceId == d.id,
                        onSelected: _running
                            ? null
                            : (_) => setState(() => _deviceId = d.id),
                      ),
                  ],
                ),
        ),
        const SectionHeader('2. Escenario', icon: Icons.science_outlined),
        for (final s in DetectionScenario.values) ...[
          SectionCard(
            onTap: _running ? null : () => setState(() => _scenario = s),
            color: _scenario == s ? context.status.info.background : null,
            child: Row(
              children: [
                Icon(
                  _scenario == s
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(s.description,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('run-detection-test'),
          onPressed: !online || _running || _deviceId == null
              ? null
              : () {
                  final d = deviceById(devices.valueOrNull?.data, _deviceId);
                  if (d != null) _start(d);
                },
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_running ? 'Prueba en curso…' : 'Ejecutar prueba'),
        ),
        if (!online)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(kOfflineActionMessage,
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.log, required this.onClose});
  final List<DetectionStatus> log;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final last = log.last;
    final tone = !last.phase.isTerminal
        ? context.status.info
        : last.phase.isSuccess
            ? context.status.normal
            : last.phase == DetectionPhase.failed
                ? context.status.critical
                : context.status.warning;
    final reached = log.map((s) => s.phase).toSet();
    return Semantics(
      liveRegion: true,
      child: SectionCard(
        title: 'Resultado',
        icon: Icons.fact_check_outlined,
        trailing: onClose == null
            ? null
            : IconButton(
                tooltip: 'Cerrar',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusChip(label: last.phase.label, tone: tone),
            const SizedBox(height: 12),
            for (final p in DetectionPhase.timeline)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 20,
                      child: !last.phase.isTerminal && last.phase == p
                          ? const CircularProgressIndicator(strokeWidth: 2.4)
                          : Icon(
                              reached.contains(p)
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked,
                              size: 20,
                              color: reached.contains(p)
                                  ? context.status.normal.foreground
                                  : Theme.of(context).colorScheme.outline,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.label)),
                  ],
                ),
              ),
            if (last.message != null) ...[
              const SizedBox(height: 4),
              Text(last.message!, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (last.riskId != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.risk(last.riskId!)),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Ver el riesgo registrado'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
