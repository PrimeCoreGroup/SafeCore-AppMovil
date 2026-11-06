import '../entities/risk_situation.dart';

/// Reglas de priorización y recomendaciones de seguridad.
class RiskRules {
  const RiskRules._();

  /// Activos primero, luego por gravedad y por fecha (recientes primero).
  static List<RiskSituation> sortByPriority(Iterable<RiskSituation> risks) =>
      risks.toList()
        ..sort((a, b) {
          final act = (a.isActive ? 0 : 1).compareTo(b.isActive ? 0 : 1);
          if (act != 0) return act;
          final st = (a.status == RiskStatus.open ? 0 : 1)
              .compareTo(b.status == RiskStatus.open ? 0 : 1);
          if (st != 0) return st;
          final sev = a.severity.priority.compareTo(b.severity.priority);
          if (sev != 0) return sev;
          return b.detectedAt.compareTo(a.detectedAt);
        });

  static List<RiskSituation> active(Iterable<RiskSituation> risks) =>
      sortByPriority(risks.where((r) => r.isActive));

  static List<RiskSituation> resolved(Iterable<RiskSituation> risks) =>
      risks.where((r) => !r.isActive).toList()
        ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));

  /// Pautas generales por tipo. No reemplazan a las autoridades.
  static List<String> recommendationsFor(RiskType type) => switch (type) {
        RiskType.earthquake => const [
            'Mantén la calma y dirígete a la zona segura más cercana.',
            'Aléjate de ventanas y objetos que puedan caer.',
            'Evacúa por las rutas señalizadas; no uses ascensores.',
            'Emergencias: Bomberos 116 · Policía 105 · SAMU 106.',
          ],
        RiskType.fire => const [
            'Evacúa de inmediato por la ruta de evacuación.',
            'Si hay humo, desplázate agachado y cubre nariz y boca.',
            'No regreses hasta que los bomberos lo autoricen.',
            'Llama a los Bomberos al 116.',
          ],
        RiskType.gasOrSmoke => const [
            'No enciendas ni apagues interruptores ni aparatos eléctricos.',
            'No uses fuego ni generes chispas.',
            'Si es seguro, ventila abriendo puertas y ventanas y evacúa.',
            'Llama a los Bomberos al 116 desde fuera del inmueble.',
          ],
        RiskType.sensorFault || RiskType.unknown => const [
            'Revisa la conexión y alimentación del sensor indicado.',
            'Mientras persista la falla, la cobertura de esa zona está reducida.',
            'Coordina la revisión con el técnico instalador.',
          ],
      };
}
