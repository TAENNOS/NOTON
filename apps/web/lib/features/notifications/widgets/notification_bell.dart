import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notifications_provider.dart';
import '../repositories/notifications_repository.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _showPanel(context, ref),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).colorScheme.onError,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _NotificationsPanel(),
      ),
    );
  }
}

class _NotificationsPanel extends ConsumerWidget {
  const _NotificationsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Text(
                  '알림',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      ref.read(notificationsProvider.notifier).markAllAsRead(),
                  child: const Text('모두 읽음'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: notifAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (notifications) => notifications.isEmpty
                  ? const Center(child: Text('알림이 없습니다'))
                  : ListView.separated(
                      controller: scrollCtrl,
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (context, i) =>
                          _NotificationTile(notification: notifications[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      tileColor: notification.isRead
          ? null
          : scheme.primaryContainer.withOpacity(0.2),
      leading: Icon(
        _iconForType(notification.type),
        color: notification.isRead ? scheme.onSurfaceVariant : scheme.primary,
      ),
      title: Text(notification.content),
      subtitle: Text(
        _formatTime(notification.createdAt),
        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
      ),
      onTap: notification.isRead
          ? null
          : () => ref
              .read(notificationsProvider.notifier)
              .markAsRead(notification.id),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outlined;
      case 'mention':
        return Icons.alternate_email;
      case 'doc':
        return Icons.article_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    return '${dt.month}/${dt.day}';
  }
}
