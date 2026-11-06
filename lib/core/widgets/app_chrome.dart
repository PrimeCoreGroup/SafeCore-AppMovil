import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../../features/notifications/presentation/providers/notification_providers.dart';
import '../../shared/providers/core_providers.dart';
import '../../shared/providers/data_providers.dart';
import '../connectivity/connectivity_status.dart';
import '../router/routes.dart';
import '../security/roles.dart';
import '../theme/status_colors.dart';
import '../utils/data_result.dart';
import '../utils/date_formatter.dart';
import 'confirm_dialog.dart';
import 'sc_logo.dart';

/// Barra superior SafeCore: logotipo, distintivo DEMO y campana.
class ScAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ScAppBar({super.key, this.title, this.actions = const []});

  final String? title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(isDemoProvider);
    final unread = ref.watch(unreadCountProvider);
    final canNotify = ref.watch(canProvider(Permission.viewAllNotifications)) ||
        ref.watch(canProvider(Permission.viewOwnNotifications));
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      titleSpacing: canPop ? 0 : 16,
      title: Row(
        children: [
          Flexible(
            child: title == null
                ? const ScLogo(size: 26, fontSize: 21)
                : Text(title!, overflow: TextOverflow.ellipsis),
          ),
          if (demo) ...[const SizedBox(width: 8), const DemoBadge()],
        ],
      ),
      actions: [
        ...actions,
        if (canNotify)
          IconButton(
            tooltip: unread > 0
                ? 'Notificaciones, $unread sin leer'
                : 'Notificaciones',
            onPressed: () => context.go(Routes.notifications),
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Modo demostración: todos los datos son ficticios',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: context.status.warning.background,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: context.status.warning.foreground),
          ),
          child: Text(
            'DEMO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.status.warning.foreground,
            ),
          ),
        ),
      );
}

/// Banner del modo offline. Distingue la red del teléfono, la nube y el
/// backend, y recuerda que la protección física es local en el ESP32.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    final health = ref.watch(healthProvider).valueOrNull;
    final backendDown = health != null && !health.ready;
    if (!status.isOffline && !backendDown) return const SizedBox.shrink();
    final tone = context.status.offline;
    final title = !status.deviceOnline
        ? 'Este teléfono no tiene conexión a Internet'
        : backendDown
            ? 'El servidor de SafeCore no está disponible'
            : 'Sin comunicación con la nube de SafeCore';
    return Semantics(
      liveRegion: true,
      child: Material(
        color: tone.background,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.cloud_off_rounded, color: tone.foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: tone.foreground),
                    ),
                    const SizedBox(height: 2),
                    const Text(kLocalOperationMessage),
                    const SizedBox(height: 2),
                    Text(
                      'Se muestra el último estado conocido. Las acciones remotas '
                      'están deshabilitadas hasta recuperar la conexión.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso de expiración del token (15 min) con renovación sin perder la
/// pantalla actual.
class SessionExpiryBanner extends ConsumerStatefulWidget {
  const SessionExpiryBanner({super.key});

  @override
  ConsumerState<SessionExpiryBanner> createState() =>
      _SessionExpiryBannerState();
}

class _SessionExpiryBannerState extends ConsumerState<SessionExpiryBanner> {
  @override
  Widget build(BuildContext context) {
    final exp = ref.watch(authControllerProvider).session?.expiresAt;
    if (exp == null) return const SizedBox.shrink();
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(seconds: 15), (i) => i),
      builder: (context, _) {
        final left = exp.difference(DateTime.now());
        if (left > const Duration(minutes: 2) || left.isNegative) {
          return const SizedBox.shrink();
        }
        final tone = context.status.warning;
        return Material(
          color: tone.background,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: tone.foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu sesión expira en ${left.inSeconds < 60 ? '${left.inSeconds} s' : '${left.inMinutes} min'}.',
                    style: TextStyle(
                        color: tone.foreground, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => showRenewSessionDialog(context),
                  child: const Text('Renovar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showRenewSessionDialog(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const _RenewDialog(),
    );

class _RenewDialog extends ConsumerStatefulWidget {
  const _RenewDialog();

  @override
  ConsumerState<_RenewDialog> createState() => _RenewDialogState();
}

class _RenewDialogState extends ConsumerState<_RenewDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error =
        await ref.read(authControllerProvider.notifier).renew(_password.text);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      showSnack(context, 'Sesión renovada por 15 minutos.');
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider)?.email ?? '';
    return AlertDialog(
      icon: const Icon(Icons.lock_clock_outlined),
      title: const Text('Renovar sesión'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Confirma tu contraseña para $email.'),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            decoration:
                InputDecoration(labelText: 'Contraseña', errorText: _error),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Validando…' : 'Renovar'),
        ),
      ],
    );
  }
}

/// Indica el origen y antigüedad de los datos en pantalla.
class DataFreshnessNote extends StatelessWidget {
  const DataFreshnessNote(this.result, {super.key});

  final DataResult<Object?> result;

  @override
  Widget build(BuildContext context) {
    final tone = result.isStale
        ? context.status.warning
        : result.fromCache
            ? context.status.offline
            : null;
    final String text;
    if (result.fromCache) {
      text = result.isStale
          ? 'Datos desactualizados · último estado conocido de las '
              '${DateFormatter.dateTime(result.fetchedAt)}'
          : 'Último estado conocido · ${DateFormatter.relative(result.fetchedAt)}';
    } else if (result.isDemo) {
      text = 'Datos de demostración · sin conexión a hardware real';
    } else {
      text =
          'Actualizado ${DateFormatter.relative(result.fetchedAt)} desde el servidor';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            result.fromCache
                ? Icons.history
                : result.isDemo
                    ? Icons.science_outlined
                    : Icons.cloud_done_outlined,
            size: 14,
            color: tone?.foreground ??
                Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: tone?.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

const kOfflineActionMessage =
    'Sin conexión: esta acción requiere comunicación con el servidor de SafeCore. '
    'La protección física local del ESP32 no depende de la app.';
