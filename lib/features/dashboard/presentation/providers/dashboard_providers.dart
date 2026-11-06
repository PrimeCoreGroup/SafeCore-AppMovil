import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../domain/services/system_assessor.dart';

final systemAssessmentProvider = Provider<SystemAssessment>((ref) {
  final devices = ref.watch(devicesProvider).valueOrNull;
  final risks = ref.watch(risksProvider).valueOrNull;
  final readings = ref.watch(readingsProvider).valueOrNull;
  final stale = [devices, risks, readings]
      .any((r) => r != null && (r.isStale || r.fromCache));
  return SystemAssessor.assess(
    devices: devices?.data,
    risks: risks?.data,
    telemetry: ref.watch(telemetryByDeviceProvider),
    health: ref.watch(healthProvider).valueOrNull,
    canReachCloud: ref.watch(connectivityProvider).canReachCloud,
    dataIsStale: stale,
    now: DateTime.now(),
  );
});
