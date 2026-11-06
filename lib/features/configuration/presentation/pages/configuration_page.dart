import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/roles.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../telemetry/domain/services/risk_evaluator.dart';
import '../../domain/entities/system_configuration.dart';

/// Configuración de monitoreo (US19 adaptada al backend real).
class ConfigurationPage extends ConsumerWidget {
  const ConfigurationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configs = ref.watch(configurationsProvider);
    final canEdit = ref.watch(canProvider(Permission.editConfiguration));
    final repo = ref.read(configurationRepositoryProvider);

    StatusTone tone(SyncStatus s) => switch (s) {
          SyncStatus.synced => context.status.normal,
          SyncStatus.pending => context.status.warning,
          SyncStatus.failed => context.status.critical,
        };

    return ScPage(
      title: 'Configuración',
      subtitle: 'Umbrales de detección y versiones de configuración',
      onRefresh: () {
        ref.invalidate(configurationsProvider);
        return settle([ref.read(configurationsProvider.future)]);
      },
      children: [
        SectionCard(
          title: 'Umbrales de detección',
          icon: Icons.tune_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Threshold(Icons.local_fire_department_rounded, 'Fuego (DS18B20)',
                  '≥ ${DetectionThresholds.fireCelsius.toStringAsFixed(0)} °C'),
              _Threshold(Icons.air_rounded, 'Gas o humo (MQ-2)',
                  'Salida digital activa o subida > ${DetectionThresholds.gasRiseAdcCounts.toStringAsFixed(0)} cuentas ADC'),
              _Threshold(Icons.vibration_rounded, 'Impacto (MPU6050)',
                  'Cambio de magnitud > ${DetectionThresholds.impactDeltaCounts.toStringAsFixed(0)} cuentas · ventana ${DetectionThresholds.impactWindow.inMilliseconds} ms'),
              _Threshold(Icons.sensors_off_rounded, 'Falla de sensor',
                  'DS18B20 reporta ${DetectionThresholds.sensorFaultCelsius.toStringAsFixed(0)} °C'),
              const SizedBox(height: 6),
              Text(
                'Valores por defecto documentados del backend (SafetyThresholds), que replican '
                'el firmware del ESP32. El backend aún no expone un endpoint para editarlos '
                'desde la app; se modifican en el servidor. El MQ-2 requiere calibración.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        SectionHeader(
          'Versiones de configuración',
          icon: Icons.sync_rounded,
          action: canEdit
              ? TextButton.icon(
                  onPressed: () {
                    final current = configs.valueOrNull?.data;
                    final next = (current == null || current.isEmpty)
                        ? 1
                        : current
                                .map((c) => c.version)
                                .reduce((a, b) => a > b ? a : b) +
                            1;
                    runRemoteAction(
                      context,
                      ref,
                      action: () => repo.create(ConfigurationDraft(
                          version: next, syncStatus: SyncStatus.pending)),
                      successMessage:
                          'Versión $next creada (pendiente de sincronizar).',
                      auditAction: 'configuration.create',
                      invalidate: [configurationsProvider],
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nueva versión'),
                )
              : null,
        ),
        AsyncValueView(
          value: configs,
          onRetry: () => ref.invalidate(configurationsProvider),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DataFreshnessNote(r),
              if (r.data.isEmpty)
                const EmptyView(
                    title: 'Sin versiones',
                    message: 'Aún no hay configuraciones registradas.'),
              for (final c in r.data) ...[
                SectionCard(
                  child: Row(
                    children: [
                      CircleAvatar(child: Text('v${c.version}')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StatusChip(
                                label: c.syncStatus.label,
                                tone: tone(c.syncStatus)),
                            const SizedBox(height: 4),
                            Text(
                              c.lastSyncedAt == null
                                  ? 'Nunca sincronizada'
                                  : 'Sincronizada ${DateFormatter.dateTime(c.lastSyncedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (canEdit)
                        PopupMenuButton<SyncStatus>(
                          tooltip: 'Cambiar estado',
                          onSelected: (s) => runRemoteAction(
                            context,
                            ref,
                            action: () => repo.update(
                              c.id,
                              ConfigurationDraft(
                                version: c.version,
                                syncStatus: s,
                                lastSyncedAt: s == SyncStatus.synced
                                    ? DateTime.now()
                                    : c.lastSyncedAt,
                              ),
                            ),
                            successMessage:
                                'Versión ${c.version}: ${s.label.toLowerCase()}.',
                            auditAction: 'configuration.update',
                            invalidate: [configurationsProvider],
                          ),
                          itemBuilder: (_) => [
                            for (final s in SyncStatus.values)
                              if (s != c.syncStatus)
                                PopupMenuItem(value: s, child: Text(s.label)),
                          ],
                        ),
                    ],
                  ),
                ),
                kGap,
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Threshold extends StatelessWidget {
  const _Threshold(this.icon, this.title, this.value);
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(value, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
}
