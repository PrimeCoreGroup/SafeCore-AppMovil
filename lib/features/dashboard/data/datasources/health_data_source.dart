import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/backend_health.dart';

abstract interface class HealthDataSource {
  Future<BackendHealth> check();
}

/// `GET /health/ready` (público): 200 `{status: ready}` o 503.
class HealthRemoteDataSource implements HealthDataSource {
  HealthRemoteDataSource(this._api);
  final ApiClient _api;

  @override
  Future<BackendHealth> check() async {
    try {
      final body = asJson(await _api.get(ApiEndpoints.healthReady));
      return BackendHealth(
        ready: readString(body, 'status').toLowerCase() == 'ready',
        checkedAt: DateTime.now(),
      );
    } on ServiceUnavailableFailure {
      return BackendHealth(
        ready: false,
        checkedAt: DateTime.now(),
        detail: 'La base de datos del backend no está disponible.',
      );
    }
  }
}
