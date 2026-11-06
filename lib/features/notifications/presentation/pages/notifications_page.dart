import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/action_runner.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';
import '../widgets/compose_notification_sheet.dart';
import '../widgets/notification_tile.dart';

/// Bandeja de notificaciones. Personal: "Para mí" y "Todas"; residente: las
/// propias (`/api/Notifications/mine`).
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(notificationsProvider);
    final staff = ref.watch(canProvider(Permission.viewAllNotifications));
    final canSend = ref.watch(canProvider(Permission.sendNotifications));
    final me = ref.watch(currentUserProvider);
    final users = ref.watch(canProvider(Permission.manageUsers))
        ? ref.watch(usersProvider).valueOrNull?.data
        : null;
    final unread = ref.watch(unreadCountProvider);

    String? recipientName(String id) {
      if (id == me?.id) return 'Tú';
      return users?.where((u) => u.id == id).firstOrNull?.fullName;
    }

    Future<void> refresh() {
      ref.invalidate(notificationsProvider);
      return settle([ref.read(notificationsProvider.future)]);
    }

    Widget list(List<AppNotification> items, {required bool showRecipient}) =>
        RefreshIndicator(
          onRefresh: refresh,
          child: AsyncValueView(
            value: all,
            onRetry: () => ref.invalidate(notificationsProvider),
            data: (r) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                DataFreshnessNote(r),
                if (items.isEmpty)
                  const EmptyView(
                    icon: Icons.notifications_off_outlined,
                    title: 'Sin notificaciones',
                    message: 'No hay notificaciones para mostrar.',
                  ),
                ..._grouped(
                    context, ref, items, showRecipient ? recipientName : null),
              ],
            ),
          ),
        );

    final data = all.valueOrNull?.data ?? const <AppNotification>[];
    final mine =
        data.where((n) => n.recipientUserId == me?.id || !staff).toList();

    final fab = canSend
        ? FloatingActionButton.extended(
            onPressed: () => showComposeNotificationSheet(context),
            icon: const Icon(Icons.edit_notifications_outlined),
            label: const Text('Nueva'),
          )
        : null;

    final actions = [
      IconButton(
        tooltip: 'Marcar todo como leído',
        onPressed: unread == 0
            ? null
            : () => ref
                .read(readNotificationsProvider.notifier)
                .markRead(mine.map((n) => n.id)),
        icon: const Icon(Icons.done_all_rounded),
      ),
      IconButton(
        tooltip: 'Preferencias',
        onPressed: () => context.go(Routes.notificationSettings),
        icon: const Icon(Icons.tune_rounded),
      ),
    ];

    if (!staff) {
      return Scaffold(
        appBar: ScAppBar(title: 'Mis avisos', actions: actions),
        body: list(mine, showRecipient: false),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: ScAppBar(title: 'Notificaciones', actions: actions),
        floatingActionButton: fab,
        body: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Para mí${unread > 0 ? ' ($unread)' : ''}'),
                Tab(text: 'Todas (${data.length})'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  list(mine, showRecipient: false),
                  list(data, showRecipient: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _grouped(
    BuildContext context,
    WidgetRef ref,
    List<AppNotification> items,
    String? Function(String id)? recipientName,
  ) {
    final canUpdate = ref.read(canProvider(Permission.sendNotifications));
    final out = <Widget>[];
    String? last;
    for (final n in items) {
      final header = n.createdAt == null
          ? 'SIN FECHA'
          : DateFormatter.dayHeader(n.createdAt!);
      if (header != last) {
        out.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(header, style: Theme.of(context).textTheme.labelLarge),
        ));
        last = header;
      }
      out
        ..add(NotificationTile(
          notification: n,
          recipientLabel: recipientName?.call(n.recipientUserId),
          trailing: canUpdate
              ? PopupMenuButton<DeliveryStatus>(
                  tooltip: 'Cambiar estado de entrega',
                  onSelected: (s) => runRemoteAction(
                    context,
                    ref,
                    action: () => ref
                        .read(notificationsRepositoryProvider)
                        .update(n.id, NotificationDraft.from(n, status: s)),
                    successMessage: 'Estado actualizado: ${s.label}.',
                    auditAction: 'notification.update',
                    invalidate: [notificationsProvider],
                  ),
                  itemBuilder: (_) => [
                    for (final s in DeliveryStatus.values)
                      if (s != n.status)
                        PopupMenuItem(
                            value: s,
                            child: Text('Marcar ${s.label.toLowerCase()}')),
                  ],
                )
              : null,
        ))
        ..add(const SizedBox(height: 10));
    }
    return out;
  }
}
