import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../risks/presentation/widgets/risk_widgets.dart';
import '../../domain/entities/emergency.dart';
import '../widgets/emergency_widgets.dart';

class ResponseDetailPage extends ConsumerWidget {
  const ResponseDetailPage({super.key, required this.responseId});
  final String responseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(emergencyProvider);
    final bundle = data.valueOrNull?.data;
    final resp = bundle?.responses.where((r) => r.id == responseId).firstOrNull;
    final risk = ref
        .watch(risksProvider)
        .valueOrNull
        ?.data
        .where((r) => r.id == resp?.riskSituationId)
        .firstOrNull;
    final canUpdate = ref.watch(canProvider(Permission.updateResponses));
    final canActions = ref.watch(canProvider(Permission.manageActions));
    final online = ref.watch(connectivityProvider).canReachCloud;
    final repo = ref.read(emergencyRepositoryProvider);

    return ScPage(
      title: 'Respuesta de emergencia',
      subtitle: bundle?.protocol(resp?.protocolId ?? '')?.name,
      onRefresh: () {
        ref.invalidate(emergencyProvider);
        return settle([ref.read(emergencyProvider.future)]);
      },
      floatingActionButton: canActions && resp != null && resp.status.isActive
          ? FloatingActionButton.extended(
              onPressed: !online
                  ? null
                  : () async {
                      final draft = await showActionFormSheet(context,
                          responseId: resp.id);
                      if (draft == null || !context.mounted) return;
                      await runRemoteAction(
                        context,
                        ref,
                        action: () => repo.createAction(draft),
                        successMessage: 'Acción registrada.',
                        auditAction: 'action.create',
                        invalidate: [emergencyProvider],
                      );
                    },
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Acción'),
            )
          : null,
      children: [
        AsyncValueView(
          value: data,
          onRetry: () => ref.invalidate(emergencyProvider),
          data: (r) {
            if (resp == null) {
              return const EmptyView(
                  title: 'Respuesta no encontrada',
                  message: 'Pudo haber sido eliminada.');
            }
            final actions = r.data.actionsFor(resp.id);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconBadge(
                              icon: Icons.emergency_rounded,
                              tone: responseTone(context, resp.status)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              r.data.protocol(resp.protocolId)?.name ??
                                  'Protocolo',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          StatusChip(
                              label: resp.status.label,
                              tone: responseTone(context, resp.status)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LabeledRow(
                        LabeledValue('Tipo de emergencia', resp.emergencyType),
                        LabeledValue(
                            'Inicio',
                            resp.createdAt == null
                                ? '—'
                                : DateFormatter.dateTime(resp.createdAt!)),
                      ),
                      if (risk != null)
                        RiskTile(
                            risk: risk,
                            onTap: () => context.go(Routes.risk(risk.id))),
                    ],
                  ),
                ),
                if (canUpdate) ...[
                  const SectionHeader('Estado de la respuesta',
                      icon: Icons.flag_outlined),
                  SegmentedButton<ResponseStatus>(
                    segments: [
                      for (final s in ResponseStatus.values)
                        ButtonSegment(value: s, label: Text(s.label)),
                    ],
                    selected: {resp.status},
                    onSelectionChanged: !online
                        ? null
                        : (s) => runRemoteAction(
                              context,
                              ref,
                              action: () => repo.updateResponse(resp.id,
                                  ResponseDraft.from(resp, status: s.first)),
                              successMessage: 'Respuesta: ${s.first.label}.',
                              auditAction: 'response.update',
                              invalidate: [emergencyProvider],
                            ),
                  ),
                ],
                SectionHeader('Acciones de coordinación (${actions.length})',
                    icon: Icons.checklist_rounded),
                if (actions.isEmpty)
                  const SectionCard(
                      child: Text('Aún no hay acciones registradas.')),
                for (final a in actions) ...[
                  SectionCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconBadge(
                            icon: actionIcon(a.actuatorType),
                            tone: actionTone(context, a.status),
                            size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ActionDraft.actuatorLabel(a.actuatorType),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(a.instruction),
                              const SizedBox(height: 6),
                              StatusChip(
                                  label: a.status.label,
                                  tone: actionTone(context, a.status)),
                            ],
                          ),
                        ),
                        if (canActions)
                          PopupMenuButton<ActionStatus>(
                            tooltip: 'Cambiar estado',
                            enabled: online,
                            onSelected: (s) => runRemoteAction(
                              context,
                              ref,
                              action: () => repo.updateAction(
                                  a.id, ActionDraft.from(a, status: s)),
                              successMessage: 'Acción: ${s.label}.',
                              auditAction: 'action.update',
                              invalidate: [emergencyProvider],
                            ),
                            itemBuilder: (_) => [
                              for (final s in ActionStatus.values)
                                if (s != a.status)
                                  PopupMenuItem(value: s, child: Text(s.label)),
                            ],
                          ),
                      ],
                    ),
                  ),
                  kGap,
                ],
                Text(
                  '"Completada" significa que una persona la registró como hecha. '
                  'El servidor no confirma la ejecución física de actuadores.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (!online) ...[
                  const SizedBox(height: 8),
                  Text(kOfflineActionMessage,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
