import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/status_colors.dart';
import '../../domain/entities/device.dart';

/// Muestra el secreto del dispositivo UNA sola vez. No se guarda en la app.
Future<void> showDeviceSecretDialog(
        BuildContext context, ProvisionedDevice p) =>
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final tone = context.status.warning;
        return AlertDialog(
          icon: Icon(Icons.key_rounded, color: tone.foreground),
          title: const Text('Secreto del dispositivo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${p.device.name} · ${p.device.serialNumber}'),
                const SizedBox(height: 4),
                SelectableText('ID: ${p.device.id}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SelectableText(
                    p.secret,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: tone.background,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Text(
                    'Cópialo ahora y guárdalo en el almacén seguro del ESP32. '
                    'El servidor no lo vuelve a mostrar y esta app no lo almacena. '
                    'El dispositivo lo canjea por un JWT en /api/iam/auth/device-token.',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: p.secret));
                ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                  const SnackBar(
                      content: Text('Secreto copiado al portapapeles.')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copiar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ya lo guardé'),
            ),
          ],
        );
      },
    );

/// Formulario de alta/edición de dispositivo (solo administradores).
Future<DeviceDraft?> showDeviceFormSheet(BuildContext context,
        {Device? initial}) =>
    showModalBottomSheet<DeviceDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _DeviceForm(initial: initial),
    );

class _DeviceForm extends StatefulWidget {
  const _DeviceForm({this.initial});
  final Device? initial;

  @override
  State<_DeviceForm> createState() => _DeviceFormState();
}

class _DeviceFormState extends State<_DeviceForm> {
  final _form = GlobalKey<FormState>();
  late final _serial =
      TextEditingController(text: widget.initial?.serialNumber);
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _category =
      TextEditingController(text: widget.initial?.category ?? 'ESP32');
  late DeviceConnectivity _status =
      widget.initial?.connectivity == DeviceConnectivity.unknown ||
              widget.initial == null
          ? DeviceConnectivity.offline
          : widget.initial!.connectivity;

  @override
  void dispose() {
    _serial.dispose();
    _name.dispose();
    _category.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
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
              Text(editing ? 'Editar dispositivo' : 'Registrar dispositivo',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _serial,
                decoration: const InputDecoration(
                    labelText: 'Número de serie', hintText: 'SC-LAB-001'),
                validator: DeviceDraft.validateSerial,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Nombre', hintText: 'Nodo Torre Norte'),
                validator: DeviceDraft.validateName,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: DeviceDraft.validateCategory,
              ),
              const SizedBox(height: 16),
              Text('Estado de conectividad',
                  style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in DeviceConnectivity.editable)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  if (!(_form.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop(
                    DeviceDraft(
                      serialNumber: _serial.text,
                      name: _name.text,
                      category: _category.text,
                      connectivity: _status,
                    ),
                  );
                },
                child: Text(editing
                    ? 'Guardar cambios'
                    : 'Registrar y generar secreto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
