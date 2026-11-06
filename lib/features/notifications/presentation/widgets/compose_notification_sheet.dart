import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/roles.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../domain/entities/app_notification.dart';

Future<void> showComposeNotificationSheet(BuildContext context,
        {String? presetTitle, String? presetBody}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          _ComposeSheet(presetTitle: presetTitle, presetBody: presetBody),
    );

class _ComposeSheet extends ConsumerStatefulWidget {
  const _ComposeSheet({this.presetTitle, this.presetBody});
  final String? presetTitle;
  final String? presetBody;

  @override
  ConsumerState<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends ConsumerState<_ComposeSheet> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.presetTitle);
  late final _body = TextEditingController(text: widget.presetBody);
  final _recipientId = TextEditingController();
  String? _recipient;
  NotificationChannel _channel = NotificationChannel.push;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _recipientId.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final recipient = _recipient ?? _recipientId.text.trim();
    setState(() => _busy = true);
    final ok = await runRemoteAction(
      context,
      ref,
      action: () => ref.read(notificationsRepositoryProvider).create(
            NotificationDraft(
              recipientUserId: recipient,
              title: _title.text,
              body: _body.text,
              channel: _channel,
              status: DeliveryStatus.pending,
            ),
          ),
      successMessage: 'Notificación registrada.',
      auditAction: 'notification.create',
      invalidate: [notificationsProvider],
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(canProvider(Permission.manageUsers));
    final me = ref.watch(currentUserProvider);
    final users = isAdmin ? ref.watch(usersProvider).valueOrNull?.data : null;
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
              Text('Nueva notificación',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Se registra en el servidor y aparece en la bandeja del destinatario. '
                'El backend aún no envía push, correo ni SMS reales.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Destinatario',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              if (users != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final u in users)
                      ChoiceChip(
                        label: Text(
                            '${u.fullName} · ${u.roles.isEmpty ? '' : u.roles.first.label}'),
                        selected: _recipient == u.id,
                        onSelected: (_) => setState(() => _recipient = u.id),
                      ),
                  ],
                )
              else ...[
                if (me != null)
                  ChoiceChip(
                    label: const Text('Enviármela a mí (prueba)'),
                    selected: _recipient == me.id,
                    onSelected: (s) =>
                        setState(() => _recipient = s ? me.id : null),
                  ),
                if (_recipient == null)
                  TextFormField(
                    controller: _recipientId,
                    decoration: const InputDecoration(
                      labelText: 'ID del usuario destinatario (GUID)',
                      helperText:
                          'Solo un administrador puede listar usuarios.',
                    ),
                    validator: (v) => (v == null || v.trim().length < 8)
                        ? 'Indica el ID del destinatario.'
                        : null,
                  ),
              ],
              if (users != null && _recipient == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Selecciona un destinatario.',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _title,
                maxLength: 200,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: NotificationDraft.validateTitle,
              ),
              TextFormField(
                controller: _body,
                maxLines: 4,
                maxLength: 4000,
                decoration: const InputDecoration(labelText: 'Mensaje'),
                validator: NotificationDraft.validateBody,
              ),
              Text('Canal', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<NotificationChannel>(
                segments: [
                  for (final c in NotificationChannel.values)
                    ButtonSegment(value: c, label: Text(c.label)),
                ],
                selected: {_channel},
                onSelectionChanged: (s) => setState(() => _channel = s.first),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _busy || (users != null && _recipient == null)
                    ? null
                    : _send,
                icon: const Icon(Icons.send_rounded),
                label: Text(_busy ? 'Enviando…' : 'Registrar notificación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
