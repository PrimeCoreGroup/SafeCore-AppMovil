import '../../../../core/utils/data_result.dart';
import '../entities/system_configuration.dart';

abstract interface class ConfigurationRepository {
  Future<DataResult<List<SystemConfiguration>>> getAll();
  Future<SystemConfiguration> create(ConfigurationDraft draft);
  Future<void> update(String id, ConfigurationDraft draft);
}
