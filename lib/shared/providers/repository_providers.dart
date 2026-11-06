import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/data/datasources/auth_demo_data_source.dart';
import '../../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../../features/authentication/data/repositories/auth_repository_impl.dart';
import '../../features/authentication/domain/repositories/auth_repository.dart';
import '../../features/configuration/data/datasources/configuration_demo_data_source.dart';
import '../../features/configuration/data/datasources/configuration_remote_data_source.dart';
import '../../features/configuration/data/repositories/configuration_repository_impl.dart';
import '../../features/configuration/domain/repositories/configuration_repository.dart';
import '../../features/dashboard/data/datasources/health_data_source.dart';
import '../../features/dashboard/data/datasources/health_demo_data_source.dart';
import '../../features/devices/data/datasources/devices_demo_data_source.dart';
import '../../features/devices/data/datasources/devices_remote_data_source.dart';
import '../../features/devices/data/repositories/devices_repository_impl.dart';
import '../../features/devices/domain/repositories/devices_repository.dart';
import '../../features/emergency/data/datasources/emergency_demo_data_source.dart';
import '../../features/emergency/data/datasources/emergency_remote_data_source.dart';
import '../../features/emergency/data/repositories/emergency_repository_impl.dart';
import '../../features/emergency/domain/repositories/emergency_repository.dart';
import '../../features/notifications/data/datasources/notifications_demo_data_source.dart';
import '../../features/notifications/data/datasources/notifications_remote_data_source.dart';
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/risks/data/datasources/risks_demo_data_source.dart';
import '../../features/risks/data/datasources/risks_remote_data_source.dart';
import '../../features/risks/data/repositories/risks_repository_impl.dart';
import '../../features/risks/domain/repositories/risks_repository.dart';
import '../../features/telemetry/data/datasources/telemetry_demo_data_source.dart';
import '../../features/telemetry/data/datasources/telemetry_remote_data_source.dart';
import '../../features/telemetry/data/repositories/telemetry_repository_impl.dart';
import '../../features/telemetry/domain/repositories/telemetry_repository.dart';
import '../../features/users/data/datasources/users_demo_data_source.dart';
import '../../features/users/data/datasources/users_remote_data_source.dart';
import '../../features/users/data/repositories/users_repository_impl.dart';
import '../../features/users/domain/repositories/users_repository.dart';
import 'core_providers.dart';

/// Punto único donde se elige entre el backend REAL y la DEMOSTRACIÓN.
/// Las pantallas solo conocen las interfaces de dominio.

bool Function() _demoOnline(Ref ref) =>
    () => ref.read(connectivityProvider.notifier).demoCloudAvailable;

void Function(bool) _reporter(Ref ref) =>
    (r) => ref.read(connectivityProvider.notifier).reportCloud(r);

Duration _stale(Ref ref) => ref.watch(appConfigProvider).staleAfter;

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  final store = ref.watch(demoStoreProvider);
  return AuthRepositoryImpl(
    dataSource: demo
        ? (AuthDemoDataSource(store, isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : AuthRemoteDataSource(ref.watch(apiClientProvider)),
    tokenStorage: ref.watch(tokenStorageProvider),
    cache: ref.watch(localCacheProvider),
    demoStore: demo ? store : null,
  );
});

final healthDataSourceProvider = Provider<HealthDataSource>((ref) {
  if (ref.watch(isDemoProvider)) {
    return HealthDemoDataSource(ref.watch(demoStoreProvider),
        isOnline: _demoOnline(ref))
      ..onReachability = _reporter(ref);
  }
  return HealthRemoteDataSource(ref.watch(apiClientProvider));
});

final devicesRepositoryProvider = Provider<DevicesRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  return DevicesRepositoryImpl(
    demo
        ? (DevicesDemoDataSource(ref.watch(demoStoreProvider),
            isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : DevicesRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(localCacheProvider),
    staleAfter: _stale(ref),
    isDemo: demo,
  );
});

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  return TelemetryRepositoryImpl(
    demo
        ? (TelemetryDemoDataSource(ref.watch(demoStoreProvider),
            isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : TelemetryRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(localCacheProvider),
    staleAfter: _stale(ref),
    isDemo: demo,
  );
});

final risksRepositoryProvider = Provider<RisksRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  return RisksRepositoryImpl(
    demo
        ? (RisksDemoDataSource(ref.watch(demoStoreProvider),
            isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : RisksRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(localCacheProvider),
    staleAfter: _stale(ref),
    isDemo: demo,
  );
});

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  return EmergencyRepositoryImpl(
    demo
        ? (EmergencyDemoDataSource(ref.watch(demoStoreProvider),
            isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : EmergencyRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(localCacheProvider),
    staleAfter: _stale(ref),
    isDemo: demo,
  );
});

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  return NotificationsRepositoryImpl(
    demo
        ? (NotificationsDemoDataSource(ref.watch(demoStoreProvider),
            isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : NotificationsRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(localCacheProvider),
    staleAfter: _stale(ref),
    isDemo: demo,
  );
});

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  return UsersRepositoryImpl(
    demo
        ? (UsersDemoDataSource(ref.watch(demoStoreProvider),
            isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : UsersRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(localCacheProvider),
    staleAfter: _stale(ref),
    isDemo: demo,
  );
});

final configurationRepositoryProvider =
    Provider<ConfigurationRepository>((ref) {
  final demo = ref.watch(isDemoProvider);
  return ConfigurationRepositoryImpl(
    demo
        ? (ConfigurationDemoDataSource(ref.watch(demoStoreProvider),
            isOnline: _demoOnline(ref))
          ..onReachability = _reporter(ref))
        : ConfigurationRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(localCacheProvider),
    staleAfter: _stale(ref),
    isDemo: demo,
  );
});
