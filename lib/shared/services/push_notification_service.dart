import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/health_status.dart';
import '../providers/core_providers.dart';

enum PushPermissionStatus {
  notConfigured,
  notDetermined,
  granted,
  denied;

  String get label => switch (this) {
        PushPermissionStatus.notConfigured =>
          'Firebase no está configurado en esta compilación',
        PushPermissionStatus.notDetermined => 'Permiso del sistema pendiente',
        PushPermissionStatus.granted => 'Permiso del sistema concedido',
        PushPermissionStatus.denied =>
          'Permiso denegado: actívalo desde los ajustes del teléfono',
      };
}

/// Mensaje push recibido (primer plano o al abrir la notificación).
class IncomingPush {
  const IncomingPush({
    required this.title,
    required this.body,
    this.alertId,
    this.severity,
    this.opened = false,
  });

  final String title;
  final String body;
  final String? alertId;
  final Severity? severity;

  /// true si el usuario tocó la notificación del sistema.
  final bool opened;

  factory IncomingPush.fromRemote(RemoteMessage m, {bool opened = false}) {
    final sev = m.data['severity']?.toString().toUpperCase();
    return IncomingPush(
      title: m.notification?.title ?? m.data['title']?.toString() ?? 'SafeCore',
      body: m.notification?.body ?? m.data['body']?.toString() ?? '',
      alertId: m.data['alertId']?.toString(),
      severity: sev == null ? null : Severity.fromApi(sev),
      opened: opened,
    );
  }
}

/// Manejador en segundo plano. Las notificaciones con bloque `notification`
/// las muestra el sistema operativo; aquí no se procesa información sensible.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Integración con Firebase Cloud Messaging (US10).
///
/// Es opcional en tiempo de ejecución: si `FIREBASE_ENABLED=false` o falta
/// la configuración de Firebase, la app funciona sin push y lo indica.
class PushNotificationService {
  PushNotificationService({
    required this.enabled,
    required this.onToken,
    required this.onStatus,
  });

  final bool enabled;
  final Future<void> Function(String token) onToken;
  final void Function(PushPermissionStatus status) onStatus;

  final _messages = StreamController<IncomingPush>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  bool _ready = false;

  Stream<IncomingPush> get messages => _messages.stream;

  Future<void> initialize() async {
    if (!enabled) {
      onStatus(PushPermissionStatus.notConfigured);
      return;
    }
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final fm = FirebaseMessaging.instance;
      _subs
        ..add(
          FirebaseMessaging.onMessage
              .listen((m) => _messages.add(IncomingPush.fromRemote(m))),
        )
        ..add(
          FirebaseMessaging.onMessageOpenedApp.listen(
              (m) => _messages.add(IncomingPush.fromRemote(m, opened: true))),
        )
        ..add(fm.onTokenRefresh.listen((t) => unawaited(onToken(t))));
      final initial = await fm.getInitialMessage();
      if (initial != null) {
        _messages.add(IncomingPush.fromRemote(initial, opened: true));
      }
      _ready = true;
      onStatus(_map((await fm.getNotificationSettings()).authorizationStatus));
      await _registerToken();
    } catch (e) {
      // Sin google-services.json / GoogleService-Info.plist.
      debugPrint('[Push] Firebase no disponible: ${e.runtimeType}');
      onStatus(PushPermissionStatus.notConfigured);
    }
  }

  Future<void> requestPermission() async {
    if (!_ready) return;
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    onStatus(_map(settings.authorizationStatus));
    await _registerToken();
  }

  Future<void> _registerToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await onToken(token);
    } catch (_) {
      // Se reintentará en onTokenRefresh.
    }
  }

  static PushPermissionStatus _map(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional =>
          PushPermissionStatus.granted,
        AuthorizationStatus.denied => PushPermissionStatus.denied,
        AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
        AuthorizationStatus.deniedPermanently => PushPermissionStatus.denied,
      };

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    await _messages.close();
  }
}

final pushPermissionProvider = StateProvider<PushPermissionStatus>(
    (ref) => PushPermissionStatus.notConfigured);

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(
    enabled: ref.watch(appConfigProvider).firebaseEnabled,
    // El backend aún no expone un endpoint para registrar tokens FCM; el
    // token solo se registra en el log de depuración.
    onToken: (token) async => debugPrint(
      '[Push] Token FCM obtenido (${Platform.isIOS ? 'iOS' : 'Android'}); '
      'pendiente de endpoint en el backend.',
    ),
    onStatus: (s) => ref.read(pushPermissionProvider.notifier).state = s,
  );
  ref.onDispose(service.dispose);
  return service;
});
