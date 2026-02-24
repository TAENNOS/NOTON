import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/workspace_provider.dart';
import '../../features/workspace/repositories/workspace_repository.dart';
import '../notifications/widgets/notification_bell.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(workspacesProvider);
    final selected = ref.watch(selectedWorkspaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selected?.name ?? 'NOTON'),
        actions: const [NotificationBell()],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NOTON',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '워크스페이스',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: workspacesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('오류: $e')),
                data: (workspaces) => workspaces.isEmpty
                    ? _EmptyWorkspaceList(onCreateTap: () =>
                        _showCreateWorkspaceDialog(context, ref))
                    : _WorkspaceTree(
                        workspaces: workspaces,
                        selected: selected,
                        onWorkspaceTap: (ws) {
                          ref
                              .read(selectedWorkspaceProvider.notifier)
                              .state = ws;
                        },
                        onDocTap: (docId) {
                          Navigator.pop(context);
                          context.go('/docs/$docId');
                        },
                        onChatTap: (channelId) {
                          Navigator.pop(context);
                          context.go('/chat/$channelId');
                        },
                        onCreateDoc: (wsId) =>
                            _showCreateDocDialog(context, ref, wsId),
                      ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () async {
                await ref.read(authStatusProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }

  Future<void> _showCreateWorkspaceDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('워크스페이스 만들기'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: slugCtrl,
              decoration: const InputDecoration(labelText: 'slug (예: my-team)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(workspaceRepositoryProvider)
                  .createWorkspace(nameCtrl.text.trim(), slugCtrl.text.trim());
              ref.invalidate(workspacesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDocDialog(
      BuildContext context, WidgetRef ref, String workspaceId) async {
    final titleCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('문서 만들기'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: '제목'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () async {
              await ref
                  .read(workspaceRepositoryProvider)
                  .createDocument(workspaceId, titleCtrl.text.trim());
              ref.invalidate(documentsProvider(workspaceId));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkspaceList extends StatelessWidget {
  const _EmptyWorkspaceList({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspaces_outlined, size: 48),
          const SizedBox(height: 8),
          const Text('워크스페이스가 없습니다'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: const Text('만들기'),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceTree extends ConsumerWidget {
  const _WorkspaceTree({
    required this.workspaces,
    required this.selected,
    required this.onWorkspaceTap,
    required this.onDocTap,
    required this.onChatTap,
    required this.onCreateDoc,
  });

  final List<Workspace> workspaces;
  final Workspace? selected;
  final ValueChanged<Workspace> onWorkspaceTap;
  final ValueChanged<String> onDocTap;
  final ValueChanged<String> onChatTap;
  final ValueChanged<String> onCreateDoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('워크스페이스',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  )),
        ),
        for (final ws in workspaces)
          ExpansionTile(
            leading: const Icon(Icons.folder_outlined),
            title: Text(ws.name),
            initiallyExpanded: selected?.id == ws.id,
            onExpansionChanged: (expanded) {
              if (expanded) onWorkspaceTap(ws);
            },
            children: [_DocumentSubTree(workspaceId: ws.id, onDocTap: onDocTap)],
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () => onCreateDoc(ws.id),
                  tooltip: '문서 만들기',
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DocumentSubTree extends ConsumerWidget {
  const _DocumentSubTree({required this.workspaceId, required this.onDocTap});
  final String workspaceId;
  final ValueChanged<String> onDocTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider(workspaceId));
    return docsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text('오류: $e', style: const TextStyle(fontSize: 12)),
      ),
      data: (docs) => docs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('문서가 없습니다', style: TextStyle(fontSize: 12)),
            )
          : Column(
              children: docs
                  .map((doc) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.article_outlined, size: 18),
                        title: Text(doc.title,
                            style: const TextStyle(fontSize: 14)),
                        onTap: () => onDocTap(doc.id),
                      ))
                  .toList(),
            ),
    );
  }
}
