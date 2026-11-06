import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/emergency.dart';

class EmergencyMapper {
  const EmergencyMapper._();

  static EmergencyProtocol protocolFromJson(Json j) => EmergencyProtocol(
        id: readString(j, 'id'),
        name: readString(j, 'name', 'Protocolo'),
        emergencyType: readString(j, 'emergencyType'),
        isActive: readBool(j, 'isActive'),
      );

  static Json protocolToJson(EmergencyProtocol p) => {
        'id': p.id,
        'name': p.name,
        'emergencyType': p.emergencyType,
        'isActive': p.isActive,
      };

  static Json protocolDraftToJson(ProtocolDraft d) => {
        'name': d.name.trim(),
        'emergencyType': d.emergencyType.trim(),
        'isActive': d.isActive,
      };

  static EmergencyResponse responseFromJson(Json j) => EmergencyResponse(
        id: readString(j, 'id'),
        protocolId: readString(j, 'protocolId'),
        emergencyType: readString(j, 'emergencyType'),
        riskSituationId: readString(j, 'riskSituationId'),
        status: enumFromApi(
            ResponseStatus.values, j['status'], ResponseStatus.open),
        createdAt: DateFormatter.tryParse(j['createdAt']),
      );

  static Json responseToJson(EmergencyResponse r) => {
        'id': r.id,
        'protocolId': r.protocolId,
        'emergencyType': r.emergencyType,
        'riskSituationId': r.riskSituationId,
        'status': r.status.apiValue,
        if (r.createdAt != null)
          'createdAt': r.createdAt!.toUtc().toIso8601String(),
      };

  static Json responseDraftToJson(ResponseDraft d) => {
        'protocolId': d.protocolId,
        'emergencyType': d.emergencyType,
        'riskSituationId': d.riskSituationId,
        'status': d.status.apiValue,
      };

  static EmergencyAction actionFromJson(Json j) => EmergencyAction(
        id: readString(j, 'id'),
        emergencyResponseId: readString(j, 'emergencyResponseId'),
        actuatorType: readString(j, 'actuatorType'),
        instruction: readString(j, 'instruction'),
        status:
            enumFromApi(ActionStatus.values, j['status'], ActionStatus.pending),
        createdAt: DateFormatter.tryParse(j['createdAt']),
      );

  static Json actionToJson(EmergencyAction a) => {
        'id': a.id,
        'emergencyResponseId': a.emergencyResponseId,
        'actuatorType': a.actuatorType,
        'instruction': a.instruction,
        'status': a.status.apiValue,
        if (a.createdAt != null)
          'createdAt': a.createdAt!.toUtc().toIso8601String(),
      };

  static Json actionDraftToJson(ActionDraft d) => {
        'emergencyResponseId': d.emergencyResponseId,
        'actuatorType': d.actuatorType.trim(),
        'instruction': d.instruction.trim(),
        'status': d.status.apiValue,
      };

  static Json dataToJson(EmergencyData d) => {
        'protocols': d.protocols.map(protocolToJson).toList(),
        'responses': d.responses.map(responseToJson).toList(),
        'actions': d.actions.map(actionToJson).toList(),
      };

  static EmergencyData dataFromJson(Object? raw) {
    final j = asJson(raw);
    return EmergencyData(
      protocols: asJsonList(j['protocols']).map(protocolFromJson).toList(),
      responses: asJsonList(j['responses']).map(responseFromJson).toList(),
      actions: asJsonList(j['actions']).map(actionFromJson).toList(),
    );
  }
}
