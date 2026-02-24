import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(dioProvider)),
);

class Channel {
  const Channel({required this.id, required this.name, required this.workspaceId});
  final String id;
  final String name;
  final String workspaceId;

  factory Channel.fromJson(Map<String, dynamic> j) => Channel(
        id: j['id'] as String,
        name: j['name'] as String,
        workspaceId: j['workspaceId'] as String,
      );
}

class Message {
  const Message({
    required this.id,
    required this.content,
    required this.authorId,
    required this.createdAt,
    this.authorName,
  });
  final String id;
  final String content;
  final String authorId;
  final DateTime createdAt;
  final String? authorName;

  factory Message.fromJson(Map<String, dynamic> j) => Message(
        id: j['id'] as String,
        content: j['content'] as String,
        authorId: j['authorId'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        authorName: j['author']?['name'] as String?,
      );
}

class ChatRepository {
  ChatRepository(this._dio);
  final Dio _dio;

  Future<List<Channel>> getChannels(String workspaceId) async {
    final res = await _dio.get('/chat/channels?workspaceId=$workspaceId');
    return (res.data as List)
        .map((j) => Channel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Channel> createChannel(String workspaceId, String name) async {
    final res = await _dio.post('/chat/channels', data: {
      'workspaceId': workspaceId,
      'name': name,
    });
    return Channel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Message>> getMessages(String channelId, {String? cursor}) async {
    final res = await _dio.get(
      '/chat/channels/$channelId/messages',
      queryParameters: {if (cursor != null) 'cursor': cursor},
    );
    return (res.data as List)
        .map((j) => Message.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Message> sendMessage(String channelId, String content) async {
    final res = await _dio.post('/chat/channels/$channelId/messages', data: {
      'content': content,
    });
    return Message.fromJson(res.data as Map<String, dynamic>);
  }
}
