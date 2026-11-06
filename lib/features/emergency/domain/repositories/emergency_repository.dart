import '../../../../core/utils/data_result.dart';
import '../entities/emergency.dart';

abstract interface class EmergencyRepository {
  Future<DataResult<EmergencyData>> getAll();

  Future<EmergencyProtocol> createProtocol(ProtocolDraft draft);
  Future<void> updateProtocol(String id, ProtocolDraft draft);
  Future<void> deleteProtocol(String id);

  Future<EmergencyResponse> createResponse(ResponseDraft draft);
  Future<void> updateResponse(String id, ResponseDraft draft);

  Future<EmergencyAction> createAction(ActionDraft draft);
  Future<void> updateAction(String id, ActionDraft draft);
}
