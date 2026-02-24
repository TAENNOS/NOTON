import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/storage/token_storage.dart';
import '../../../theme.dart';
import '../repositories/docs_repository.dart';

const String kRealtimeHost = 'localhost:3003';

class DocEditorScreen extends ConsumerStatefulWidget {
  const DocEditorScreen({super.key, required this.docId});
  final String docId;

  @override
  ConsumerState<DocEditorScreen> createState() => _DocEditorScreenState();
}

class _DocEditorScreenState extends ConsumerState<DocEditorScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _bodyFocus = FocusNode();
  WebSocketChannel? _channel;
  bool _loading = true;
  bool _connected = false;
  bool _saving = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    _loadDoc();
  }

  Future<void> _loadDoc() async {
    try {
      final repo = ref.read(docsRepositoryProvider);
      final doc = await repo.getDocument(widget.docId);
      _titleCtrl.text = doc.title;
      _bodyCtrl.text = doc.content ?? '';
      await _connectWebSocket();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('문서 로드 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _connectWebSocket() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.getAccessToken();
    final uri = Uri(
      scheme: 'ws',
      host: kRealtimeHost.split(':').first,
      port: int.tryParse(kRealtimeHost.split(':').last) ?? 3003,
      path: '/yjs',
      queryParameters: {
        'documentId': widget.docId,
        if (token != null) 'token': token,
      },
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (message) {
          if (message is String) {
            try {
              final data = jsonDecode(message) as Map<String, dynamic>;
              if (data['type'] == 'sync' && data['content'] != null) {
                final incoming = data['content'] as String;
                if (incoming != _bodyCtrl.text) {
                  final cursor = _bodyCtrl.selection;
                  _bodyCtrl.text = incoming;
                  _bodyCtrl.selection = cursor;
                }
              }
            } catch (_) {}
          }
        },
        onDone: () { if (mounted) setState(() => _connected = false); },
        onError: (_) { if (mounted) setState(() => _connected = false); },
      );
      if (mounted) setState(() => _connected = true);
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  void _onChanged() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 600), () {
      _sendUpdate(_bodyCtrl.text);
      _autoSave();
    });
  }

  void _sendUpdate(String content) {
    if (_channel == null || !_connected) return;
    _channel!.sink.add(jsonEncode({
      'type': 'update',
      'documentId': widget.docId,
      'content': content,
    }));
  }

  Future<void> _autoSave() async {
    if (_saving) return;
    if (mounted) setState(() => _saving = true);
    try {
      final title = _titleCtrl.text.trim().isEmpty ? 'Untitled' : _titleCtrl.text.trim();
      await ref.read(docsRepositoryProvider).updateDocument(
            widget.docId, title, _bodyCtrl.text);
    } catch (_) {}
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _channel?.sink.close();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: NotonColors.bg,
      body: Column(
        children: [
          _EditorTopBar(connected: _connected, saving: _saving),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(120, 48, 120, 80),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Editable title
                    TextField(
                      controller: _titleCtrl,
                      onChanged: (_) => _onChanged(),
                      onSubmitted: (_) => _bodyFocus.requestFocus(),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: NotonColors.textPrimary,
                        height: 1.25,
                      ),
                      decoration: const InputDecoration(
                        hintText: '제목 없음',
                        hintStyle: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: NotonColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Body editor
                    TextField(
                      controller: _bodyCtrl,
                      focusNode: _bodyFocus,
                      onChanged: (_) => _onChanged(),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        fontSize: 15,
                        color: NotonColors.textPrimary,
                        height: 1.75,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Enter를 눌러 내용을 입력하세요...",
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: NotonColors.textTertiary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorTopBar extends StatelessWidget {
  const _EditorTopBar({required this.connected, required this.saving});
  final bool connected;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: NotonColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TopBarButton(
            icon: Icons.chevron_left,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Text(
            '문서',
            style: const TextStyle(
              fontSize: 13,
              color: NotonColors.textSecondary,
            ),
          ),
          const Spacer(),
          _SyncStatus(connected: connected, saving: saving),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatefulWidget {
  const _TopBarButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_TopBarButton> createState() => _TopBarButtonState();
}

class _TopBarButtonState extends State<_TopBarButton> {
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

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.connected, required this.saving});
  final bool connected;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String label;
    final Color color;

    if (saving) {
      icon = Icons.cloud_upload_outlined;
      label = '저장 중...';
      color = NotonColors.textTertiary;
    } else if (connected) {
      icon = Icons.cloud_done_outlined;
      label = '저장됨';
      color = NotonColors.success;
    } else {
      icon = Icons.cloud_off_outlined;
      label = '오프라인';
      color = NotonColors.textTertiary;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
