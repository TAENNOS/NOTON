import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../repositories/chat_repository.dart';
import '../../../core/storage/token_storage.dart';
import '../../../theme.dart';

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
  const ChatScreen({super.key, required this.channelId, this.channelName});
  final String channelId;
  final String? channelName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  io.Socket? _socket;
  bool _sending = false;
  bool _connected = false;

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
        if (mounted) setState(() => _connected = true);
      })
      ..onDisconnect((_) {
        if (mounted) setState(() => _connected = false);
      })
      ..on('message:new', (data) {
        if (data is Map<String, dynamic>) {
          final msg = Message.fromJson(data);
          ref.read(_messagesProvider(widget.channelId).notifier).addIncoming(msg);
        }
      })
      ..connect();
  }

  @override
  void dispose() {
    _socket?.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _inputCtrl.clear();
    try {
      await ref.read(_messagesProvider(widget.channelId).notifier).sendMessage(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('전송 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _inputFocus.requestFocus();
  }

  String get _displayName {
    if (widget.channelName != null) return widget.channelName!;
    return widget.channelId.length > 8
        ? widget.channelId.substring(0, 8)
        : widget.channelId;
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(_messagesProvider(widget.channelId));

    return Scaffold(
      backgroundColor: NotonColors.bg,
      body: Column(
        children: [
          // Channel header
          _ChannelHeader(name: _displayName, connected: _connected),
          const Divider(height: 1),
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('오류: $e',
                    style: const TextStyle(color: NotonColors.textSecondary)),
              ),
              data: (messages) => messages.isEmpty
                  ? _EmptyChannelView(channelName: _displayName)
                  : _MessageList(
                      messages: messages,
                      scrollController: _scrollCtrl,
                    ),
            ),
          ),
          // Input
          _ChatInputBar(
            controller: _inputCtrl,
            focusNode: _inputFocus,
            sending: _sending,
            channelName: _displayName,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ─── Channel Header ───────────────────────────────────────────────────────────

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({required this.name, required this.connected});
  final String name;
  final bool connected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: NotonColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.tag, size: 16, color: NotonColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: NotonColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          if (!connected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: NotonColors.bgSecondary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '오프라인',
                style: TextStyle(fontSize: 11, color: NotonColors.textTertiary),
              ),
            ),
          const Spacer(),
          // Placeholder toolbar icons
          _HeaderAction(icon: Icons.search, tooltip: '검색'),
          _HeaderAction(icon: Icons.group_outlined, tooltip: '멤버'),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatefulWidget {
  const _HeaderAction({required this.icon, required this.tooltip});
  final IconData icon;
  final String tooltip;

  @override
  State<_HeaderAction> createState() => _HeaderActionState();
}

class _HeaderActionState extends State<_HeaderAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(left: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hover ? NotonColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(widget.icon, size: 18, color: NotonColors.textSecondary),
        ),
      ),
    );
  }
}

// ─── Message List ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.scrollController,
  });
  final List<Message> messages;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final prev = i < messages.length - 1 ? messages[i + 1] : null;
        // Group consecutive messages from same author within 5 minutes
        final grouped = prev != null &&
            prev.authorId == msg.authorId &&
            msg.createdAt.difference(prev.createdAt).inMinutes.abs() < 5;
        return _MessageRow(message: msg, grouped: grouped);
      },
    );
  }
}

class _MessageRow extends StatefulWidget {
  const _MessageRow({required this.message, required this.grouped});
  final Message message;
  final bool grouped;

  @override
  State<_MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends State<_MessageRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final author = widget.message.authorName ?? widget.message.authorId;
    final initial = author[0].toUpperCase();

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        color: _hover ? NotonColors.bgSecondary : Colors.transparent,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: widget.grouped ? 2 : 12,
          bottom: 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: widget.grouped
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: _hover
                          ? Text(
                              _shortTime(widget.message.createdAt),
                              style: const TextStyle(
                                  fontSize: 10, color: NotonColors.textTertiary),
                            )
                          : const SizedBox.shrink(),
                    )
                  : _Avatar(initial: initial, authorId: widget.message.authorId),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!widget.grouped)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          author,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: NotonColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(widget.message.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: NotonColors.textTertiary),
                        ),
                      ],
                    ),
                  if (!widget.grouped) const SizedBox(height: 2),
                  Text(
                    widget.message.content,
                    style: const TextStyle(
                      fontSize: 14,
                      color: NotonColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (now.day == dt.day && now.month == dt.month && now.year == dt.year) {
      return '오늘 $h:$m';
    }
    return '${dt.month}/${dt.day} $h:$m';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.authorId});
  final String initial;
  final String authorId;

  Color _colorFromId(String id) {
    const colors = [
      Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFFEF5350),
      Color(0xFFAB47BC), Color(0xFF42A5F5), Color(0xFFFF7043),
    ];
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _colorFromId(authorId),
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyChannelView extends StatelessWidget {
  const _EmptyChannelView({required this.channelName});
  final String channelName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NotonColors.bgSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.tag, size: 28, color: NotonColors.textTertiary),
          ),
          const SizedBox(height: 12),
          Text(
            '#$channelName의 시작입니다',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: NotonColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '첫 번째 메시지를 보내보세요',
            style: TextStyle(fontSize: 14, color: NotonColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.channelName,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final String channelName;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: NotonColors.bg,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: NotonColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: _InputAction(
                icon: Icons.add_circle_outline,
                tooltip: '첨부',
                onTap: () {},
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: '#$channelName에 메시지 보내기',
                  hintStyle: const TextStyle(
                      fontSize: 14, color: NotonColors.textTertiary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                ),
                maxLines: 6,
                minLines: 1,
                style: const TextStyle(
                    fontSize: 14, color: NotonColors.textPrimary),
                textInputAction: TextInputAction.newline,
                onSubmitted: (_) => onSend(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: NotonColors.primary),
                    )
                  : _SendButton(onTap: onSend),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputAction extends StatefulWidget {
  const _InputAction(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_InputAction> createState() => _InputActionState();
}

class _InputActionState extends State<_InputAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Icon(
            widget.icon,
            size: 20,
            color: _hover ? NotonColors.textSecondary : NotonColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '전송',
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _hover ? NotonColors.primary : NotonColors.bgSecondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.send_rounded,
              size: 16,
              color: _hover ? Colors.white : NotonColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
