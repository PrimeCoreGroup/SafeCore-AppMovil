enum NotificationChannel {
  push,
  email,
  sms;

  String get label => switch (this) {
        NotificationChannel.push => 'Push',
        NotificationChannel.email => 'Correo',
        NotificationChannel.sms => 'SMS',
      };

  String get apiValue => switch (this) {
        NotificationChannel.push => 'Push',
        NotificationChannel.email => 'Email',
        NotificationChannel.sms => 'Sms',
      };
}

enum DeliveryStatus {
  pending,
  delivered,
  failed;

  String get label => switch (this) {
        DeliveryStatus.pending => 'Pendiente',
        DeliveryStatus.delivered => 'Entregada',
        DeliveryStatus.failed => 'Fallida',
      };

  String get apiValue => switch (this) {
        DeliveryStatus.pending => 'Pending',
        DeliveryStatus.delivered => 'Delivered',
        DeliveryStatus.failed => 'Failed',
      };
}

/// Notificación persistida en el backend (`/api/Notifications`).
///
/// El backend no entrega push/SMS/correo reales: la bandeja de la app es el
/// canal efectivo de lectura.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    required this.channel,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String recipientUserId;
  final String title;
  final String body;
  final NotificationChannel channel;
  final DeliveryStatus status;
  final DateTime? createdAt;

  /// Las notificaciones de riesgo se reconocen por palabras clave del título.
  bool get looksUrgent {
    final t = title.toLowerCase();
    return t.contains('crític') ||
        t.contains('critic') ||
        t.contains('incendio') ||
        t.contains('fuego') ||
        t.contains('gas') ||
        t.contains('sismo') ||
        t.contains('evacu');
  }
}

class NotificationDraft {
  const NotificationDraft({
    required this.recipientUserId,
    required this.title,
    required this.body,
    required this.channel,
    required this.status,
  });

  factory NotificationDraft.from(AppNotification n, {DeliveryStatus? status}) =>
      NotificationDraft(
        recipientUserId: n.recipientUserId,
        title: n.title,
        body: n.body,
        channel: n.channel,
        status: status ?? n.status,
      );

  final String recipientUserId;
  final String title;
  final String body;
  final NotificationChannel channel;
  final DeliveryStatus status;

  static String? validateTitle(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa un título.';
    return s.length > 200 ? 'Máximo 200 caracteres.' : null;
  }

  static String? validateBody(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa el mensaje.';
    return s.length > 4000 ? 'Máximo 4000 caracteres.' : null;
  }
}

/// Preferencias locales de avisos dentro de la app.
class NotificationPreferences {
  const NotificationPreferences({
    this.inAppBanners = true,
    this.showDeliveredOnly = false,
  });

  final bool inAppBanners;
  final bool showDeliveredOnly;

  Map<String, Object> toJson() => {
        'inAppBanners': inAppBanners,
        'showDeliveredOnly': showDeliveredOnly,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> j) =>
      NotificationPreferences(
        inAppBanners:
            j['inAppBanners'] is bool ? j['inAppBanners'] as bool : true,
        showDeliveredOnly: j['showDeliveredOnly'] is bool
            ? j['showDeliveredOnly'] as bool
            : false,
      );
}
