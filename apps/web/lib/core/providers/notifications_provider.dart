import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../features/notifications/repositories/notifications_repository.dart';
import '../storage/token_storage.dart';

const String kNotificationsUrl = 'http://localhost:3008';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<AppNotification>>>((ref) {
  return NotificationsNotifier(
    ref.watch(notificationsRepositoryProvider),
    ref.read(tokenStorageProvider),
  );
});

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).whenOrNull(
        data: (list) => list.where((n) => !n.isRead).length,
      ) ??
      0;
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier(this._repo, this._storage)
      : super(const AsyncLoading()) {
    _init();
  }

  final NotificationsRepository _repo;
  final TokenStorage _storage;
  io.Socket? _socket;

  Future<void> _init() async {
    await _load();
    _connectSocket();
  }

  Future<void> _load() async {
    try {
      final list = await _repo.getNotifications();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _connectSocket() async {
    final token = await _storage.getAccessToken();

    _socket = io.io(
      kNotificationsUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setNamespace('/notifications')
          .setQuery({'token': token ?? ''})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {})
      ..on('notification:new', (data) {
        if (data is Map<String, dynamic>) {
          try {
            final notif = AppNotification.fromJson(data);
            state = state.whenData((list) => [notif, ...list]);
          } catch (_) {}
        }
      })
      ..connect();
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    state = state.whenData((list) => list
        .map((n) => n.id == id
            ? AppNotification(
                id: n.id,
                type: n.type,
                content: n.content,
                isRead: true,
                createdAt: n.createdAt,
              )
            : n)
        .toList());
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    state = state.whenData((list) => list
        .map((n) => AppNotification(
              id: n.id,
              type: n.type,
              content: n.content,
              isRead: true,
              createdAt: n.createdAt,
            ))
        .toList());
  }

  @override
  void dispose() {
    _socket?.dispose();
    super.dispose();
  }
}
