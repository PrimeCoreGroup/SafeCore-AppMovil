import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/status_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/visuals.dart';
import '../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

IconData channelIcon(NotificationChannel c) => switch (c) {
      NotificationChannel.push => Icons.notifications_rounded,
      NotificationChannel.email => Icons.email_rounded,
      NotificationChannel.sms => Icons.sms_rounded,
    };

class NotificationTile extends ConsumerWidget {
  const NotificationTile(
      {super.key,
      required this.notification,
      this.trailing,
      this.recipientLabel});

  final AppNotification notification;
  final Widget? trailing;
  final String? recipientLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final read = ref
            .watch(readNotificationsProvider)
            .valueOrNull
            ?.contains(notification.id) ??
        false;
    final tone = notification.looksUrgent
        ? context.status.critical
        : context.status.info;
    final n = notification;
    return Material(
      color: read ? Theme.of(context).colorScheme.surface : tone.background,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          ref.read(readNotificationsProvider.notifier).markRead([n.id]);
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            isScrollControlled: true,
            builder: (_) => _NotificationDetail(
                notification: n, recipientLabel: recipientLabel),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
                left: BorderSide(color: tone.foreground, width: read ? 2 : 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: channelIcon(n.channel), tone: tone, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                                fontWeight:
                                    read ? FontWeight.w600 : FontWeight.w800),
                          ),
                        ),
                        if (!read)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                                color: tone.foreground, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          n.createdAt == null
                              ? n.channel.label
                              : '${DateFormatter.shortDateTime(n.createdAt!)} · ${n.channel.label}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (recipientLabel != null)
                          Text('→ $recipientLabel',
                              style: Theme.of(context).textTheme.bodySmall),
                        StatusChip(
                          label: n.status.label,
                          tone: switch (n.status) {
                            DeliveryStatus.delivered => context.status.normal,
                            DeliveryStatus.pending => context.status.offline,
                            DeliveryStatus.failed => context.status.critical,
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetail extends StatelessWidget {
  const _NotificationDetail({required this.notification, this.recipientLabel});
  final AppNotification notification;
  final String? recipientLabel;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              [
                if (n.createdAt != null) DateFormatter.dateTime(n.createdAt!),
                'Canal: ${n.channel.label}',
                'Estado: ${n.status.label}',
                if (recipientLabel != null) 'Para: $recipientLabel',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            SelectableText(n.body,
                style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
