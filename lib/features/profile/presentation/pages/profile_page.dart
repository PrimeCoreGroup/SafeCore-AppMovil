import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/security/roles.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_chrome.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/sc_page.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../providers/theme_mode_provider.dart';

/// Perfil, preferencias, estado del servidor y sesión (sección 5.12).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final perms = ref.watch(permissionsProvider);
    final config = ref.watch(appConfigProvider);
    final demo = ref.watch(isDemoProvider);
    final health = ref.watch(healthProvider);
    final themeMode = ref.watch(themeModeProvider);

    Widget nav(IconData icon, String title, String subtitle, String route) =>
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.go(route),
        );

    return ScPage(
      title: 'Perfil',
      subtitle: 'Cuenta, preferencias y sesión',
      onRefresh: () =>
          ref.read(authControllerProvider.notifier).refreshProfile(),
      children: [
        GradientHero(
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                child: Text(
                  user?.initials ?? '?',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? '',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                    Text(user?.email ?? '',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final r in user?.roles ?? const <UserRole>[])
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(r.label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(user?.primaryRole.description ?? '',
            style: Theme.of(context).textTheme.bodySmall),
        kGap,
        SectionCard(
          title: 'Administración',
          icon: Icons.admin_panel_settings_outlined,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            children: [
              if (perms.contains(Permission.manageUsers))
                nav(Icons.group_outlined, 'Usuarios',
                    'Crear cuentas y gestionar estados', Routes.users),
              if (perms.contains(Permission.viewConfiguration))
                nav(
                    Icons.tune_rounded,
                    'Configuración',
                    'Umbrales y versiones de sincronización',
                    Routes.configuration),
              if (perms.contains(Permission.viewOperations))
                nav(Icons.rule_folder_outlined, 'Protocolos de emergencia',
                    'Guías de respuesta', Routes.protocols),
              if (perms.contains(Permission.postReadings))
                nav(Icons.science_outlined, 'Prueba de detección',
                    'Verificar la cadena de detección', Routes.detectionTest),
              nav(Icons.notifications_outlined, 'Preferencias de avisos',
                  'Avisos dentro de la app', Routes.notificationSettings),
            ],
          ),
        ),
        kGap,
        SectionCard(
          title: 'Apariencia',
          icon: Icons.palette_outlined,
          child: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistema'),
                  icon: Icon(Icons.brightness_auto_rounded)),
              ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Claro'),
                  icon: Icon(Icons.light_mode_rounded)),
              ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Oscuro'),
                  icon: Icon(Icons.dark_mode_rounded)),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
        ),
        kGap,
        SectionCard(
          title: 'Conexión',
          icon: Icons.cloud_outlined,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            children: [
              ListTile(
                leading:
                    Icon(demo ? Icons.science_outlined : Icons.dns_rounded),
                title: Text(demo ? 'Modo demostración' : 'Servidor SafeCore'),
                subtitle: Text(demo
                    ? 'Datos ficticios, sin conexión al servidor'
                    : Uri.tryParse(config.apiBaseUrl)?.host ??
                        config.apiBaseUrl),
                trailing: health.when(
                  data: (h) => StatusChip(
                    label: h.ready ? 'Listo' : 'BD no lista',
                    tone: h.ready
                        ? context.status.normal
                        : context.status.warning,
                  ),
                  loading: () => const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (_, __) => StatusChip(
                      label: 'Sin contacto', tone: context.status.offline),
                ),
                onTap: () => ref.invalidate(healthProvider),
              ),
              if (demo)
                SwitchListTile(
                  secondary: const Icon(Icons.cloud_off_outlined),
                  title: const Text('Simular pérdida de conexión'),
                  subtitle: const Text('Para probar el modo offline'),
                  value: ref.watch(connectivityProvider).isOffline &&
                      ref
                          .read(connectivityProvider.notifier)
                          .simulatedCloudLoss,
                  onChanged: (v) => ref
                      .read(connectivityProvider.notifier)
                      .setSimulatedCloudLoss(v),
                ),
            ],
          ),
        ),
        kGap,
        SectionCard(
          title: 'Seguridad',
          icon: Icons.security_rounded,
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: const Text('Sesión'),
                subtitle: Text(
                  auth.session?.expiresAt == null
                      ? 'Sin expiración informada'
                      : 'Expira a las ${DateFormatter.time(auth.session!.expiresAt!)} (los tokens duran 15 min)',
                ),
                trailing: TextButton(
                  onPressed: () => showRenewSessionDialog(context),
                  child: const Text('Renovar'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: const Text('Cambiar contraseña'),
                subtitle: const Text(
                    'Solicítalo a un administrador (el backend no permite autoservicio).'),
                onTap: () => context.push(Routes.accessHelp),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Actividad en este dispositivo'),
                subtitle: const Text('Operaciones registradas desde la app'),
                onTap: () => _showAudit(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          key: const Key('logout'),
          onPressed: () async {
            final ok = await showConfirmDialog(
              context,
              title: '¿Cerrar sesión?',
              message:
                  'Se eliminará la información guardada en este dispositivo.',
              confirmLabel: 'Cerrar sesión',
            );
            if (ok) await ref.read(authControllerProvider.notifier).logout();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesión'),
        ),
        const SizedBox(height: 12),
        Center(
            child: Text('SafeCore Mobile 2.0.0',
                style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }

  Future<void> _showAudit(BuildContext context, WidgetRef ref) async {
    final entries = await ref.read(auditLoggerProvider).entries();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.6,
        child: entries.isEmpty
            ? const Center(child: Text('Sin actividad registrada.'))
            : ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = entries[i];
                  final at = DateFormatter.tryParse(e['at']);
                  return ListTile(
                    dense: true,
                    title: Text('${e['action']}'),
                    subtitle: Text(
                        '${at == null ? '' : DateFormatter.dateTime(at)} · ${e['result']}'),
                  );
                },
              ),
      ),
    );
  }
}
