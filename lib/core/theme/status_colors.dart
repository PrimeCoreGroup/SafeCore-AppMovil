import 'package:flutter/material.dart';

import '../../shared/domain/health_status.dart';
import 'app_colors.dart';

/// Par de colores (primer plano / fondo tintado) para un estado.
@immutable
class StatusTone {
  const StatusTone(this.foreground, this.background);
  final Color foreground;
  final Color background;
}

/// Colores semánticos de estado con soporte de modo claro y oscuro.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.normal,
    required this.warning,
    required this.critical,
    required this.offline,
    required this.info,
  });

  final StatusTone normal;
  final StatusTone warning;
  final StatusTone critical;
  final StatusTone offline;
  final StatusTone info;

  static const light = StatusColors(
    normal: StatusTone(AppColors.success, AppColors.successBg),
    warning: StatusTone(AppColors.warning, AppColors.warningBg),
    critical: StatusTone(AppColors.critical, AppColors.criticalBg),
    offline: StatusTone(AppColors.offline, AppColors.offlineBg),
    info: StatusTone(AppColors.info, AppColors.infoBg),
  );

  static const dark = StatusColors(
    normal: StatusTone(Color(0xFF4ADE80), Color(0xFF12301F)),
    warning: StatusTone(Color(0xFFFBBF24), Color(0xFF3A2C0B)),
    critical: StatusTone(Color(0xFFFF6B6B), Color(0xFF3D1518)),
    offline: StatusTone(Color(0xFFA5B4C8), Color(0xFF1F2A3B)),
    info: StatusTone(Color(0xFF6CB0FF), Color(0xFF13294A)),
  );

  StatusTone health(HealthStatus s) => switch (s) {
        HealthStatus.normal => normal,
        HealthStatus.warning => warning,
        HealthStatus.critical => critical,
        HealthStatus.disconnected => offline,
        HealthStatus.unknown => offline,
      };

  StatusTone severity(Severity s) => switch (s) {
        Severity.critical || Severity.high => critical,
        Severity.medium => warning,
        Severity.low => info,
      };

  @override
  StatusColors copyWith({
    StatusTone? normal,
    StatusTone? warning,
    StatusTone? critical,
    StatusTone? offline,
    StatusTone? info,
  }) =>
      StatusColors(
        normal: normal ?? this.normal,
        warning: warning ?? this.warning,
        critical: critical ?? this.critical,
        offline: offline ?? this.offline,
        info: info ?? this.info,
      );

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) =>
      t < 0.5 ? this : (other as StatusColors? ?? this);
}

extension StatusColorsContext on BuildContext {
  StatusColors get status =>
      Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
}

IconData healthIcon(HealthStatus s) => switch (s) {
      HealthStatus.normal => Icons.check_circle_outline,
      HealthStatus.warning => Icons.warning_amber_rounded,
      HealthStatus.critical => Icons.error_outline,
      HealthStatus.disconnected => Icons.link_off,
      HealthStatus.unknown => Icons.help_outline,
    };

IconData severityIcon(Severity s) => switch (s) {
      Severity.critical || Severity.high => Icons.warning_amber_rounded,
      Severity.medium => Icons.error_outline,
      Severity.low => Icons.info_outline,
    };
