/// Protocolo de emergencia (`/api/emergency/protocols`).
class EmergencyProtocol {
  const EmergencyProtocol({
    required this.id,
    required this.name,
    required this.emergencyType,
    required this.isActive,
  });

  final String id;
  final String name;
  final String emergencyType;
  final bool isActive;
}

class ProtocolDraft {
  const ProtocolDraft({
    required this.name,
    required this.emergencyType,
    required this.isActive,
  });

  final String name;
  final String emergencyType;
  final bool isActive;

  static String? validateName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa un nombre.';
    return s.length > 100 ? 'Máximo 100 caracteres.' : null;
  }

  static String? validateType(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Ingresa el tipo de emergencia.';
    return s.length > 50 ? 'Máximo 50 caracteres.' : null;
  }
}

enum ResponseStatus {
  open,
  inProgress,
  resolved,
  cancelled;

  String get label => switch (this) {
        ResponseStatus.open => 'Abierta',
        ResponseStatus.inProgress => 'En curso',
        ResponseStatus.resolved => 'Resuelta',
        ResponseStatus.cancelled => 'Cancelada',
      };

  String get apiValue => switch (this) {
        ResponseStatus.open => 'Open',
        ResponseStatus.inProgress => 'InProgress',
        ResponseStatus.resolved => 'Resolved',
        ResponseStatus.cancelled => 'Cancelled',
      };

  bool get isActive => this == open || this == inProgress;
}

/// Respuesta de emergencia vinculada a un riesgo y un protocolo.
class EmergencyResponse {
  const EmergencyResponse({
    required this.id,
    required this.protocolId,
    required this.emergencyType,
    required this.riskSituationId,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String protocolId;
  final String emergencyType;
  final String riskSituationId;
  final ResponseStatus status;
  final DateTime? createdAt;
}

class ResponseDraft {
  const ResponseDraft({
    required this.protocolId,
    required this.emergencyType,
    required this.riskSituationId,
    required this.status,
  });

  factory ResponseDraft.from(EmergencyResponse r, {ResponseStatus? status}) =>
      ResponseDraft(
        protocolId: r.protocolId,
        emergencyType: r.emergencyType,
        riskSituationId: r.riskSituationId,
        status: status ?? r.status,
      );

  final String protocolId;
  final String emergencyType;
  final String riskSituationId;
  final ResponseStatus status;
}

/// Estado de una acción de coordinación.
///
/// IMPORTANTE: el backend registra la coordinación pero NO envía comandos
/// físicos al ESP32. "Completada" significa que una persona lo registró así.
enum ActionStatus {
  pending,
  dispatched,
  completed,
  failed,
  cancelled;

  String get label => switch (this) {
        ActionStatus.pending => 'Pendiente',
        ActionStatus.dispatched => 'Despachada',
        ActionStatus.completed => 'Completada (registrada)',
        ActionStatus.failed => 'Fallida',
        ActionStatus.cancelled => 'Cancelada',
      };

  String get apiValue => switch (this) {
        ActionStatus.pending => 'Pending',
        ActionStatus.dispatched => 'Dispatched',
        ActionStatus.completed => 'Completed',
        ActionStatus.failed => 'Failed',
        ActionStatus.cancelled => 'Cancelled',
      };

  bool get isOpen => this == pending || this == dispatched;
}

class EmergencyAction {
  const EmergencyAction({
    required this.id,
    required this.emergencyResponseId,
    required this.actuatorType,
    required this.instruction,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String emergencyResponseId;
  final String actuatorType;
  final String instruction;
  final ActionStatus status;
  final DateTime? createdAt;
}

class ActionDraft {
  const ActionDraft({
    required this.emergencyResponseId,
    required this.actuatorType,
    required this.instruction,
    required this.status,
  });

  factory ActionDraft.from(EmergencyAction a, {ActionStatus? status}) =>
      ActionDraft(
        emergencyResponseId: a.emergencyResponseId,
        actuatorType: a.actuatorType,
        instruction: a.instruction,
        status: status ?? a.status,
      );

  final String emergencyResponseId;
  final String actuatorType;
  final String instruction;
  final ActionStatus status;

  /// Tipos de actuador sugeridos (texto libre en el backend, máx. 50).
  static const suggestedActuators = [
    'Relay',
    'Valve',
    'Buzzer',
    'Light',
    'DoorLock',
    'Sprinkler',
  ];

  static String actuatorLabel(String t) => switch (t.toLowerCase()) {
        'relay' => 'Relé / corte eléctrico',
        'valve' => 'Válvula de gas',
        'buzzer' => 'Sirena / buzzer',
        'light' => 'Iluminación de emergencia',
        'doorlock' => 'Cerrojo de acceso',
        'sprinkler' => 'Rociador',
        _ => t,
      };

  static String? validateActuator(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Indica el tipo de actuador.';
    return s.length > 50 ? 'Máximo 50 caracteres.' : null;
  }

  static String? validateInstruction(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Describe la instrucción.';
    return s.length > 1000 ? 'Máximo 1000 caracteres.' : null;
  }
}

/// Bundle de datos de emergencias.
class EmergencyData {
  const EmergencyData({
    required this.protocols,
    required this.responses,
    required this.actions,
  });

  final List<EmergencyProtocol> protocols;
  final List<EmergencyResponse> responses;
  final List<EmergencyAction> actions;

  EmergencyProtocol? protocol(String id) =>
      protocols.where((p) => p.id == id).firstOrNull;

  List<EmergencyResponse> responsesForRisk(String riskId) =>
      responses.where((r) => r.riskSituationId == riskId).toList();

  List<EmergencyAction> actionsFor(String responseId) =>
      actions.where((a) => a.emergencyResponseId == responseId).toList()
        ..sort((a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
}
