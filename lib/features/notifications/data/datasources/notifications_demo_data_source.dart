import '../../../../core/errors/failures.dart';
import '../../../../core/security/roles.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/app_notification.dart';
import 'notifications_data_source.dart';

class NotificationsDemoDataSource extends DemoGateway
    implements NotificationsDataSource {
  NotificationsDemoDataSource(super.store, {required super.isOnline});

  @override
  Future<List<AppNotification>> fetchAll() => call(() {
        require(Permission.viewAllNotifications);
        return List.of(store.notifications);
      });

  @override
  Future<List<AppNotification>> fetchMine() => call(() {
        require(Permission.viewOwnNotifications);
        return store.notifications
            .where((n) => n.recipientUserId == account.user.id)
            .toList();
      });

  @override
  Future<AppNotification> create(NotificationDraft d) => call(() {
        require(Permission.sendNotifications);
        if (!store.users.any((u) => u.id == d.recipientUserId)) {
          throw const ValidationFailure('El destinatario no existe.');
        }
        final n = AppNotification(
          id: store.newId('nt'),
          recipientUserId: d.recipientUserId,
          title: d.title.trim(),
          body: d.body.trim(),
          channel: d.channel,
          status: d.status,
          createdAt: store.now,
        );
        store.notifications.add(n);
        return n;
      });

  @override
  Future<void> update(String id, NotificationDraft d) => call(() {
        require(Permission.sendNotifications);
        final i = store.notifications.indexWhere((n) => n.id == id);
        if (i < 0) throw const NotFoundFailure();
        final old = store.notifications[i];
        store.notifications[i] = AppNotification(
          id: id,
          recipientUserId: d.recipientUserId,
          title: d.title,
          body: d.body,
          channel: d.channel,
          status: d.status,
          createdAt: old.createdAt,
        );
      });
}
