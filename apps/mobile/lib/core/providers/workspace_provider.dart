import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/workspace/repositories/workspace_repository.dart';

final workspacesProvider =
    FutureProvider<List<Workspace>>((ref) async {
  return ref.watch(workspaceRepositoryProvider).getWorkspaces();
});

final selectedWorkspaceProvider = StateProvider<Workspace?>((ref) => null);

final documentsProvider =
    FutureProvider.family<List<Document>, String>((ref, workspaceId) async {
  return ref.watch(workspaceRepositoryProvider).getDocuments(workspaceId);
});
