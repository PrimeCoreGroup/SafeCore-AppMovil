/// Roles del backend SafeCore (globales por usuario).
enum UserRole {
  administrator,
  operator,
  responder,
  resident,
  unknown;

  String get label => switch (this) {
        UserRole.administrator => 'Administrador',
        UserRole.operator => 'Operador',
        UserRole.responder => 'Respondedor',
        UserRole.resident => 'Residente',
        UserRole.unknown => 'Rol no identificado',
      };

  String get description => switch (this) {
        UserRole.administrator =>
          'Gestión completa: usuarios, dispositivos, configuración y emergencias.',
        UserRole.operator =>
          'Operación de sensores, riesgos, protocolos, respuestas y notificaciones.',
        UserRole.responder =>
          'Consulta operativa y registro de respuestas y acciones de emergencia.',
        UserRole.resident => 'Consulta de sus propias notificaciones.',
        UserRole.unknown => 'Sin permisos asignados.',
      };

  /// Valor exacto del backend.
  String get apiValue => switch (this) {
        UserRole.administrator => 'Administrator',
        UserRole.operator => 'Operator',
        UserRole.responder => 'Responder',
        UserRole.resident => 'Resident',
        UserRole.unknown => 'Unknown',
      };

  static UserRole fromApi(Object? raw) {
    final v = raw?.toString().toLowerCase().trim();
    for (final r in UserRole.values) {
      if (r.apiValue.toLowerCase() == v) return r;
    }
    return switch (v) {
      'admin' => UserRole.administrator,
      _ => UserRole.unknown,
    };
  }

  static const assignable = [
    UserRole.administrator,
    UserRole.operator,
    UserRole.responder,
    UserRole.resident,
  ];
}

/// Operaciones sujetas a autorización. Reflejan la matriz del backend; el
/// backend valida cada llamada y su 403 es la fuente de verdad.
enum Permission {
  viewOperations, // dispositivos, lecturas, riesgos, emergencias
  manageDevices,
  postReadings, // pruebas de detección
  manageRisks, // crear, reconocer, resolver
  deleteRisks,
  manageProtocols,
  deleteProtocols,
  createResponses,
  updateResponses,
  manageActions,
  viewAllNotifications,
  sendNotifications,
  viewOwnNotifications,
  manageUsers,
  viewConfiguration,
  editConfiguration,
  deleteRecords,
}

class RolePermissions {
  const RolePermissions._();

  static const Map<UserRole, Set<Permission>> _matrix = {
    UserRole.administrator: {...Permission.values},
    UserRole.operator: {
      Permission.viewOperations,
      Permission.postReadings,
      Permission.manageRisks,
      Permission.manageProtocols,
      Permission.createResponses,
      Permission.updateResponses,
      Permission.manageActions,
      Permission.viewAllNotifications,
      Permission.sendNotifications,
      Permission.viewConfiguration,
    },
    UserRole.responder: {
      Permission.viewOperations,
      Permission.createResponses,
      Permission.manageActions,
      Permission.viewAllNotifications,
      Permission.sendNotifications,
    },
    UserRole.resident: {Permission.viewOwnNotifications},
    UserRole.unknown: {},
  };

  /// Unión de permisos de todos los roles del usuario.
  static Set<Permission> forRoles(Iterable<UserRole> roles) =>
      {for (final r in roles) ...?_matrix[r]};

  static bool can(Iterable<UserRole> roles, Permission p) =>
      forRoles(roles).contains(p);

  /// Rol principal para mostrar (el de mayor privilegio).
  static UserRole primary(Iterable<UserRole> roles) {
    for (final r in UserRole.values) {
      if (roles.contains(r)) return r;
    }
    return UserRole.unknown;
  }
}
