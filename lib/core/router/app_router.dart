import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/pages/access_help_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../../features/configuration/presentation/pages/configuration_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/devices/presentation/pages/device_detail_page.dart';
import '../../features/devices/presentation/pages/devices_page.dart';
import '../../features/emergency/presentation/pages/emergency_page.dart';
import '../../features/emergency/presentation/pages/protocols_page.dart';
import '../../features/emergency/presentation/pages/response_detail_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/risks/presentation/pages/risk_detail_page.dart';
import '../../features/risks/presentation/pages/risk_history_page.dart';
import '../../features/risks/presentation/pages/risks_page.dart';
import '../../features/telemetry/presentation/pages/detection_test_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import 'route_guard.dart';
import 'routes.dart';
import 'scaffold_with_nav.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, __) => refresh.value++)
    ..listen(permissionsProvider, (_, __) => refresh.value++)
    ..onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = ref.read(authControllerProvider);
    return RouteGuard.redirect(
      session: switch (auth.status) {
        AuthStatus.checking => SessionPhase.checking,
        AuthStatus.authenticated => SessionPhase.authenticated,
        AuthStatus.unauthenticated => SessionPhase.unauthenticated,
      },
      permissions: ref.read(permissionsProvider),
      location: state.matchedLocation,
    );
  }

  GoRoute leaf(String path, Widget Function(GoRouterState s) page) =>
      GoRoute(path: path, builder: (_, s) => page(s));

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      leaf(Routes.splash, (_) => const SplashPage()),
      leaf(Routes.login, (_) => const LoginPage()),
      leaf(Routes.accessHelp, (_) => const AccessHelpPage()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => ScaffoldWithNav(navigationShell: shell),
        branches: [
          StatefulShellBranch(
              routes: [leaf(Routes.home, (_) => const DashboardPage())]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.devices,
                builder: (_, __) => const DevicesPage(),
                routes: [
                  leaf('detection-test', (_) => const DetectionTestPage()),
                  leaf(
                      ':deviceId',
                      (s) => DeviceDetailPage(
                          deviceId: s.pathParameters['deviceId']!)),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.risks,
                builder: (_, __) => const RisksPage(),
                routes: [
                  leaf('history', (_) => const RiskHistoryPage()),
                  leaf(
                      ':riskId',
                      (s) =>
                          RiskDetailPage(riskId: s.pathParameters['riskId']!)),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.emergency,
                builder: (_, __) => const EmergencyPage(),
                routes: [
                  leaf('protocols', (_) => const ProtocolsPage()),
                  leaf(
                      ':responseId',
                      (s) => ResponseDetailPage(
                          responseId: s.pathParameters['responseId']!)),
                ],
              ),
            ],
          ),
          StatefulShellBranch(routes: [
            leaf(Routes.notifications, (_) => const NotificationsPage())
          ]),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, __) => const ProfilePage(),
                routes: [
                  leaf('users', (_) => const UsersPage()),
                  leaf('configuration', (_) => const ConfigurationPage()),
                  leaf('notification-settings',
                      (_) => const NotificationSettingsPage()),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
