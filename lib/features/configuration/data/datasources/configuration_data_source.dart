import '../../domain/entities/system_configuration.dart';

abstract interface class ConfigurationDataSource {
  Future<List<SystemConfiguration>> fetchAll();
  Future<SystemConfiguration> create(ConfigurationDraft d);
  Future<void> update(String id, ConfigurationDraft d);
}
