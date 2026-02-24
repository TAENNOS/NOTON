import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) => WorkspaceRepository(ref.watch(dioProvider)),
);

class Workspace {
  const Workspace({required this.id, required this.name, required this.slug});
  final String id;
  final String name;
  final String slug;

  factory Workspace.fromJson(Map<String, dynamic> j) => Workspace(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
      );
}

class Document {
  const Document({
    required this.id,
    required this.title,
    required this.workspaceId,
    this.parentId,
  });
  final String id;
  final String title;
  final String workspaceId;
  final String? parentId;

  factory Document.fromJson(Map<String, dynamic> j) => Document(
        id: j['id'] as String,
        title: j['title'] as String,
        workspaceId: j['workspaceId'] as String,
        parentId: j['parentId'] as String?,
      );
}

class WorkspaceRepository {
  WorkspaceRepository(this._dio);
  final Dio _dio;

  Future<List<Workspace>> getWorkspaces() async {
    final res = await _dio.get('/docs/workspaces');
    return (res.data as List)
        .map((j) => Workspace.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Workspace> createWorkspace(String name, String slug) async {
    final res = await _dio.post('/docs/workspaces', data: {'name': name, 'slug': slug});
    return Workspace.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Document>> getDocuments(String workspaceId) async {
    final res = await _dio.get('/docs/documents?workspaceId=$workspaceId');
    return (res.data as List)
        .map((j) => Document.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Document> createDocument(String workspaceId, String title) async {
    final res = await _dio.post('/docs/documents', data: {
      'workspaceId': workspaceId,
      'title': title,
    });
    return Document.fromJson(res.data as Map<String, dynamic>);
  }
}
