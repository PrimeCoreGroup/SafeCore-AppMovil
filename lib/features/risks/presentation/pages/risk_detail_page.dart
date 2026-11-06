import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../emergency/presentation/widgets/emergency_widgets.dart';
import '../../domain/entities/risk_situation.dart';
import '../../domain/services/risk_rules.dart';
import '../widgets/risk_widgets.dart';

class RiskDetailPage extends ConsumerWidget {
  const RiskDetailPage({super.key, required this.riskId});
  final String riskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final risks = ref.watch(risksProvider);
    final risk =
        risks.valueOrNull?.data.where((r) => r.id == riskId).firstOrNull;
    final devices = ref.watch(devicesProvider).valueOrNull?.data;
    final emergency = ref.watch(emergencyProvider).valueOrNull?.data;
    final canManage = ref.watch(canProvider(Permission.manageRisks));
    final canDelete = ref.watch(canProvider(Permission.deleteRisks));
    final canRespond = ref.watch(canProvider(Permission.createResponses));
    final online = ref.watch(connectivityProvider).canReachCloud;
    final repo = ref.read(risksRepositoryProvider);

    Future<void> setStatus(RiskSituation r, RiskStatus s) async {
      final ok = await showConfirmDialog(
        context,
        title: s == RiskStatus.acknowledged
            ? '¿Reconocer riesgo?'
            : '¿Marcar como resuelto?',
        message: s == RiskStatus.acknowledged
            ? 'Confirma que recibiste el aviso y que se está atendiendo. No lo resuelve.'
            : 'Confirma que la condición terminó y que el área es segura.',
        confirmLabel: s == RiskStatus.acknowledged ? 'Reconocer' : 'Resolver',
      );
      if (!ok || !context.mounted) return;
      await runRemoteAction(
        context,
        ref,
        action: () => repo.update(r.id, RiskDraft.from(r, status: s)),
        successMessage: 'Riesgo ${s.label.toLowerCase()}.',
        auditAction: 'risk.${s.name}',
        invalidate: [risksProvider],
      );
    }

    return ScPage(
      title: risk?.riskType.label ?? 'Riesgo',
      subtitle:
          risk == null ? null : 'ID ${risk.shortId} · ${risk.origin.label}',
      onRefresh: () {
        ref.invalidate(risksProvider);
        ref.invalidate(emergencyProvider);
        return settle([ref.read(risksProvider.future)]);
      },
      headerTrailing: canDelete && risk != null
          ? IconButton(
              tooltip: 'Eliminar registro',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: '¿Eliminar riesgo?',
                  message:
                      'No es posible si tiene una respuesta de emergencia vinculada.',
                  confirmLabel: 'Eliminar',
                  destructive: true,
                );
                if (!ok || !context.mounted) return;
                final done = await runRemoteAction(
                  context,
                  ref,
                  action: () => repo.delete(risk.id),
                  successMessage: 'Riesgo eliminado.',
                  auditAction: 'risk.delete',
                  invalidate: [risksProvider],
                );
                if (done && context.mounted) context.go(Routes.risks);
              },
            )
          : null,
      children: [
        AsyncValueView(
          value: risks,
          onRetry: () => ref.invalidate(risksProvider),
          data: (r) {
            if (risk == null) {
              return const EmptyView(
                  title: 'Riesgo no encontrado',
                  message: 'Pudo haber sido eliminado.');
            }
            final tone = risk.isActive
                ? severityTone(context, risk.severity)
                : context.status.normal;
            final device = deviceById(devices, risk.deviceId);
            final responses = emergency?.responsesForRisk(risk.id) ?? const [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradientHero(
                  colors: [
                    tone.foreground,
                    tone.foreground.withValues(alpha: 0.75)
                  ],
                  child: Row(
                    children: [
                      Icon(riskIcon(risk.riskType), size: 40),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${risk.status.label} · Gravedad ${risk.severity.label.toLowerCase()}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                                'Detectado ${DateFormatter.relative(risk.detectedAt)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                DataFreshnessNote(r),
                SectionCard(
                  title: 'Detalle',
                  icon: Icons.info_outline_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabeledRow(
                        LabeledValue('Tipo', risk.riskType.label),
                        LabeledValue('Origen', risk.origin.label),
                      ),
                      LabeledValue('Fecha y hora',
                          DateFormatter.dateTime(risk.detectedAt)),
                      if (risk.alertUntil != null)
                        LabeledValue('Ventana de alerta hasta',
                            DateFormatter.dateTime(risk.alertUntil!)),
                      if (device != null)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.memory_rounded),
                          title: Text(device.name),
                          subtitle: Text(device.serialNumber),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context.go(Routes.device(device.id)),
                        )
                      else if (risk.deviceId != null)
                        LabeledValue('Dispositivo', risk.deviceId!),
                    ],
                  ),
                ),
                kGap,
                SectionCard(
                  title: 'Atención',
                  icon: Icons.task_alt_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (canManage && risk.status == RiskStatus.open)
                        FilledButton.icon(
                          key: const Key('ack-risk'),
                          onPressed: online
                              ? () => setStatus(risk, RiskStatus.acknowledged)
                              : null,
                          icon: const Icon(Icons.visibility_rounded),
                          label: const Text('Reconocer'),
                        ),
                      if (canManage && risk.isActive) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: online
                              ? () => setStatus(risk, RiskStatus.resolved)
                              : null,
                          icon: const Icon(Icons.check_circle_outline_rounded),
                          label: const Text('Marcar como resuelto'),
                        ),
                      ],
                      if (canManage && !risk.isActive)
                        OutlinedButton.icon(
                          onPressed: online
                              ? () => setStatus(risk, RiskStatus.open)
                              : null,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Reabrir'),
                        ),
                      if (!canManage)
                        StatusChip(
                          label:
                              'Solo Administrador u Operador pueden cambiar el estado',
                          tone: riskStatusTone(context, risk.status),
                        ),
                      if (canRespond && risk.isActive) ...[
                        const SizedBox(height: 8),
                        FilledButton.tonalIcon(
                          onPressed: online
                              ? () =>
                                  showStartResponseSheet(context, risk: risk)
                              : null,
                          icon: const Icon(Icons.emergency_rounded),
                          label: const Text('Iniciar respuesta de emergencia'),
                        ),
                      ],
                      if (!online) ...[
                        const SizedBox(height: 8),
                        Text(kOfflineActionMessage,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                const SectionHeader('Respuestas de emergencia',
                    icon: Icons.emergency_outlined),
                if (emergency == null)
                  const LoadingView()
                else if (responses.isEmpty)
                  const SectionCard(
                    child: Text(
                        'Aún no hay respuestas de emergencia vinculadas a este riesgo.'),
                  )
                else
                  for (final resp in responses) ...[
                    ResponseTile(
                      response: resp,
                      protocol: emergency.protocol(resp.protocolId),
                      actions: emergency.actionsFor(resp.id),
                      onTap: () => context.go(Routes.response(resp.id)),
                    ),
                    kGap,
                  ],
                const SectionHeader('Recomendaciones de seguridad',
                    icon: Icons.health_and_safety_outlined),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final rec
                          in RiskRules.recommendationsFor(risk.riskType))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.shield_outlined, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(rec)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
