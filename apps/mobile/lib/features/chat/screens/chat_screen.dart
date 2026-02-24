import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../repositories/chat_repository.dart';
import '../../../core/storage/token_storage.dart';

const String kNotificationsHost = 'http://localhost:3008';

final _messagesProvider = StateNotifierProvider.family<_MessagesNotifier,
    AsyncValue<List<Message>>, String>((ref, channelId) {
  return _MessagesNotifier(ref.watch(chatRepositoryProvider), channelId);
});

class _MessagesNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  _MessagesNotifier(this._repo, this._channelId) : super(const AsyncLoading()) {
    _load();
  }

  final ChatRepository _repo;
  final String _channelId;

  Future<void> _load() async {
    try {
      final msgs = await _repo.getMessages(_channelId);
      state = AsyncData(msgs.reversed.toList());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    final msg = await _repo.sendMessage(_channelId, content);
    state = state.whenData((list) => [msg, ...list]);
  }

  void addIncoming(Message msg) {
    state = state.whenData((list) {
      if (list.any((m) => m.id == msg.id)) return list;
      return [msg, ...list];
    });
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.channelId});
  final String channelId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  io.Socket? _socket;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.getAccessToken();

    _socket = io.io(
      '$kNotificationsHost/notifications',
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setQuery({'token': token ?? ''})
          .disableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _socket!.emit('join:channel', widget.channelId);
      })
      ..on('message:new', (data) {
        if (data is Map<String, dynamic>) {
          final msg = Message.fromJson(data);
          ref
              .read(_messagesProvider(widget.channelId).notifier)
              .addIncoming(msg);
        }
      })
      ..connect();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _inputCtrl.clear();
    try {
      await ref
          .read(_messagesProvider(widget.channelId).notifier)
          .sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(_messagesProvider(widget.channelId));

    return Scaffold(
      appBar: AppBar(title: Text('#${widget.channelId.substring(0, 8)}')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (messages) => messages.isEmpty
                  ? const Center(child: Text('메시지가 없습니다'))
                  : ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (context, i) =>
                          _MessageBubble(message: messages[i]),
                    ),
            ),
          ),
          _ChatInput(
            controller: _inputCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: Text(
              (message.authorName ?? message.authorId)[0].toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.authorName ?? message.authorId.substring(0, 8),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(message.content),
              ],
            ),
          ),
        ],
      ),
    );
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

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: '메시지 입력...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
