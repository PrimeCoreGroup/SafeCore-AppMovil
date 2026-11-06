import '../../../../core/storage/cached_fetch.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/utils/data_result.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_data_source.dart';
import '../models/notification_mapper.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._ds, this._cache,
      {required this.staleAfter, this.isDemo = false});

  final NotificationsDataSource _ds;
  final LocalCache _cache;
  final Duration staleAfter;
  final bool isDemo;

  Future<DataResult<List<AppNotification>>> _get(
    String key,
    Future<List<AppNotification>> Function() remote,
  ) =>
      fetchWithCache(
        cache: _cache,
        key: key,
        remote: () async => (await remote())
          ..sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0))),
        toJson: NotificationMapper.listToJson,
        fromJson: NotificationMapper.listFromJson,
        staleAfter: staleAfter,
        remoteKind: isDemo ? DataSourceKind.demo : DataSourceKind.remote,
      );

  @override
  Future<DataResult<List<AppNotification>>> getAll() =>
      _get(CacheKeys.notifications, _ds.fetchAll);

  @override
  Future<DataResult<List<AppNotification>>> getMine() =>
      _get(CacheKeys.myNotifications, _ds.fetchMine);

  @override
  Future<AppNotification> create(NotificationDraft d) => _ds.create(d);

  @override
  Future<void> update(String id, NotificationDraft d) => _ds.update(id, d);

  @override
  Future<Set<String>> readIds() async {
    final v = (await _cache.read(CacheKeys.readNotifications))?.value;
    return v is List ? v.map((e) => e.toString()).toSet() : <String>{};
  }

  @override
  Future<void> markRead(Iterable<String> ids) async {
    final current = await readIds()
      ..addAll(ids);
    final list = current.toList();
    await _cache.write(
      CacheKeys.readNotifications,
      list.length > 500 ? list.sublist(list.length - 500) : list,
    );
  }

  @override
  Future<NotificationPreferences> loadPreferences() async {
    final v = (await _cache.read(CacheKeys.notificationPrefs))?.value;
    return v == null
        ? const NotificationPreferences()
        : NotificationPreferences.fromJson(asJson(v));
  }

  @override
  Future<void> savePreferences(NotificationPreferences prefs) =>
      _cache.write(CacheKeys.notificationPrefs, prefs.toJson());
}
