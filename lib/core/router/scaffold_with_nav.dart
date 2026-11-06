import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../../features/notifications/presentation/providers/notification_providers.dart';
import '../../shared/providers/core_providers.dart';
import '../../shared/providers/data_providers.dart';
import '../security/roles.dart';
import '../widgets/app_chrome.dart';

/// Ramas de la navegación (índices del StatefulShellRoute).
class NavBranch {
  static const home = 0;
  static const devices = 1;
  static const risks = 2;
  static const emergency = 3;
  static const notifications = 4;
  static const profile = 5;
}

class _Dest {
  const _Dest(this.branch, this.icon, this.selected, this.label);
  final int branch;
  final IconData icon;
  final IconData selected;
  final String label;
}

/// Contenedor con navegación inferior según el rol, banner offline, aviso
/// de expiración de sesión y sondeo periódico.
class ScaffoldWithNav extends ConsumerStatefulWidget {
  const ScaffoldWithNav({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends ConsumerState<ScaffoldWithNav>
    with WidgetsBindingObserver {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(ref.read(appConfigProvider).pollInterval, (_) {
      if (ref.read(connectivityProvider).canReachCloud) {
        refreshOperational(ref.invalidate);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshOperational(ref.invalidate);
      _startPolling();
    } else if (state == AppLifecycleState.paused) {
      _poll?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final operational = perms.contains(Permission.viewOperations);
    final openRisks = operational
        ? (ref
                .watch(risksProvider)
                .valueOrNull
                ?.data
                .where((r) => r.isActive)
                .length ??
            0)
        : 0;
    final unread = ref.watch(unreadCountProvider);
    final dests = <_Dest>[
      const _Dest(
          NavBranch.home, Icons.home_outlined, Icons.home_rounded, 'Inicio'),
      if (operational) ...const [
        _Dest(NavBranch.devices, Icons.memory_outlined, Icons.memory_rounded,
            'Dispositivos'),
        _Dest(NavBranch.risks, Icons.warning_amber_outlined,
            Icons.warning_amber_rounded, 'Riesgos'),
        _Dest(NavBranch.emergency, Icons.emergency_outlined,
            Icons.emergency_rounded, 'Emergencias'),
      ] else
        const _Dest(NavBranch.notifications, Icons.notifications_none_rounded,
            Icons.notifications_rounded, 'Avisos'),
      const _Dest(NavBranch.profile, Icons.person_outline_rounded,
          Icons.person_rounded, 'Perfil'),
    ];
    final shell = widget.navigationShell;
    var selected = dests.indexWhere((d) => d.branch == shell.currentIndex);
    if (selected < 0) selected = 0;

    Widget icon(_Dest d, IconData data) {
      final count = d.branch == NavBranch.risks
          ? openRisks
          : d.branch == NavBranch.notifications
              ? unread
              : 0;
      return Badge(
          isLabelVisible: count > 0, label: Text('$count'), child: Icon(data));
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SessionExpiryBanner(),
          const ConnectivityBanner(),
          NavigationBar(
            selectedIndex: selected,
            onDestinationSelected: (i) {
              final b = dests[i].branch;
              shell.goBranch(b, initialLocation: b == shell.currentIndex);
            },
            destinations: [
              for (final d in dests)
                NavigationDestination(
                    icon: icon(d, d.icon),
                    selectedIcon: icon(d, d.selected),
                    label: d.label),
            ],
          ),
        ],
      ),
    );
  }
}
