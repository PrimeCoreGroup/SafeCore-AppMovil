import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/system_configuration.dart';
import '../models/configuration_mapper.dart';
import 'configuration_data_source.dart';

class ConfigurationRemoteDataSource implements ConfigurationDataSource {
  ConfigurationRemoteDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<SystemConfiguration>> fetchAll() => fetchAllPages(
        (page, size) async => ConfigurationMapper.listFromJson(
          await _api.get(
            ApiEndpoints.configurations,
            query: {'page': page, 'pageSize': size},
          ),
        ),
      );

  @override
  Future<SystemConfiguration> create(ConfigurationDraft d) async =>
      ConfigurationMapper.fromJson(
        asJson(
          await _api.post(
            ApiEndpoints.configurations,
            body: ConfigurationMapper.draftToJson(d),
          ),
        ),
      );

  @override
  Future<void> update(String id, ConfigurationDraft d) => _api.put(
        ApiEndpoints.configuration(id),
        body: ConfigurationMapper.draftToJson(d),
      );
}
