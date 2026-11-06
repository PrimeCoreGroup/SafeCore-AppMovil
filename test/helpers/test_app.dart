import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safecore_mobile/app.dart';
import 'package:safecore_mobile/core/config/app_config.dart';
import 'package:safecore_mobile/core/connectivity/connectivity_probe.dart';
import 'package:safecore_mobile/core/security/token_storage.dart';
import 'package:safecore_mobile/core/storage/local_cache.dart';
import 'package:safecore_mobile/shared/providers/core_providers.dart';
import 'package:safecore_mobile/shared/services/demo/demo_data_store.dart';

/// Entorno de prueba: almacenamiento en memoria, sin Firebase y con
/// conectividad controlable. Por defecto en modo demostración.
class TestEnv {
  TestEnv({bool online = true, this.demo = true})
      : probe = FakeConnectivityProbe(online: online),
        cache = InMemoryLocalCache(),
        tokens = InMemoryTokenStorage(),
        store = DemoDataStore();

  final bool demo;
  final FakeConnectivityProbe probe;
  final InMemoryLocalCache cache;
  final InMemoryTokenStorage tokens;
  final DemoDataStore store;

  AppConfig get config => AppConfig.fromEnvironment().copyWith(
        demoMode: demo,
        firebaseEnabled: false,
        pollInterval: const Duration(hours: 1),
      );

  Widget app() => ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          localCacheProvider.overrideWithValue(cache),
          tokenStorageProvider.overrideWithValue(tokens),
          connectivityProbeProvider.overrideWithValue(probe),
          demoStoreProvider.overrideWithValue(store),
        ],
        child: const SafeCoreApp(),
      );
}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Avanza el tiempo simulado para que terminen las latencias del modo demo.
Future<void> settle(WidgetTester tester, {int steps = 10}) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Desmonta la app para liberar temporizadores al final de cada prueba.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await settle(tester, steps: 20);
}

Future<void> loginAs(WidgetTester tester, String email) async {
  await settle(tester);
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(
      find.byKey(const Key('login-password')), DemoDataStore.demoPassword);
  await tester.tap(find.byKey(const Key('login-submit')));
  await settle(tester, steps: 15);
}
