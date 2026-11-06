import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/app_notification.dart';

class NotificationMapper {
  const NotificationMapper._();

  static AppNotification fromJson(Json j) => AppNotification(
        id: readString(j, 'id'),
        recipientUserId: readString(j, 'recipientUserId'),
        title: readString(j, 'title', 'Notificación'),
        body: readString(j, 'body'),
        channel: enumFromApi(
          NotificationChannel.values,
          j['channel'],
          NotificationChannel.push,
        ),
        status: enumFromApi(
            DeliveryStatus.values, j['status'], DeliveryStatus.pending),
        createdAt: DateFormatter.tryParse(j['createdAt']),
      );

  static Json toJson(AppNotification n) => {
        'id': n.id,
        'recipientUserId': n.recipientUserId,
        'title': n.title,
        'body': n.body,
        'channel': n.channel.apiValue,
        'status': n.status.apiValue,
        if (n.createdAt != null)
          'createdAt': n.createdAt!.toUtc().toIso8601String(),
      };

  static Json draftToJson(NotificationDraft d) => {
        'recipientUserId': d.recipientUserId,
        'title': d.title.trim(),
        'body': d.body.trim(),
        'channel': d.channel.apiValue,
        'status': d.status.apiValue,
      };

  static List<AppNotification> listFromJson(Object? raw) =>
      asJsonList(raw).map(fromJson).toList();
  static List<Json> listToJson(List<AppNotification> l) =>
      l.map(toJson).toList();
}
