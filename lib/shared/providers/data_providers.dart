import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../core/security/roles.dart';
import '../../core/utils/data_result.dart';
import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../../features/configuration/domain/entities/system_configuration.dart';
import '../../features/dashboard/domain/entities/backend_health.dart';
import '../../features/devices/domain/entities/device.dart';
import '../../features/emergency/domain/entities/emergency.dart';
import '../../features/notifications/domain/entities/app_notification.dart';
import '../../features/risks/domain/entities/risk_situation.dart';
import '../../features/telemetry/domain/entities/sensor_reading.dart';
import '../../features/telemetry/domain/services/telemetry_summary.dart';
import '../../features/users/domain/entities/managed_user.dart';
import 'repository_providers.dart';

/// Identificador de la sesión: al cambiar de usuario se recargan los datos.
String _session(Ref ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw const SessionExpiredFailure();
  return user.id;
}

final healthProvider = FutureProvider<BackendHealth>(
  (ref) => ref.watch(healthDataSourceProvider).check(),
);

final devicesProvider = FutureProvider<DataResult<List<Device>>>((ref) {
  _session(ref);
  return ref.watch(devicesRepositoryProvider).getDevices();
});

final readingsProvider = FutureProvider<DataResult<List<SensorReading>>>((ref) {
  _session(ref);
  return ref.watch(telemetryRepositoryProvider).getLatestReadings();
});

final telemetryByDeviceProvider =
    Provider<Map<String, DeviceTelemetry>?>((ref) {
  final r = ref.watch(readingsProvider).valueOrNull;
  return r == null ? null : TelemetrySummary.byDevice(r.data);
});

final risksProvider = FutureProvider<DataResult<List<RiskSituation>>>((ref) {
  _session(ref);
  return ref.watch(risksRepositoryProvider).getRisks();
});

final emergencyProvider = FutureProvider<DataResult<EmergencyData>>((ref) {
  _session(ref);
  return ref.watch(emergencyRepositoryProvider).getAll();
});

/// Bandeja según rol: personal operativo ve todas; residente, solo las suyas.
final notificationsProvider =
    FutureProvider<DataResult<List<AppNotification>>>((ref) {
  _session(ref);
  final repo = ref.watch(notificationsRepositoryProvider);
  return ref.watch(canProvider(Permission.viewAllNotifications))
      ? repo.getAll()
      : repo.getMine();
});

final usersProvider = FutureProvider<DataResult<List<ManagedUser>>>((ref) {
  _session(ref);
  return ref.watch(usersRepositoryProvider).getUsers();
});

final configurationsProvider =
    FutureProvider<DataResult<List<SystemConfiguration>>>((ref) {
  _session(ref);
  return ref.watch(configurationRepositoryProvider).getAll();
});

/// Refresca los datos operativos (manual, sondeo o reconexión).
void refreshOperational(void Function(ProviderOrFamily) invalidate) {
  invalidate(healthProvider);
  invalidate(devicesProvider);
  invalidate(readingsProvider);
  invalidate(risksProvider);
  invalidate(emergencyProvider);
  invalidate(notificationsProvider);
}

Device? deviceById(List<Device>? devices, String? id) =>
    id == null ? null : devices?.where((d) => d.id == id).firstOrNull;
