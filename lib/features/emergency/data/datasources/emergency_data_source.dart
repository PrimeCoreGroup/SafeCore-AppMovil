import '../../domain/entities/emergency.dart';

abstract interface class EmergencyDataSource {
  Future<EmergencyData> fetchAll();
  Future<EmergencyProtocol> createProtocol(ProtocolDraft d);
  Future<void> updateProtocol(String id, ProtocolDraft d);
  Future<void> deleteProtocol(String id);
  Future<EmergencyResponse> createResponse(ResponseDraft d);
  Future<void> updateResponse(String id, ResponseDraft d);
  Future<EmergencyAction> createAction(ActionDraft d);
  Future<void> updateAction(String id, ActionDraft d);
}
