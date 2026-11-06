import '../../../../core/utils/data_result.dart';
import '../entities/app_notification.dart';

abstract interface class NotificationsRepository {
  /// Todas (Administrator, Operator, Responder).
  Future<DataResult<List<AppNotification>>> getAll();

  /// Solo las del usuario (Resident) — `/api/Notifications/mine`.
  Future<DataResult<List<AppNotification>>> getMine();

  Future<AppNotification> create(NotificationDraft draft);
  Future<void> update(String id, NotificationDraft draft);

  // Estado local (en el dispositivo)
  Future<Set<String>> readIds();
  Future<void> markRead(Iterable<String> ids);
  Future<NotificationPreferences> loadPreferences();
  Future<void> savePreferences(NotificationPreferences prefs);
}
