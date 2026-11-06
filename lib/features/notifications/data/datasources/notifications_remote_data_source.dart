import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/pagination.dart';
import '../../../../core/utils/json_utils.dart';
import '../../domain/entities/app_notification.dart';
import '../models/notification_mapper.dart';
import 'notifications_data_source.dart';

class NotificationsRemoteDataSource implements NotificationsDataSource {
  NotificationsRemoteDataSource(this._api);
  final ApiClient _api;

  Future<List<AppNotification>> _paged(String path) => fetchAllPages(
        (page, size) async => NotificationMapper.listFromJson(
          await _api.get(path, query: {'page': page, 'pageSize': size}),
        ),
        maxPages: 8,
      );

  @override
  Future<List<AppNotification>> fetchAll() =>
      _paged(ApiEndpoints.notifications);

  @override
  Future<List<AppNotification>> fetchMine() =>
      _paged(ApiEndpoints.myNotifications);

  @override
  Future<AppNotification> create(NotificationDraft d) async =>
      NotificationMapper.fromJson(
        asJson(
          await _api.post(
            ApiEndpoints.notifications,
            body: NotificationMapper.draftToJson(d),
          ),
        ),
      );

  @override
  Future<void> update(String id, NotificationDraft d) => _api.put(
        ApiEndpoints.notification(id),
        body: NotificationMapper.draftToJson(d),
      );
}
