import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../domain/entities/app_notification.dart';

class ReadNotificationsController extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() =>
      ref.watch(notificationsRepositoryProvider).readIds();

  Future<void> markRead(Iterable<String> ids) async {
    await ref.read(notificationsRepositoryProvider).markRead(ids);
    state = AsyncData({...?state.valueOrNull, ...ids});
  }
}

final readNotificationsProvider =
    AsyncNotifierProvider<ReadNotificationsController, Set<String>>(
  ReadNotificationsController.new,
);

class NotificationPrefsController
    extends AsyncNotifier<NotificationPreferences> {
  @override
  Future<NotificationPreferences> build() =>
      ref.watch(notificationsRepositoryProvider).loadPreferences();

  Future<void> save(NotificationPreferences p) async {
    await ref.read(notificationsRepositoryProvider).savePreferences(p);
    state = AsyncData(p);
  }
}

final notificationPrefsProvider =
    AsyncNotifierProvider<NotificationPrefsController, NotificationPreferences>(
  NotificationPrefsController.new,
);

/// Notificaciones dirigidas al usuario actual (las que cuentan como "suyas").
final myInboxProvider = Provider<List<AppNotification>?>((ref) {
  final me = ref.watch(currentUserProvider)?.id;
  final all = ref.watch(notificationsProvider).valueOrNull?.data;
  if (all == null || me == null) return null;
  return all.where((n) => n.recipientUserId == me).toList();
});

final unreadCountProvider = Provider<int>((ref) {
  final inbox = ref.watch(myInboxProvider);
  if (inbox == null) return 0;
  final read =
      ref.watch(readNotificationsProvider).valueOrNull ?? const <String>{};
  return inbox.where((n) => !read.contains(n.id)).length;
});
