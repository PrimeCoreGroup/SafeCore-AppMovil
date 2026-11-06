import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../devices/presentation/widgets/device_widgets.dart';
import '../../../risks/domain/services/risk_rules.dart';
import '../../../risks/presentation/widgets/risk_widgets.dart';
import '../../domain/services/system_assessor.dart';
import '../providers/dashboard_providers.dart';
import 'resident_home.dart';

/// Inicio. El residente ve su propia vista (el backend solo le permite
/// consultar sus notificaciones).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canOperate = ref.watch(canProvider(Permission.viewOperations));
    return canOperate ? const _StaffDashboard() : const ResidentHome();
  }
}

class _StaffDashboard extends ConsumerWidget {
  const _StaffDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final risks = ref.watch(risksProvider);
    final devices = ref.watch(devicesProvider);
    final telemetry = ref.watch(telemetryByDeviceProvider);
    final emergency = ref.watch(emergencyProvider).valueOrNull?.data;
    final canTest = ref.watch(canProvider(Permission.postReadings));
    final deviceList = devices.valueOrNull?.data;

    Future<void> refresh() {
      refreshOperational(ref.invalidate);
      return settle([
        ref.read(risksProvider.future),
        ref.read(devicesProvider.future),
        ref.read(readingsProvider.future),
        ref.read(healthProvider.future),
      ]);
    }

    final activeResponses =
        emergency?.responses.where((r) => r.status.isActive).length;

    return Scaffold(
      appBar: const ScAppBar(),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              'Hola, ${user?.displayFirstName ?? ''}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${user?.primaryRole.label ?? ''} · ${DateFormatter.shortDateTime(DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            const _StatusHero(),
            const SizedBox(height: 16),
            _Kpis(activeResponses: activeResponses),
            SectionHeader(
              'Riesgos activos',
              icon: Icons.warning_amber_rounded,
              action: TextButton(
                onPressed: () => context.go(Routes.risks),
                child: const Text('Ver todos'),
              ),
            ),
            AsyncValueView(
              value: risks,
              onRetry: () => ref.invalidate(risksProvider),
              data: (r) {
                final active = RiskRules.active(r.data);
                if (active.isEmpty) {
                  return const SectionCard(
                    child: EmptyView(
                      icon: Icons.verified_user_outlined,
                      title: 'Sin riesgos activos',
                      message:
                          'No hay situaciones de riesgo abiertas en el servidor.',
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final x in active.take(3)) ...[
                      RiskTile(
                        risk: x,
                        deviceName: deviceById(deviceList, x.deviceId)?.name,
                        onTap: () => context.go(Routes.risk(x.id)),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (active.length > 3)
                      Text('+${active.length - 3} más',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(Routes.riskHistory),
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Historial'),
                  ),
                ),
                if (canTest) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(Routes.detectionTest),
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Prueba de detección'),
                    ),
                  ),
                ],
              ],
            ),
            SectionHeader(
              'Dispositivos',
              icon: Icons.memory_rounded,
              action: TextButton(
                onPressed: () => context.go(Routes.devices),
                child: const Text('Ver todos'),
              ),
            ),
            AsyncValueView(
              value: devices,
              onRetry: () => ref.invalidate(devicesProvider),
              data: (d) => d.data.isEmpty
                  ? const SectionCard(
                      child: EmptyView(
                        icon: Icons.memory_rounded,
                        title: 'Sin dispositivos',
                        message:
                            'Un administrador debe registrar los nodos ESP32.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final dev in d.data.take(3)) ...[
                          DeviceCard(
                            device: dev,
                            telemetry: telemetry?[dev.id],
                            openRisks: risks.valueOrNull?.data
                                    .where((x) =>
                                        x.isActive && x.deviceId == dev.id)
                                    .length ??
                                0,
                            onTap: () => context.go(Routes.device(dev.id)),
                          ),
                          const SizedBox(height: 10),
                        ],
                        DataFreshnessNote(d),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'El backend registra telemetría y riesgos; no acciona actuadores. '
              'Relé, buzzer y luces los controla localmente el ESP32.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHero extends ConsumerWidget {
  const _StatusHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(systemAssessmentProvider);
    final colors = switch (a.level) {
      ProtectionLevel.clear => null,
      ProtectionLevel.attention => const [Color(0xFFB45309), Color(0xFFD97706)],
      ProtectionLevel.critical => const [Color(0xFFB91C1C), Color(0xFFE11D48)],
      ProtectionLevel.unverified => const [
          Color(0xFF334155),
          Color(0xFF64748B)
        ],
    };
    final icon = switch (a.level) {
      ProtectionLevel.clear => Icons.verified_user_rounded,
      ProtectionLevel.attention => Icons.warning_amber_rounded,
      ProtectionLevel.critical => Icons.report_rounded,
      ProtectionLevel.unverified => Icons.help_outline_rounded,
    };
    final ratio = a.totalDevices == 0 ? 0.0 : a.onlineDevices / a.totalDevices;
    return Semantics(
      label: 'Estado del sistema: ${a.level.label}',
      child: GradientHero(
        colors: colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusRing(
                    icon: icon,
                    progress:
                        a.level == ProtectionLevel.unverified ? 0 : ratio),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado del sistema',
                        style: TextStyle(
                            color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        a.level.label,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final r in a.reasons.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: Colors.white)),
                    Expanded(
                        child: Text(r,
                            style: const TextStyle(color: Colors.white))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Kpis extends ConsumerWidget {
  const _Kpis({required this.activeResponses});
  final int? activeResponses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(systemAssessmentProvider);
    final health = ref.watch(healthProvider);
    final serverTone = health.when(
      data: (h) => h.ready ? context.status.normal : context.status.warning,
      loading: () => context.status.info,
      error: (_, __) => context.status.offline,
    );
    final serverText = health.when(
      data: (h) => h.ready ? 'En línea' : 'BD no lista',
      loading: () => '…',
      error: (_, __) => 'Sin contacto',
    );
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        MetricTile(
          icon: Icons.warning_amber_rounded,
          value: '${a.openRisks}',
          label: '${a.urgentRisks} urgentes · riesgos abiertos',
          tone: a.urgentRisks > 0 ? context.status.critical : null,
          onTap: () => context.go(Routes.risks),
        ),
        MetricTile(
          icon: Icons.memory_rounded,
          value: '${a.onlineDevices} / ${a.totalDevices}',
          label: 'Dispositivos en línea',
          tone: a.onlineDevices < a.totalDevices
              ? context.status.warning
              : context.status.normal,
          onTap: () => context.go(Routes.devices),
        ),
        MetricTile(
          icon: Icons.emergency_rounded,
          value: activeResponses == null ? '—' : '$activeResponses',
          label: 'Respuestas de emergencia activas',
          onTap: () => context.go(Routes.emergency),
        ),
        MetricTile(
          icon: Icons.dns_rounded,
          value: serverText,
          label: 'Servidor y base de datos',
          tone: serverTone,
          onTap: () => ref.invalidate(healthProvider),
        ),
      ],
    );
  }
}
