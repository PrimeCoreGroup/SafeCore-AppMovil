import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../risks/presentation/widgets/risk_widgets.dart';
import '../../../telemetry/domain/entities/sensor_reading.dart';
import '../../domain/entities/device.dart';
import '../widgets/device_dialogs.dart';
import '../widgets/device_widgets.dart';

class DeviceDetailPage extends ConsumerWidget {
  const DeviceDetailPage({super.key, required this.deviceId});
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final device = deviceById(devices.valueOrNull?.data, deviceId);
    final telemetry = ref.watch(telemetryByDeviceProvider)?[deviceId];
    final readings = ref.watch(readingsProvider);
    final risks = ref
        .watch(risksProvider)
        .valueOrNull
        ?.data
        .where((r) => r.deviceId == deviceId)
        .toList();
    final isAdmin = ref.watch(canProvider(Permission.manageDevices));
    final repo = ref.read(devicesRepositoryProvider);

    Future<void> edit(Device d) async {
      final draft = await showDeviceFormSheet(context, initial: d);
      if (draft == null || !context.mounted) return;
      await runRemoteAction(
        context,
        ref,
        action: () => repo.update(d.id, draft),
        successMessage: 'Dispositivo actualizado.',
        auditAction: 'device.update',
        invalidate: [devicesProvider],
      );
    }

    Future<void> rotate(Device d) async {
      final ok = await showConfirmDialog(
        context,
        title: '¿Rotar secreto?',
        message: 'El secreto actual dejará de funcionar de inmediato. Deberás '
            'cargar el nuevo secreto en el ESP32 para que siga enviando lecturas.',
        confirmLabel: 'Rotar',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      if (!ref.read(connectivityProvider).canReachCloud) {
        showSnack(context, kOfflineActionMessage, error: true);
        return;
      }
      try {
        final p = await repo.rotateSecret(d.id);
        await ref
            .read(auditLoggerProvider)
            .log('device.rotateSecret', resourceId: d.id);
        if (context.mounted) await showDeviceSecretDialog(context, p);
      } catch (e) {
        if (context.mounted) {
          showSnack(context, asFailure(e).message, error: true);
        }
      }
    }

    Future<void> delete(Device d) async {
      final ok = await showConfirmDialog(
        context,
        title: '¿Eliminar dispositivo?',
        message: 'Solo es posible si no tiene lecturas registradas. '
            'Si las tiene, márcalo en mantenimiento o fuera de línea.',
        confirmLabel: 'Eliminar',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      final done = await runRemoteAction(
        context,
        ref,
        action: () => repo.delete(d.id),
        successMessage: 'Dispositivo eliminado.',
        auditAction: 'device.delete',
        invalidate: [devicesProvider],
      );
      if (done && context.mounted) context.go(Routes.devices);
    }

    return ScPage(
      title: device?.name ?? 'Dispositivo',
      subtitle:
          device == null ? null : '${device.serialNumber} · ${device.category}',
      onRefresh: () {
        ref.invalidate(devicesProvider);
        ref.invalidate(readingsProvider);
        return settle([
          ref.read(devicesProvider.future),
          ref.read(readingsProvider.future)
        ]);
      },
      headerTrailing: isAdmin && device != null
          ? PopupMenuButton<String>(
              tooltip: 'Opciones de administración',
              onSelected: (v) => switch (v) {
                'edit' => edit(device),
                'rotate' => rotate(device),
                _ => delete(device),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar / cambiar estado'))),
                PopupMenuItem(
                    value: 'rotate',
                    child: ListTile(
                        leading: Icon(Icons.key_rounded),
                        title: Text('Rotar secreto'))),
                PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Eliminar'))),
              ],
            )
          : null,
      children: [
        AsyncValueView(
          value: devices,
          onRetry: () => ref.invalidate(devicesProvider),
          data: (r) {
            if (device == null) {
              return const EmptyView(
                  title: 'Dispositivo no encontrado',
                  message: 'Pudo haber sido eliminado.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StatusChip(
                            label: device.connectivity.label,
                            tone:
                                connectivityTone(context, device.connectivity),
                            icon: connectivityIcon(device.connectivity),
                          ),
                          if (telemetry?.lastSeen != null)
                            StatusChip(
                              label:
                                  'Última lectura ${DateFormatter.relative(telemetry!.lastSeen!)}',
                              tone: connectivityTone(
                                  context, DeviceConnectivity.maintenance),
                              icon: Icons.schedule_rounded,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LabeledRow(
                        LabeledValue('Número de serie', device.serialNumber),
                        LabeledValue('Categoría', device.category),
                      ),
                      LabeledValue('ID', device.id),
                      if (device.createdAt != null)
                        LabeledValue('Registrado',
                            DateFormatter.dateTime(device.createdAt!)),
                    ],
                  ),
                ),
                const SectionHeader('Telemetría reciente',
                    icon: Icons.show_chart_rounded),
                if (readings.hasError && !readings.hasValue)
                  ErrorView(
                      error: readings.error!,
                      onRetry: () => ref.invalidate(readingsProvider))
                else if (telemetry == null || telemetry.series.isEmpty)
                  const SectionCard(
                    child: EmptyView(
                      icon: Icons.sensors_off_rounded,
                      title: 'Sin lecturas recientes',
                      message:
                          'El dispositivo no ha enviado telemetría en el rango consultado.',
                    ),
                  )
                else
                  for (final t in [
                    SensorType.temperature,
                    SensorType.gas,
                    SensorType.accelerometer,
                    SensorType.gyroscope
                  ])
                    if (telemetry.series[t] case final s?
                        when s.isNotEmpty) ...[
                      TelemetrySeriesCard(type: t, series: s),
                      kGap,
                    ],
                const SectionHeader('Riesgos de este dispositivo',
                    icon: Icons.warning_amber_rounded),
                if (risks == null)
                  const LoadingView()
                else if (risks.isEmpty)
                  const SectionCard(
                    child: EmptyView(
                      icon: Icons.verified_user_outlined,
                      title: 'Sin riesgos registrados',
                      message:
                          'No hay situaciones de riesgo asociadas a este dispositivo.',
                    ),
                  )
                else
                  for (final x in risks.take(5)) ...[
                    RiskTile(
                        risk: x,
                        deviceName: device.name,
                        onTap: () => context.go(Routes.risk(x.id))),
                    const SizedBox(height: 10),
                  ],
                DataFreshnessNote(r),
              ],
            );
          },
        ),
      ],
    );
  }
}
