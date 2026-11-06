import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../domain/entities/risk_situation.dart';
import '../../domain/services/risk_rules.dart';
import '../widgets/risk_forms.dart';
import '../widgets/risk_widgets.dart';

/// Situaciones de riesgo: activas y resueltas (sección 5.5).
class RisksPage extends ConsumerWidget {
  const RisksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risks = ref.watch(risksProvider);
    final devices = ref.watch(devicesProvider).valueOrNull?.data;
    final canCreate = ref.watch(canProvider(Permission.manageRisks));
    final all = risks.valueOrNull?.data ?? const <RiskSituation>[];
    final active = RiskRules.active(all);
    final resolved = RiskRules.resolved(all);

    Widget list(List<RiskSituation> items, bool activeTab) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(risksProvider);
            return settle([ref.read(risksProvider.future)]);
          },
          child: AsyncValueView(
            value: risks,
            onRetry: () => ref.invalidate(risksProvider),
            data: (r) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                DataFreshnessNote(r),
                if (items.isEmpty)
                  EmptyView(
                    icon: activeTab
                        ? Icons.verified_user_outlined
                        : Icons.history_rounded,
                    title: activeTab
                        ? 'Sin riesgos activos'
                        : 'Sin riesgos resueltos',
                    message: activeTab
                        ? 'No hay situaciones de riesgo abiertas ni reconocidas.'
                        : 'Los riesgos resueltos aparecerán aquí.',
                  ),
                for (final x in items) ...[
                  RiskTile(
                    risk: x,
                    deviceName: deviceById(devices, x.deviceId)?.name,
                    onTap: () => context.go(Routes.risk(x.id)),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ScAppBar(
          title: 'Riesgos',
          actions: [
            IconButton(
              tooltip: 'Historial con filtros',
              onPressed: () => context.go(Routes.riskHistory),
              icon: const Icon(Icons.manage_search_rounded),
            ),
          ],
        ),
        floatingActionButton: canCreate
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final draft = await showRiskFormSheet(context);
                  if (draft == null || !context.mounted) return;
                  await runRemoteAction(
                    context,
                    ref,
                    action: () =>
                        ref.read(risksRepositoryProvider).create(draft),
                    successMessage: 'Riesgo registrado.',
                    auditAction: 'risk.create',
                    invalidate: [risksProvider],
                  );
                },
                icon: const Icon(Icons.add_alert_rounded),
                label: const Text('Registrar'),
              )
            : null,
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Activos (${active.length})'),
                Tab(text: 'Resueltos (${resolved.length})'),
              ],
            ),
            Expanded(
                child: TabBarView(
                    children: [list(active, true), list(resolved, false)])),
          ],
        ),
      ),
    );
  }
}
