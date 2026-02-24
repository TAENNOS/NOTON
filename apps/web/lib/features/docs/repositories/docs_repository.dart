import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final docsRepositoryProvider = Provider<DocsRepository>(
  (ref) => DocsRepository(ref.watch(dioProvider)),
);

class DocumentDetail {
  const DocumentDetail({
    required this.id,
    required this.title,
    required this.workspaceId,
    this.content,
  });
  final String id;
  final String title;
  final String workspaceId;
  final String? content;

  factory DocumentDetail.fromJson(Map<String, dynamic> j) => DocumentDetail(
        id: j['id'] as String,
        title: j['title'] as String,
        workspaceId: j['workspaceId'] as String,
        content: j['content'] as String?,
      );
}

class DocsRepository {
  DocsRepository(this._dio);
  final Dio _dio;

  Future<DocumentDetail> getDocument(String id) async {
    final res = await _dio.get('/docs/documents/$id');
    return DocumentDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> updateDocument(String id, String title, String content) async {
    await _dio.patch('/docs/documents/$id', data: {
      'title': title,
      'content': content,
    });
  }
}
