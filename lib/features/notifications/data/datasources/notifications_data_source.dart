import '../../domain/entities/app_notification.dart';

abstract interface class NotificationsDataSource {
  Future<List<AppNotification>> fetchAll();
  Future<List<AppNotification>> fetchMine();
  Future<AppNotification> create(NotificationDraft d);
  Future<void> update(String id, NotificationDraft d);
}
