import '../../../../core/errors/failures.dart';
import '../../../../core/security/roles.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/emergency.dart';
import 'emergency_data_source.dart';

class EmergencyDemoDataSource extends DemoGateway
    implements EmergencyDataSource {
  EmergencyDemoDataSource(super.store, {required super.isOnline});

  @override
  Future<EmergencyData> fetchAll() => call(() {
        require(Permission.viewOperations);
        return EmergencyData(
          protocols: [...store.protocols]
            ..sort((a, b) => a.name.compareTo(b.name)),
          responses: List.of(store.responses),
          actions: List.of(store.actions),
        );
      });

  @override
  Future<EmergencyProtocol> createProtocol(ProtocolDraft d) => call(() {
        require(Permission.manageProtocols);
        final p = EmergencyProtocol(
          id: store.newId('pr'),
          name: d.name.trim(),
          emergencyType: d.emergencyType.trim(),
          isActive: d.isActive,
        );
        store.protocols.add(p);
        return p;
      });

  @override
  Future<void> updateProtocol(String id, ProtocolDraft d) => call(() {
        require(Permission.manageProtocols);
        final i = store.protocols.indexWhere((p) => p.id == id);
        if (i < 0) throw const NotFoundFailure();
        store.protocols[i] = EmergencyProtocol(
          id: id,
          name: d.name.trim(),
          emergencyType: d.emergencyType.trim(),
          isActive: d.isActive,
        );
      });

  @override
  Future<void> deleteProtocol(String id) => call(() {
        require(Permission.deleteProtocols);
        if (store.responses.any((r) => r.protocolId == id)) {
          throw const ConflictFailure(
              'El protocolo está en uso por una respuesta.');
        }
        store.protocols.removeWhere((p) => p.id == id);
      });

  void _validateRefs(ResponseDraft d) {
    final p = store.protocols.where((x) => x.id == d.protocolId).firstOrNull;
    if (p == null || !p.isActive) {
      throw const ValidationFailure('El protocolo no existe o no está activo.');
    }
    if (!store.risks.any((r) => r.id == d.riskSituationId)) {
      throw const ValidationFailure('La situación de riesgo no existe.');
    }
  }

  @override
  Future<EmergencyResponse> createResponse(ResponseDraft d) => call(() {
        require(Permission.createResponses);
        _validateRefs(d);
        final r = EmergencyResponse(
          id: store.newId('resp'),
          protocolId: d.protocolId,
          emergencyType: d.emergencyType,
          riskSituationId: d.riskSituationId,
          status: d.status,
          createdAt: store.now,
        );
        store.responses.add(r);
        return r;
      });

  @override
  Future<void> updateResponse(String id, ResponseDraft d) => call(() {
        require(Permission.updateResponses);
        final i = store.responses.indexWhere((r) => r.id == id);
        if (i < 0) throw const NotFoundFailure();
        final old = store.responses[i];
        if (d.protocolId != old.protocolId) _validateRefs(d);
        store.responses[i] = EmergencyResponse(
          id: id,
          protocolId: d.protocolId,
          emergencyType: d.emergencyType,
          riskSituationId: d.riskSituationId,
          status: d.status,
          createdAt: old.createdAt,
        );
      });

  @override
  Future<EmergencyAction> createAction(ActionDraft d) => call(() {
        require(Permission.manageActions);
        if (!store.responses.any((r) => r.id == d.emergencyResponseId)) {
          throw const ValidationFailure(
              'La respuesta de emergencia no existe.');
        }
        final a = EmergencyAction(
          id: store.newId('act'),
          emergencyResponseId: d.emergencyResponseId,
          actuatorType: d.actuatorType.trim(),
          instruction: d.instruction.trim(),
          status: d.status,
          createdAt: store.now,
        );
        store.actions.add(a);
        return a;
      });

  @override
  Future<void> updateAction(String id, ActionDraft d) => call(() {
        require(Permission.manageActions);
        final i = store.actions.indexWhere((a) => a.id == id);
        if (i < 0) throw const NotFoundFailure();
        store.actions[i] = EmergencyAction(
          id: id,
          emergencyResponseId: d.emergencyResponseId,
          actuatorType: d.actuatorType.trim(),
          instruction: d.instruction.trim(),
          status: d.status,
          createdAt: store.actions[i].createdAt,
        );
      });
}
