import '../../domain/entities/risk_situation.dart';

abstract interface class RisksDataSource {
  Future<List<RiskSituation>> fetchAll();
  Future<RiskSituation> create(RiskDraft draft);
  Future<void> update(String id, RiskDraft draft);
  Future<void> delete(String id);
}
