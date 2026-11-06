import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/backend_health.dart';
import 'health_data_source.dart';

class HealthDemoDataSource extends DemoGateway implements HealthDataSource {
  HealthDemoDataSource(super.store, {required super.isOnline});

  @override
  Future<BackendHealth> check() => call(
      () => BackendHealth(ready: true, checkedAt: store.now, detail: 'Demo'));
}
