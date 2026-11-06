import 'package:flutter/material.dart';

import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/visuals.dart';
import '../../../../shared/domain/health_status.dart';
import '../../domain/entities/risk_situation.dart';

StatusTone severityTone(BuildContext c, Severity s) => switch (s) {
      Severity.critical || Severity.high => c.status.critical,
      Severity.medium => c.status.warning,
      Severity.low => c.status.info,
    };

StatusTone riskStatusTone(BuildContext c, RiskStatus s) => switch (s) {
      RiskStatus.open => c.status.critical,
      RiskStatus.acknowledged => c.status.warning,
      RiskStatus.resolved => c.status.normal,
    };

IconData riskIcon(RiskType t) => switch (t) {
      RiskType.fire => Icons.local_fire_department_rounded,
      RiskType.gasOrSmoke => Icons.air_rounded,
      RiskType.earthquake => Icons.vibration_rounded,
      RiskType.sensorFault => Icons.sensors_off_rounded,
      RiskType.unknown => Icons.report_problem_outlined,
    };

/// Tarjeta de riesgo. Los urgentes activos destacan por borde, color,
/// icono y etiqueta (no solo por color).
class RiskTile extends StatelessWidget {
  const RiskTile({super.key, required this.risk, this.deviceName, this.onTap});

  final RiskSituation risk;
  final String? deviceName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tone = risk.isActive
        ? severityTone(context, risk.severity)
        : context.status.offline;
    final urgent = risk.isActive && risk.severity.isUrgent;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: onTap != null,
      label:
          'Riesgo ${risk.riskType.label}, gravedad ${risk.severity.label}, ${risk.status.label}',
      child: Material(
        color: risk.isActive
            ? tone.background
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                  left: BorderSide(
                      color: tone.foreground, width: urgent ? 5 : 3)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                IconBadge(icon: riskIcon(risk.riskType), tone: tone),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        risk.riskType.label,
                        style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: urgent ? tone.foreground : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          deviceName ??
                              (risk.origin == RiskOrigin.manual
                                  ? 'Registro manual'
                                  : 'Sin dispositivo'),
                          DateFormatter.shortDateTime(risk.detectedAt),
                        ].join(' · '),
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          StatusChip(
                            label:
                                'Gravedad ${risk.severity.label.toLowerCase()}',
                            tone: severityTone(context, risk.severity),
                            icon: urgent ? Icons.priority_high_rounded : null,
                          ),
                          StatusChip(
                              label: risk.status.label,
                              tone: riskStatusTone(context, risk.status)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded, color: tone.foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
