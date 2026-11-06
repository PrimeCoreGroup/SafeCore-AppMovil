/// Estado operativo normalizado.
enum HealthStatus {
  normal,
  warning,
  critical,
  disconnected,
  unknown;

  String get label => switch (this) {
        HealthStatus.normal => 'Normal',
        HealthStatus.warning => 'Advertencia',
        HealthStatus.critical => 'Crítico',
        HealthStatus.disconnected => 'Sin conexión',
        HealthStatus.unknown => 'Sin información',
      };

  int get priority => switch (this) {
        HealthStatus.critical => 0,
        HealthStatus.warning => 1,
        HealthStatus.disconnected => 2,
        HealthStatus.unknown => 3,
        HealthStatus.normal => 4,
      };
}

/// Gravedad del backend: `Critical`, `High`, `Medium`, `Low`.
enum Severity {
  critical,
  high,
  medium,
  low;

  String get label => switch (this) {
        Severity.critical => 'Crítica',
        Severity.high => 'Alta',
        Severity.medium => 'Media',
        Severity.low => 'Baja',
      };

  String get apiValue => switch (this) {
        Severity.critical => 'Critical',
        Severity.high => 'High',
        Severity.medium => 'Medium',
        Severity.low => 'Low',
      };

  /// Requiere atención inmediata.
  bool get isUrgent => this == Severity.critical || this == Severity.high;

  int get priority => index;

  static Severity fromApi(Object? raw) {
    final v = raw?.toString().toLowerCase();
    for (final s in Severity.values) {
      if (s.apiValue.toLowerCase() == v) return s;
    }
    return Severity.medium;
  }
}
