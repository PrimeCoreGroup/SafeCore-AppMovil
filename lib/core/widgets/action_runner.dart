import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/providers/core_providers.dart';
import '../errors/failures.dart';
import 'app_chrome.dart';
import 'confirm_dialog.dart';

/// Ejecuta una operación remota con las validaciones comunes:
/// conexión disponible, manejo de errores (incluido 403), auditoría local
/// y refresco de los datos afectados. Devuelve true si tuvo éxito.
Future<bool> runRemoteAction(
  BuildContext context,
  WidgetRef ref, {
  required Future<void> Function() action,
  required String successMessage,
  required String auditAction,
  List<ProviderOrFamily> invalidate = const [],
}) async {
  if (!ref.read(connectivityProvider).canReachCloud) {
    showSnack(context, kOfflineActionMessage, error: true);
    return false;
  }
  final audit = ref.read(auditLoggerProvider);
  try {
    await action();
    await audit.log(auditAction);
    for (final p in invalidate) {
      ref.invalidate(p);
    }
    if (context.mounted) showSnack(context, successMessage);
    return true;
  } catch (e) {
    await audit.log(auditAction, result: 'error');
    if (context.mounted) showSnack(context, asFailure(e).message, error: true);
    return false;
  }
}
