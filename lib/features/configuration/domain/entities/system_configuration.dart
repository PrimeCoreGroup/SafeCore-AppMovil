enum SyncStatus {
  pending,
  synced,
  failed;

  String get label => switch (this) {
        SyncStatus.pending => 'Pendiente de sincronizar',
        SyncStatus.synced => 'Sincronizada',
        SyncStatus.failed => 'Sincronización fallida',
      };

  String get apiValue => switch (this) {
        SyncStatus.pending => 'Pending',
        SyncStatus.synced => 'Synced',
        SyncStatus.failed => 'Failed',
      };
}

/// Versión de configuración de monitoreo (`/api/SystemConfigurations`).
class SystemConfiguration {
  const SystemConfiguration({
    required this.id,
    required this.version,
    required this.syncStatus,
    this.lastSyncedAt,
  });

  final String id;
  final int version;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
}

class ConfigurationDraft {
  const ConfigurationDraft({
    required this.version,
    required this.syncStatus,
    this.lastSyncedAt,
  });

  final int version;
  final SyncStatus syncStatus;
  final DateTime? lastSyncedAt;
}
