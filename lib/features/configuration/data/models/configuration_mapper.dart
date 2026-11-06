import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/system_configuration.dart';

class ConfigurationMapper {
  const ConfigurationMapper._();

  static SystemConfiguration fromJson(Json j) => SystemConfiguration(
        id: readString(j, 'id'),
        version: readInt(j, 'version') ?? 1,
        syncStatus:
            enumFromApi(SyncStatus.values, j['syncStatus'], SyncStatus.pending),
        lastSyncedAt: DateFormatter.tryParse(j['lastSyncedAt']),
      );

  static Json toJson(SystemConfiguration c) => {
        'id': c.id,
        'version': c.version,
        'syncStatus': c.syncStatus.apiValue,
        'lastSyncedAt': c.lastSyncedAt?.toUtc().toIso8601String(),
      };

  static Json draftToJson(ConfigurationDraft d) => {
        'version': d.version,
        'syncStatus': d.syncStatus.apiValue,
        'lastSyncedAt': d.lastSyncedAt?.toUtc().toIso8601String(),
      };

  static List<SystemConfiguration> listFromJson(Object? raw) =>
      asJsonList(raw).map(fromJson).toList();
  static List<Json> listToJson(List<SystemConfiguration> l) =>
      l.map(toJson).toList();
}
