import 'package:flutter/material.dart';

import '../theme/status_colors.dart';

/// Diálogo de confirmación explícita (estilo "¿Reconocer incidente?").
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool destructive = false,
  Widget? extra,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        destructive ? Icons.warning_amber_rounded : Icons.help_outline,
        color: destructive
            ? context.status.critical.foreground
            : Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (extra != null) ...[const SizedBox(height: 12), extra]
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: context.status.critical.foreground,
                  minimumSize: const Size(0, 48),
                )
              : FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Confirmación reforzada para operaciones sobre actuadores físicos:
/// exige marcar una casilla de entendimiento antes de habilitar el botón.
Future<bool> showCriticalConfirmDialog(
  BuildContext context, {
  required String title,
  required String warning,
  required String acknowledgement,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _CriticalConfirmDialog(
      title: title,
      warning: warning,
      acknowledgement: acknowledgement,
      confirmLabel: confirmLabel,
    ),
  );
  return result ?? false;
}

class _CriticalConfirmDialog extends StatefulWidget {
  const _CriticalConfirmDialog({
    required this.title,
    required this.warning,
    required this.acknowledgement,
    required this.confirmLabel,
  });

  final String title;
  final String warning;
  final String acknowledgement;
  final String confirmLabel;

  @override
  State<_CriticalConfirmDialog> createState() => _CriticalConfirmDialogState();
}

class _CriticalConfirmDialogState extends State<_CriticalConfirmDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final tone = context.status.warning;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: tone.foreground),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(widget.warning),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const Key('critical-confirm-checkbox'),
              contentPadding: EdgeInsets.zero,
              value: _accepted,
              onChanged: (v) => setState(() => _accepted = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(widget.acknowledgement),
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const Key('critical-confirm-button'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: _accepted ? () => Navigator.of(context).pop(true) : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? context.status.critical.foreground : null,
      ),
    );
}
