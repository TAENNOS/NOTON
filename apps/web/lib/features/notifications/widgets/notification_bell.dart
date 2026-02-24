import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../theme.dart';
import '../repositories/notifications_repository.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return _BellButton(
      unread: unread,
      onTap: () => _showPanel(context, ref),
    );
  }

  void _showPanel(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => ProviderScope(
        parent: ProviderScope.containerOf(context),
        child: const _NotificationDialog(),
      ),
    );
  }
}

class _BellButton extends StatefulWidget {
  const _BellButton({required this.unread, required this.onTap});
  final int unread;
  final VoidCallback onTap;

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '알림',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hover ? NotonColors.bgHover : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  widget.unread > 0
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                  size: 18,
                  color: widget.unread > 0
                      ? NotonColors.textPrimary
                      : NotonColors.textSecondary,
                ),
                if (widget.unread > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                          minWidth: 14, minHeight: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: const BoxDecoration(
                        color: NotonColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.unread > 99 ? '99+' : '${widget.unread}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Notification Panel (Dialog) ──────────────────────────────────────────────

class _NotificationDialog extends ConsumerWidget {
  const _NotificationDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 48, right: 16),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          shadowColor: Colors.black.withOpacity(0.15),
          child: Container(
            width: 360,
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: BoxDecoration(
              color: NotonColors.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NotonColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PanelHeader(
                  onMarkAll: () =>
                      ref.read(notificationsProvider.notifier).markAllAsRead(),
                  onClose: () => Navigator.of(context).pop(),
                ),
                const Divider(height: 1),
                const Expanded(child: _NotificationList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onMarkAll, required this.onClose});
  final VoidCallback onMarkAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          const Text(
            '알림',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: NotonColors.textPrimary,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: onMarkAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: NotonColors.textLink,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            child: const Text('모두 읽음'),
          ),
          const SizedBox(width: 4),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: _hover ? NotonColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.close, size: 16, color: NotonColors.textSecondary),
        ),
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  const _NotificationList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(notificationsProvider);

    return notifAsync.when(
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(strokeWidth: 2),
      )),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('오류: $e',
              style: const TextStyle(
                  fontSize: 13, color: NotonColors.textSecondary)),
        ),
      ),
      data: (notifications) => notifications.isEmpty
          ? const _EmptyNotifications()
          : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _NotificationItem(
                notification: notifications[i],
                onTap: notifications[i].isRead
                    ? null
                    : () => ref
                        .read(notificationsProvider.notifier)
                        .markAsRead(notifications[i].id),
              ),
            ),
    );
  }
}

class _NotificationItem extends StatefulWidget {
  const _NotificationItem({required this.notification, this.onTap});
  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final unread = !widget.notification.isRead;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          color: _hover
              ? NotonColors.bgSecondary
              : unread
                  ? const Color(0xFFF0F2FF)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: unread
                      ? NotonColors.primary.withOpacity(0.1)
                      : NotonColors.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _iconForType(widget.notification.type),
                  size: 16,
                  color: unread
                      ? NotonColors.primary
                      : NotonColors.textTertiary,
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.notification.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: NotonColors.textPrimary,
                        fontWeight:
                            unread ? FontWeight.w500 : FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTime(widget.notification.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: NotonColors.textTertiary),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (unread)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 8),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: NotonColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_outline;
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
    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${dt.month}/${dt.day}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 36, color: NotonColors.textTertiary),
          SizedBox(height: 8),
          Text(
            '알림이 없습니다',
            style: TextStyle(fontSize: 14, color: NotonColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
