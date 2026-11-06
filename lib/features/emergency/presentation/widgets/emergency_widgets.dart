import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../risks/domain/entities/risk_situation.dart';
import '../../domain/entities/emergency.dart';

StatusTone responseTone(BuildContext c, ResponseStatus s) => switch (s) {
      ResponseStatus.open => c.status.critical,
      ResponseStatus.inProgress => c.status.warning,
      ResponseStatus.resolved => c.status.normal,
      ResponseStatus.cancelled => c.status.offline,
    };

StatusTone actionTone(BuildContext c, ActionStatus s) => switch (s) {
      ActionStatus.pending => c.status.offline,
      ActionStatus.dispatched => c.status.info,
      ActionStatus.completed => c.status.normal,
      ActionStatus.failed => c.status.critical,
      ActionStatus.cancelled => c.status.offline,
    };

IconData actionIcon(String actuator) => switch (actuator.toLowerCase()) {
      'relay' => Icons.power_off_rounded,
      'valve' => Icons.gas_meter_outlined,
      'buzzer' => Icons.campaign_rounded,
      'light' => Icons.emergency_rounded,
      'doorlock' => Icons.door_front_door_outlined,
      'sprinkler' => Icons.shower_outlined,
      _ => Icons.settings_input_component_rounded,
    };

class ResponseTile extends StatelessWidget {
  const ResponseTile(
      {super.key,
      required this.response,
      this.protocol,
      this.actions = const [],
      this.onTap});

  final EmergencyResponse response;
  final EmergencyProtocol? protocol;
  final List<EmergencyAction> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = responseTone(context, response.status);
    final open = actions.where((a) => a.status.isOpen).length;
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: Icons.emergency_rounded, tone: tone),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(protocol?.name ?? 'Protocolo ${response.protocolId}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  [
                    response.emergencyType,
                    if (response.createdAt != null)
                      DateFormatter.shortDateTime(response.createdAt!),
                    '${actions.length} acción(es)${open > 0 ? ', $open abiertas' : ''}',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusChip(label: response.status.label, tone: tone),
        ],
      ),
    );
  }
}

/// Inicia una respuesta de emergencia para un riesgo (US: coordinación).
Future<void> showStartResponseSheet(BuildContext context,
        {required RiskSituation risk}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _StartResponseSheet(risk: risk),
    );

class _StartResponseSheet extends ConsumerStatefulWidget {
  const _StartResponseSheet({required this.risk});
  final RiskSituation risk;

  @override
  ConsumerState<_StartResponseSheet> createState() =>
      _StartResponseSheetState();
}

class _StartResponseSheetState extends ConsumerState<_StartResponseSheet> {
  String? _protocolId;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(emergencyProvider).valueOrNull?.data;
    final protocols = data?.protocols.where((p) => p.isActive).toList() ??
        const <EmergencyProtocol>[];
    final suggested = protocols
        .where((p) =>
            p.emergencyType.toLowerCase() ==
            widget.risk.riskType.apiValue.toLowerCase())
        .map((p) => p.id)
        .toSet();
    _protocolId ??= suggested.isEmpty ? null : suggested.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Iniciar respuesta',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
              'Riesgo: ${widget.risk.riskType.label} · ${widget.risk.severity.label}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          Text('Protocolo activo',
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (data == null)
            const LinearProgressIndicator()
          else if (protocols.isEmpty)
            const Text(
                'No hay protocolos activos. Un administrador u operador debe crearlos.')
          else
            for (final p in protocols)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(_protocolId == p.id
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off),
                  title: Text(p.name),
                  subtitle: Text(
                      '${p.emergencyType}${suggested.contains(p.id) ? ' · sugerido' : ''}'),
                  onTap: () => setState(() => _protocolId = p.id),
                ),
              ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy || _protocolId == null
                ? null
                : () async {
                    if (!ref.read(connectivityProvider).canReachCloud) {
                      showSnack(context, kOfflineActionMessage, error: true);
                      return;
                    }
                    setState(() => _busy = true);
                    try {
                      final p =
                          protocols.firstWhere((x) => x.id == _protocolId);
                      final resp = await ref
                          .read(emergencyRepositoryProvider)
                          .createResponse(
                            ResponseDraft(
                              protocolId: p.id,
                              emergencyType: p.emergencyType,
                              riskSituationId: widget.risk.id,
                              status: ResponseStatus.open,
                            ),
                          );
                      await ref
                          .read(auditLoggerProvider)
                          .log('response.create', resourceId: resp.id);
                      ref.invalidate(emergencyProvider);
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      context.go(Routes.response(resp.id));
                    } catch (e) {
                      if (context.mounted) {
                        showSnack(context, asFailure(e).message, error: true);
                      }
                      setState(() => _busy = false);
                    }
                  },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(_busy ? 'Creando…' : 'Iniciar respuesta'),
          ),
        ],
      ),
    );
  }
}

/// Formulario de acción de coordinación.
Future<ActionDraft?> showActionFormSheet(BuildContext context,
        {required String responseId}) =>
    showModalBottomSheet<ActionDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _ActionForm(responseId: responseId),
    );

class _ActionForm extends StatefulWidget {
  const _ActionForm({required this.responseId});
  final String responseId;

  @override
  State<_ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<_ActionForm> {
  final _form = GlobalKey<FormState>();
  final _actuator = TextEditingController(text: 'Relay');
  final _instruction = TextEditingController();

  @override
  void dispose() {
    _actuator.dispose();
    _instruction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Registrar acción',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Es un registro de coordinación para el equipo: no envía comandos al ESP32.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final a in ActionDraft.suggestedActuators)
                    ChoiceChip(
                      avatar: Icon(actionIcon(a), size: 16),
                      label: Text(ActionDraft.actuatorLabel(a)),
                      selected: _actuator.text == a,
                      onSelected: (_) => setState(() => _actuator.text = a),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _actuator,
                decoration:
                    const InputDecoration(labelText: 'Tipo de actuador'),
                validator: ActionDraft.validateActuator,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _instruction,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                    labelText: 'Instrucción',
                    hintText: 'Cerrar válvula de gas según protocolo local'),
                validator: ActionDraft.validateInstruction,
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  if (!(_form.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop(
                    ActionDraft(
                      emergencyResponseId: widget.responseId,
                      actuatorType: _actuator.text,
                      instruction: _instruction.text,
                      status: ActionStatus.pending,
                    ),
                  );
                },
                child: const Text('Registrar acción'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
