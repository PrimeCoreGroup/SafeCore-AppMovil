import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/tinted_card.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/services/push_notification_service.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

/// Preferencias locales de avisos (sección 5.9).
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final push = ref.watch(pushPermissionProvider);
    final firebase = ref.watch(appConfigProvider).firebaseEnabled;
    return ScPage(
      title: 'Preferencias de avisos',
      subtitle: 'Se guardan en este dispositivo',
      children: [
        AsyncValueView(
          value: prefs,
          data: (p) => SectionCard(
            title: 'Dentro de la app',
            icon: Icons.phone_android_rounded,
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: p.inAppBanners,
                  onChanged: (v) =>
                      ref.read(notificationPrefsProvider.notifier).save(
                            NotificationPreferences(
                                inAppBanners: v,
                                showDeliveredOnly: p.showDeliveredOnly),
                          ),
                  title: const Text('Avisos emergentes'),
                  subtitle: const Text(
                      'Mostrar un aviso al recibir nuevas notificaciones mientras usas la app. Los avisos urgentes se muestran siempre.'),
                ),
              ],
            ),
          ),
        ),
        kGap,
        SectionCard(
          title: 'Notificaciones push',
          icon: Icons.notifications_active_outlined,
          child: Text(firebase
              ? push.label
              : 'Firebase no está configurado en esta compilación.'),
        ),
        kGap,
        const InfoNote(
          title: 'Entrega de push, correo y SMS',
          message:
              'El backend actual registra las notificaciones, pero aún no las '
              'entrega por push, correo ni SMS. La bandeja de la app es el canal '
              'de lectura y se actualiza automáticamente mientras la app está abierta.',
        ),
      ],
    );
  }
}
