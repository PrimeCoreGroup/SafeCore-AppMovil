import '../../../../core/errors/failures.dart';
import '../../../../core/security/roles.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/system_configuration.dart';
import 'configuration_data_source.dart';

class ConfigurationDemoDataSource extends DemoGateway
    implements ConfigurationDataSource {
  ConfigurationDemoDataSource(super.store, {required super.isOnline});

  @override
  Future<List<SystemConfiguration>> fetchAll() => call(() {
        require(Permission.viewConfiguration);
        return List.of(store.configurations);
      });

  @override
  Future<SystemConfiguration> create(ConfigurationDraft d) => call(() {
        require(Permission.editConfiguration);
        if (d.version < 1) {
          throw const ValidationFailure('La versión debe ser ≥ 1.');
        }
        final c = SystemConfiguration(
          id: store.newId('cfg'),
          version: d.version,
          syncStatus: d.syncStatus,
          lastSyncedAt: d.lastSyncedAt,
        );
        store.configurations.add(c);
        return c;
      });

  @override
  Future<void> update(String id, ConfigurationDraft d) => call(() {
        require(Permission.editConfiguration);
        final i = store.configurations.indexWhere((c) => c.id == id);
        if (i < 0) throw const NotFoundFailure();
        store.configurations[i] = SystemConfiguration(
          id: id,
          version: d.version,
          syncStatus: d.syncStatus,
          lastSyncedAt: d.lastSyncedAt,
        );
      });
}
