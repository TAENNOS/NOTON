import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(dioProvider)),
);

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });
  final String id;
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: j['type'] as String,
        content: j['content'] as String,
        isRead: j['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class NotificationsRepository {
  NotificationsRepository(this._dio);
  final Dio _dio;

  Future<List<AppNotification>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return (res.data as List)
        .map((j) => AppNotification.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.post('/notifications/read-all');
  }
}
