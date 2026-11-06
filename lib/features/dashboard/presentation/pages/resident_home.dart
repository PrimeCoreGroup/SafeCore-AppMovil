import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../notifications/presentation/widgets/notification_tile.dart';

/// Inicio del residente: avisos recientes y guía de seguridad.
class ResidentHome extends ConsumerWidget {
  const ResidentHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    return Scaffold(
      appBar: const ScAppBar(),
      body: RefreshIndicator(
        onRefresh: () {
          ref.invalidate(notificationsProvider);
          return settle([ref.read(notificationsProvider.future)]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            GradientHero(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user?.displayFirstName ?? ''}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unread == 0
                        ? 'No tienes avisos sin leer.'
                        : 'Tienes $unread aviso(s) sin leer.',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => context.go(Routes.notifications),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Ver mis avisos'),
                  ),
                ],
              ),
            ),
            const SectionHeader('Avisos recientes',
                icon: Icons.campaign_outlined),
            AsyncValueView(
              value: notifications,
              onRetry: () => ref.invalidate(notificationsProvider),
              data: (r) => r.data.isEmpty
                  ? const SectionCard(
                      child: EmptyView(
                        icon: Icons.mark_email_read_outlined,
                        title: 'Sin avisos',
                        message:
                            'Cuando el personal de SafeCore te envíe un aviso, aparecerá aquí.',
                      ),
                    )
                  : Column(
                      children: [
                        for (final n in r.data.take(3)) ...[
                          NotificationTile(notification: n),
                          const SizedBox(height: 10),
                        ],
                        DataFreshnessNote(r),
                      ],
                    ),
            ),
            const SectionHeader('Ante una emergencia',
                icon: Icons.health_and_safety_outlined),
            const SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Tip(Icons.directions_run_rounded,
                      'Sigue las rutas de evacuación señalizadas; no uses ascensores.'),
                  _Tip(Icons.air_rounded,
                      'Si hueles gas, no acciones interruptores ni enciendas fuego.'),
                  _Tip(Icons.shield_outlined,
                      'Los dispositivos SafeCore actúan localmente aunque no haya Internet.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const SectionCard(
              title: 'Números de emergencia (Perú)',
              icon: Icons.call_rounded,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                      avatar:
                          Icon(Icons.local_fire_department_rounded, size: 18),
                      label: Text('Bomberos 116')),
                  Chip(
                      avatar: Icon(Icons.local_police_rounded, size: 18),
                      label: Text('Policía 105')),
                  Chip(
                      avatar: Icon(Icons.medical_services_rounded, size: 18),
                      label: Text('SAMU 106')),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Actualizado ${DateFormatter.relative(DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
