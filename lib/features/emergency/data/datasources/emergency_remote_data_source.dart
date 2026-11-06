import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/emergency.dart';
import '../models/emergency_mapper.dart';
import 'emergency_data_source.dart';

class EmergencyRemoteDataSource implements EmergencyDataSource {
  EmergencyRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<T>> _all<T>(String path, T Function(Json) map) => fetchAllPages(
        (page, size) async => asJsonList(
          await _api.get(path, query: {'page': page, 'pageSize': size}),
        ).map(map).toList(),
      );

  @override
  Future<EmergencyData> fetchAll() async {
    final results = await Future.wait([
      _all(ApiEndpoints.protocols, EmergencyMapper.protocolFromJson),
      _all(ApiEndpoints.responses, EmergencyMapper.responseFromJson),
      _all(ApiEndpoints.actions, EmergencyMapper.actionFromJson),
    ]);
    return EmergencyData(
      protocols: results[0].cast<EmergencyProtocol>(),
      responses: results[1].cast<EmergencyResponse>(),
      actions: results[2].cast<EmergencyAction>(),
    );
  }

  @override
  Future<EmergencyProtocol> createProtocol(ProtocolDraft d) async =>
      EmergencyMapper.protocolFromJson(
        asJson(
          await _api.post(
            ApiEndpoints.protocols,
            body: EmergencyMapper.protocolDraftToJson(d),
          ),
        ),
      );

  @override
  Future<void> updateProtocol(String id, ProtocolDraft d) => _api.put(
        ApiEndpoints.protocol(id),
        body: EmergencyMapper.protocolDraftToJson(d),
      );

  @override
  Future<void> deleteProtocol(String id) =>
      _api.delete(ApiEndpoints.protocol(id));

  @override
  Future<EmergencyResponse> createResponse(ResponseDraft d) async =>
      EmergencyMapper.responseFromJson(
        asJson(
          await _api.post(
            ApiEndpoints.responses,
            body: EmergencyMapper.responseDraftToJson(d),
          ),
        ),
      );

  @override
  Future<void> updateResponse(String id, ResponseDraft d) => _api.put(
        ApiEndpoints.response(id),
        body: EmergencyMapper.responseDraftToJson(d),
      );

  @override
  Future<EmergencyAction> createAction(ActionDraft d) async =>
      EmergencyMapper.actionFromJson(
        asJson(
          await _api.post(
            ApiEndpoints.actions,
            body: EmergencyMapper.actionDraftToJson(d),
          ),
        ),
      );

  @override
  Future<void> updateAction(String id, ActionDraft d) => _api.put(
        ApiEndpoints.action(id),
        body: EmergencyMapper.actionDraftToJson(d),
      );
}
