import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../domain/entities/device.dart';
import '../widgets/device_dialogs.dart';
import '../widgets/device_widgets.dart';

final _deviceQueryProvider = StateProvider<String>((ref) => '');
final _deviceFilterProvider = StateProvider<DeviceConnectivity?>((ref) => null);

class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final draft = await showDeviceFormSheet(context);
    if (draft == null || !context.mounted) return;
    if (!ref.read(connectivityProvider).canReachCloud) {
      showSnack(context, kOfflineActionMessage, error: true);
      return;
    }
    try {
      final p = await ref.read(devicesRepositoryProvider).create(draft);
      await ref
          .read(auditLoggerProvider)
          .log('device.create', resourceId: p.device.id);
      ref.invalidate(devicesProvider);
      if (context.mounted) await showDeviceSecretDialog(context, p);
    } catch (e) {
      if (context.mounted) {
        showSnack(context, asFailure(e).message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    final telemetry = ref.watch(telemetryByDeviceProvider);
    final risks = ref.watch(risksProvider).valueOrNull?.data;
    final query = ref.watch(_deviceQueryProvider).toLowerCase();
    final filter = ref.watch(_deviceFilterProvider);
    final isAdmin = ref.watch(canProvider(Permission.manageDevices));
    final canTest = ref.watch(canProvider(Permission.postReadings));
    final all = devices.valueOrNull?.data ?? const <Device>[];

    return ScPage(
      title: 'Dispositivos',
      subtitle: '${all.length} registrados · '
          '${all.where((d) => d.connectivity == DeviceConnectivity.online).length} en línea',
      onRefresh: () {
        ref.invalidate(devicesProvider);
        ref.invalidate(readingsProvider);
        return settle([
          ref.read(devicesProvider.future),
          ref.read(readingsProvider.future)
        ]);
      },
      headerTrailing: canTest
          ? IconButton.filledTonal(
              tooltip: 'Prueba de detección',
              onPressed: () => context.go(Routes.detectionTest),
              icon: const Icon(Icons.science_outlined),
            )
          : null,
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _create(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Registrar'),
            )
          : null,
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            hintText: 'Buscar por nombre o número de serie…',
          ),
          onChanged: (v) => ref.read(_deviceQueryProvider.notifier).state = v,
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text('Todos · ${all.length}'),
                selected: filter == null,
                onSelected: (_) =>
                    ref.read(_deviceFilterProvider.notifier).state = null,
              ),
              for (final s in DeviceConnectivity.editable) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  avatar: Icon(connectivityIcon(s), size: 16),
                  label: Text(
                      '${s.label} · ${all.where((d) => d.connectivity == s).length}'),
                  selected: filter == s,
                  onSelected: (_) =>
                      ref.read(_deviceFilterProvider.notifier).state = s,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        AsyncValueView(
          value: devices,
          onRetry: () => ref.invalidate(devicesProvider),
          data: (r) {
            final list = r.data.where((d) {
              if (filter != null && d.connectivity != filter) return false;
              if (query.isEmpty) return true;
              return d.name.toLowerCase().contains(query) ||
                  d.serialNumber.toLowerCase().contains(query) ||
                  d.category.toLowerCase().contains(query);
            }).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DataFreshnessNote(r),
                if (list.isEmpty)
                  EmptyView(
                    icon: Icons.memory_rounded,
                    title: r.data.isEmpty
                        ? 'Sin dispositivos registrados'
                        : 'Sin resultados',
                    message: r.data.isEmpty
                        ? (isAdmin
                            ? 'Registra tu primer nodo ESP32 para empezar a recibir telemetría.'
                            : 'Un administrador debe registrar los dispositivos.')
                        : 'Ningún dispositivo coincide con la búsqueda.',
                  ),
                for (final d in list) ...[
                  DeviceCard(
                    device: d,
                    telemetry: telemetry?[d.id],
                    openRisks: risks
                            ?.where((x) => x.isActive && x.deviceId == d.id)
                            .length ??
                        0,
                    onTap: () => context.go(Routes.device(d.id)),
                  ),
                  kGap,
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
