/// Estado de conectividad en tres dimensiones independientes.
///
/// SafeCore distingue:
/// * la red del teléfono (`deviceOnline`),
/// * la comunicación teléfono ↔ nube (`cloudReachable`),
/// * la operación del nodo Edge, que se informa en los datos de dispositivos.
///
/// Que el teléfono pierda conexión NO significa que el nodo Edge haya dejado
/// de proteger el inmueble.
class ConnectivityStatus {
  const ConnectivityStatus({
    required this.deviceOnline,
    required this.cloudReachable,
    this.lastCloudContact,
  });

  const ConnectivityStatus.initial()
      : deviceOnline = true,
        cloudReachable = true,
        lastCloudContact = null;

  final bool deviceOnline;
  final bool cloudReachable;
  final DateTime? lastCloudContact;

  /// Se pueden ejecutar operaciones remotas (ack, simulacros, umbrales...).
  bool get canReachCloud => deviceOnline && cloudReachable;

  bool get isOffline => !canReachCloud;

  ConnectivityStatus copyWith({
    bool? deviceOnline,
    bool? cloudReachable,
    DateTime? lastCloudContact,
  }) =>
      ConnectivityStatus(
        deviceOnline: deviceOnline ?? this.deviceOnline,
        cloudReachable: cloudReachable ?? this.cloudReachable,
        lastCloudContact: lastCloudContact ?? this.lastCloudContact,
      );

  @override
  bool operator ==(Object other) =>
      other is ConnectivityStatus &&
      other.deviceOnline == deviceOnline &&
      other.cloudReachable == cloudReachable &&
      other.lastCloudContact == lastCloudContact;

  @override
  int get hashCode =>
      Object.hash(deviceOnline, cloudReachable, lastCloudContact);
}

/// Mensaje obligatorio cuando el sistema opera sin nube.
const kLocalOperationMessage =
    'El sistema opera localmente. Las funciones de protección continúan activas.';
