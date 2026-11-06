import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/connectivity/connectivity_status.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/status_colors.dart';
import 'features/authentication/presentation/providers/auth_controller.dart';
import 'features/notifications/domain/entities/app_notification.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';
import 'features/profile/presentation/providers/theme_mode_provider.dart';
import 'shared/providers/core_providers.dart';
import 'shared/providers/data_providers.dart';
import 'shared/services/push_notification_service.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class SafeCoreApp extends ConsumerStatefulWidget {
  const SafeCoreApp({super.key});

  @override
  ConsumerState<SafeCoreApp> createState() => _SafeCoreAppState();
}

class _SafeCoreAppState extends ConsumerState<SafeCoreApp> {
  StreamSubscription<IncomingPush>? _pushSub;
  bool _pushInitialized = false;

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  Future<void> _initPush() async {
    if (_pushInitialized) return;
    _pushInitialized = true;
    final service = ref.read(pushNotificationServiceProvider);
    _pushSub = service.messages.listen((push) {
      refreshOperational(ref.invalidate);
      if (push.opened) {
        ref.read(routerProvider).go(Routes.notifications);
        return;
      }
      _showBanner(push.title, push.body,
          urgent: push.severity?.isUrgent ?? false);
    });
    await service.initialize();
  }

  /// Aviso dentro de la app ("alertas locales"). Los urgentes se muestran
  /// siempre; el resto según la preferencia del usuario.
  void _showBanner(String title, String body, {required bool urgent}) {
    final prefs = ref.read(notificationPrefsProvider).valueOrNull;
    if (!urgent && prefs != null && !prefs.inAppBanners) return;
    final messenger = scaffoldMessengerKey.currentState;
    final context = scaffoldMessengerKey.currentContext;
    if (messenger == null || context == null) return;
    final tone = urgent ? context.status.critical : context.status.info;
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          backgroundColor: tone.background,
          leading: Icon(
              urgent
                  ? Icons.warning_amber_rounded
                  : Icons.notifications_active_outlined,
              color: tone.foreground),
          content: Text('$title\n$body',
              maxLines: 3, overflow: TextOverflow.ellipsis),
          actions: [
            TextButton(
                onPressed: messenger.hideCurrentMaterialBanner,
                child: const Text('Cerrar')),
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                ref.read(routerProvider).go(Routes.notifications);
              },
              child: const Text('Ver'),
            ),
          ],
        ),
      );
  }

  Future<void> _onReconnected() async {
    refreshOperational(ref.invalidate);
    scaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(
          content: Text('Conexión restablecida. Datos sincronizados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    ref.listen<ConnectivityStatus>(connectivityProvider, (prev, next) {
      if (prev != null && prev.isOffline && next.canReachCloud) {
        unawaited(_onReconnected());
      }
    });
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.isAuthenticated) unawaited(_initPush());
    });
    // Nuevas notificaciones dirigidas al usuario detectadas en el sondeo.
    ref.listen<List<AppNotification>?>(myInboxProvider, (prev, next) {
      if (prev == null || next == null) return;
      final known = prev.map((n) => n.id).toSet();
      final fresh = next.where((n) => !known.contains(n.id)).toList();
      if (fresh.isNotEmpty) {
        final n = fresh.first;
        _showBanner(n.title, n.body, urgent: n.looksUrgent);
      }
    });

    return MaterialApp.router(
      title: 'SafeCore',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}
