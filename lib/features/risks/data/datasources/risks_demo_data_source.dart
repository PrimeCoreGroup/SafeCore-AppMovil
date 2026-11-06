import '../../../../core/errors/failures.dart';
import '../../../../core/security/roles.dart';
import '../../../../shared/services/demo/demo_gateway.dart';
import '../../domain/entities/risk_situation.dart';
import 'risks_data_source.dart';

class RisksDemoDataSource extends DemoGateway implements RisksDataSource {
  RisksDemoDataSource(super.store, {required super.isOnline});

  @override
  Future<List<RiskSituation>> fetchAll() => call(() {
        require(Permission.viewOperations);
        return List.of(store.risks);
      });

  @override
  Future<RiskSituation> create(RiskDraft d) => call(() {
        require(Permission.manageRisks);
        final r = RiskSituation(
          id: store.newId('risk'),
          riskType: d.riskType,
          status: d.status,
          severity: d.severity,
          detectedAt: d.detectedAt,
          origin: RiskOrigin.manual,
          createdAt: store.now,
        );
        store.risks.add(r);
        return r;
      });

  @override
  Future<void> update(String id, RiskDraft d) => call(() {
        require(Permission.manageRisks);
        final i = store.risks.indexWhere((r) => r.id == id);
        if (i < 0) throw const NotFoundFailure();
        final old = store.risks[i];
        store.risks[i] = RiskSituation(
          id: id,
          riskType: d.riskType,
          status: d.status,
          severity: d.severity,
          detectedAt: d.detectedAt,
          origin: old.origin,
          deviceId: old.deviceId,
          alertUntil: old.alertUntil,
          createdAt: old.createdAt,
        );
      });

  @override
  Future<void> delete(String id) => call(() {
        require(Permission.deleteRisks);
        if (store.responses.any((r) => r.riskSituationId == id)) {
          throw const ConflictFailure(
            'El riesgo tiene una respuesta de emergencia vinculada.',
          );
        }
        store.risks.removeWhere((r) => r.id == id);
      });
}
