import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/storage/token_storage.dart';
import '../repositories/docs_repository.dart';

const String kRealtimeHost = 'localhost:3003';

class DocEditorScreen extends ConsumerStatefulWidget {
  const DocEditorScreen({super.key, required this.docId});
  final String docId;

  @override
  ConsumerState<DocEditorScreen> createState() => _DocEditorScreenState();
}

class _DocEditorScreenState extends ConsumerState<DocEditorScreen> {
  final _controller = TextEditingController();
  WebSocketChannel? _channel;
  bool _loading = true;
  bool _connected = false;
  String? _title;
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
      _title = doc.title;
      _controller.text = doc.content ?? '';
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
          // Yjs update handling — in production use y_dart library
          // Here we handle plain text sync as a simplified fallback
          if (message is String) {
            try {
              final data = jsonDecode(message) as Map<String, dynamic>;
              if (data['type'] == 'sync' && data['content'] != null) {
                final incoming = data['content'] as String;
                if (incoming != _controller.text) {
                  final cursor = _controller.selection;
                  _controller.text = incoming;
                  _controller.selection = cursor;
                }
              }
            } catch (_) {}
          }
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
        onError: (_) {
          if (mounted) setState(() => _connected = false);
        },
      );
      if (mounted) setState(() => _connected = true);
    } catch (e) {
      // WebSocket unavailable — work offline
      if (mounted) setState(() => _connected = false);
    }
  }

  void _onTextChanged() {
    // Debounce: send update after 500ms of inactivity
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _sendUpdate(_controller.text);
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
    try {
      await ref.read(docsRepositoryProvider).updateDocument(
            widget.docId,
            _title ?? 'Untitled',
            _controller.text,
          );
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _channel?.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_title ?? 'Untitled'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  _connected ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                  size: 18,
                  color: _connected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  _connected ? '연결됨' : '오프라인',
                  style: TextStyle(
                    fontSize: 12,
                    color: _connected ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          onChanged: (_) => _onTextChanged(),
          maxLines: null,
          expands: true,
          decoration: const InputDecoration(
            hintText: '여기에 내용을 입력하세요...',
            border: InputBorder.none,
          ),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlignVertical: TextAlignVertical.top,
        ),
      ),
    );
  }
}
