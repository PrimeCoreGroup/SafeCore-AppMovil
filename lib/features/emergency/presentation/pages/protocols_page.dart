import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/roles.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../domain/entities/emergency.dart';

class ProtocolsPage extends ConsumerWidget {
  const ProtocolsPage({super.key});

  Future<ProtocolDraft?> _form(BuildContext context,
          {EmergencyProtocol? initial}) =>
      showModalBottomSheet<ProtocolDraft>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => _ProtocolForm(initial: initial),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(emergencyProvider);
    final canManage = ref.watch(canProvider(Permission.manageProtocols));
    final canDelete = ref.watch(canProvider(Permission.deleteProtocols));
    final repo = ref.read(emergencyRepositoryProvider);
    return ScPage(
      title: 'Protocolos',
      subtitle: 'Guías de respuesta por tipo de emergencia',
      onRefresh: () {
        ref.invalidate(emergencyProvider);
        return settle([ref.read(emergencyProvider.future)]);
      },
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                final d = await _form(context);
                if (d == null || !context.mounted) return;
                await runRemoteAction(
                  context,
                  ref,
                  action: () => repo.createProtocol(d),
                  successMessage: 'Protocolo creado.',
                  auditAction: 'protocol.create',
                  invalidate: [emergencyProvider],
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nuevo'),
            )
          : null,
      children: [
        AsyncValueView(
          value: data,
          onRetry: () => ref.invalidate(emergencyProvider),
          data: (r) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (r.data.protocols.isEmpty)
                const EmptyView(
                    title: 'Sin protocolos',
                    message: 'Crea protocolos para coordinar respuestas.'),
              for (final p in r.data.protocols) ...[
                SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              children: [
                                StatusChip(
                                    label: p.emergencyType,
                                    tone: context.status.info),
                                StatusChip(
                                  label: p.isActive ? 'Activo' : 'Inactivo',
                                  tone: p.isActive
                                      ? context.status.normal
                                      : context.status.offline,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (canManage)
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              final d = await _form(context, initial: p);
                              if (d == null || !context.mounted) return;
                              await runRemoteAction(context, ref,
                                  action: () => repo.updateProtocol(p.id, d),
                                  successMessage: 'Protocolo actualizado.',
                                  auditAction: 'protocol.update',
                                  invalidate: [emergencyProvider]);
                            } else if (v == 'toggle') {
                              await runRemoteAction(context, ref,
                                  action: () => repo.updateProtocol(
                                        p.id,
                                        ProtocolDraft(
                                            name: p.name,
                                            emergencyType: p.emergencyType,
                                            isActive: !p.isActive),
                                      ),
                                  successMessage: p.isActive
                                      ? 'Protocolo desactivado.'
                                      : 'Protocolo activado.',
                                  auditAction: 'protocol.toggle',
                                  invalidate: [emergencyProvider]);
                            } else {
                              final ok = await showConfirmDialog(context,
                                  title: '¿Eliminar protocolo?',
                                  message:
                                      'No es posible si una respuesta lo usa; en ese caso, desactívalo.',
                                  confirmLabel: 'Eliminar',
                                  destructive: true);
                              if (!ok || !context.mounted) return;
                              await runRemoteAction(context, ref,
                                  action: () => repo.deleteProtocol(p.id),
                                  successMessage: 'Protocolo eliminado.',
                                  auditAction: 'protocol.delete',
                                  invalidate: [emergencyProvider]);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit', child: Text('Editar')),
                            PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                    p.isActive ? 'Desactivar' : 'Activar')),
                            if (canDelete)
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Eliminar')),
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

class _ProtocolForm extends StatefulWidget {
  const _ProtocolForm({this.initial});
  final EmergencyProtocol? initial;

  @override
  State<_ProtocolForm> createState() => _ProtocolFormState();
}

class _ProtocolFormState extends State<_ProtocolForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _type =
      TextEditingController(text: widget.initial?.emergencyType ?? 'Fire');
  late bool _active = widget.initial?.isActive ?? true;

  @override
  void dispose() {
    _name.dispose();
    _type.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  widget.initial == null
                      ? 'Nuevo protocolo'
                      : 'Editar protocolo',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: ProtocolDraft.validateName,
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final t in const [
                    'Fire',
                    'GasOrSmoke',
                    'Earthquake',
                    'SensorFault'
                  ])
                    ChoiceChip(
                      label: Text(t),
                      selected: _type.text == t,
                      onSelected: (_) => setState(() => _type.text = t),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _type,
                maxLength: 50,
                decoration:
                    const InputDecoration(labelText: 'Tipo de emergencia'),
                validator: ProtocolDraft.validateType,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Activo'),
                subtitle: const Text(
                    'Solo los protocolos activos pueden usarse en respuestas.'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () {
                  if (!(_form.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop(
                    ProtocolDraft(
                        name: _name.text,
                        emergencyType: _type.text,
                        isActive: _active),
                  );
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      );
}
