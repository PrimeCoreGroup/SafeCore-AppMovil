import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audit/audit_logger.dart';
import '../../core/config/app_config.dart';
import '../../core/connectivity/connectivity_plus_probe.dart';
import '../../core/connectivity/connectivity_probe.dart';
import '../../core/connectivity/connectivity_status.dart';
import '../../core/connectivity/session_events.dart';
import '../../core/network/api_client.dart';
import '../../core/network/dio_factory.dart';
import '../../core/security/secure_token_storage.dart';
import '../../core/security/token_storage.dart';
import '../../core/storage/local_cache.dart';
import '../services/demo/demo_data_store.dart';

/// Configuración de compilación (sobrescribible en pruebas).
final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

/// Modo demostración. Arranca según la compilación y puede activarse desde
/// el login ("Explorar en modo demostración"). Al cerrar sesión vuelve al
/// valor de compilación.
final isDemoProvider =
    StateProvider<bool>((ref) => ref.watch(appConfigProvider).demoMode);

/// Se sobrescribe en `main.dart` con la implementación SQLite.
final localCacheProvider = Provider<LocalCache>((ref) => InMemoryLocalCache());

final tokenStorageProvider =
    Provider<TokenStorage>((ref) => SecureTokenStorage());

final demoStoreProvider = Provider<DemoDataStore>((ref) => DemoDataStore());

final auditLoggerProvider =
    Provider<AuditLogger>((ref) => AuditLogger(ref.watch(localCacheProvider)));

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

// ---------------------------------------------------------------------------
// Conectividad
// ---------------------------------------------------------------------------

final connectivityProbeProvider =
    Provider<ConnectivityProbe>((ref) => ConnectivityPlusProbe());

/// Estado de conectividad teléfono ↔ nube. El estado del nodo Edge se
/// obtiene de los datos de dispositivos, no de aquí.
class ConnectivityController extends Notifier<ConnectivityStatus> {
  bool _simulatedCloudLoss = false;
  bool _disposed = false;

  @override
  ConnectivityStatus build() {
    final probe = ref.watch(connectivityProbeProvider);
    final sub = probe.onChanged.listen(_onDeviceChanged);
    ref.onDispose(() {
      _disposed = true;
      unawaited(sub.cancel());
    });
    unawaited(
      probe.isOnline().then(_onDeviceChanged, onError: (Object _) {}),
    );
    return const ConnectivityStatus.initial();
  }

  void _onDeviceChanged(bool online) {
    if (_disposed || state.deviceOnline == online) return;
    state = state.copyWith(
      deviceOnline: online,
      // Al recuperar red se asume la nube alcanzable hasta que una
      // petición demuestre lo contrario.
      cloudReachable: online ? !_simulatedCloudLoss : state.cloudReachable,
    );
  }

  /// Llamado por el cliente HTTP tras cada petición.
  void reportCloud(bool reachable) {
    if (_disposed) return;
    final value = reachable && !_simulatedCloudLoss;
    if (state.cloudReachable == value) return;
    state = state.copyWith(
      cloudReachable: value,
      lastCloudContact: value ? DateTime.now() : state.lastCloudContact,
    );
  }

  /// Solo modo demostración: permite probar el modo offline sin apagar la red.
  bool get simulatedCloudLoss => _simulatedCloudLoss;

  void setSimulatedCloudLoss(bool value) {
    _simulatedCloudLoss = value;
    state = state.copyWith(cloudReachable: !value);
  }

  bool get demoCloudAvailable => state.deviceOnline && !_simulatedCloudLoss;
}

final connectivityProvider =
    NotifierProvider<ConnectivityController, ConnectivityStatus>(
  ConnectivityController.new,
);

// ---------------------------------------------------------------------------
// Red
// ---------------------------------------------------------------------------

final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionExpired: () =>
        ref.read(sessionEventsProvider).notifySessionExpired(),
  );
  ref.onDispose(dio.close);
  return dio;
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(dioProvider),
    onReachability: (r) =>
        ref.read(connectivityProvider.notifier).reportCloud(r),
  ),
);
