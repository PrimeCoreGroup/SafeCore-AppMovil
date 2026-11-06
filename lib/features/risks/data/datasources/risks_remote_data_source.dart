import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/risk_situation.dart';
import '../models/risk_mapper.dart';
import 'risks_data_source.dart';

class RisksRemoteDataSource implements RisksDataSource {
  RisksRemoteDataSource(this._api);
  final ApiClient _api;

  @override
  Future<List<RiskSituation>> fetchAll() => fetchAllPages(
        (page, size) async => RiskMapper.listFromJson(
          await _api.get(
            ApiEndpoints.riskSituations,
            query: {'page': page, 'pageSize': size},
          ),
        ),
      );

  @override
  Future<RiskSituation> create(RiskDraft draft) async => RiskMapper.fromJson(
        asJson(
          await _api.post(
            ApiEndpoints.riskSituations,
            body: RiskMapper.draftToJson(draft),
          ),
        ),
      );

  @override
  Future<void> update(String id, RiskDraft draft) => _api
      .put(ApiEndpoints.riskSituation(id), body: RiskMapper.draftToJson(draft));

  @override
  Future<void> delete(String id) => _api.delete(ApiEndpoints.riskSituation(id));
}
