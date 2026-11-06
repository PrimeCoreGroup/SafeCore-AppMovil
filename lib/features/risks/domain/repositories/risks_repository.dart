import '../../../../core/utils/data_result.dart';
import '../entities/risk_situation.dart';

abstract interface class RisksRepository {
  Future<DataResult<List<RiskSituation>>> getRisks();
  Future<RiskSituation> create(RiskDraft draft);
  Future<void> update(String id, RiskDraft draft);
  Future<void> delete(String id);
}
