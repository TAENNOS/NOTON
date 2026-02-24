import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/workspace_provider.dart';
import '../../features/workspace/repositories/workspace_repository.dart';
import '../notifications/widgets/notification_bell.dart';

const double kSidebarWidth = 280;

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOTON'),
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBell(),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () async {
              await ref.read(authStatusProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          SizedBox(
            width: kSidebarWidth,
            child: _Sidebar(onDocTap: (id) => context.go('/docs/$id')),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.onDocTap});
  final ValueChanged<String> onDocTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(workspacesProvider);
    final selected = ref.watch(selectedWorkspaceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '워크스페이스',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.outline,
                  letterSpacing: 1,
                ),
          ),
        ),
        Expanded(
          child: workspacesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('오류: $e')),
            data: (workspaces) => workspaces.isEmpty
                ? _EmptyState(
                    onCreateTap: () => _showCreateWorkspace(context, ref))
                : ListView(
                    children: [
                      for (final ws in workspaces)
                        ExpansionTile(
                          leading:
                              const Icon(Icons.folder_outlined, size: 18),
                          title: Text(ws.name,
                              style: const TextStyle(fontSize: 14)),
                          initiallyExpanded: selected?.id == ws.id,
                          onExpansionChanged: (exp) {
                            if (exp) {
                              ref
                                  .read(selectedWorkspaceProvider.notifier)
                                  .state = ws;
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () =>
                                _showCreateDoc(context, ref, ws.id),
                            tooltip: '문서 만들기',
                          ),
                          children: [
                            _DocList(
                                workspaceId: ws.id, onDocTap: onDocTap),
                          ],
                        ),
                    ],
                  ),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          dense: true,
          leading: const Icon(Icons.add, size: 18),
          title: const Text('워크스페이스 추가'),
          onTap: () => _showCreateWorkspace(context, ref),
        ),
      ],
    );
  }

  Future<void> _showCreateWorkspace(
      BuildContext context, WidgetRef ref) async {
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
                autofocus: true),
            const SizedBox(height: 8),
            TextField(
                controller: slugCtrl,
                decoration:
                    const InputDecoration(labelText: 'slug (예: my-team)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          FilledButton(
            onPressed: () async {
              await ref.read(workspaceRepositoryProvider).createWorkspace(
                    nameCtrl.text.trim(), slugCtrl.text.trim());
              ref.invalidate(workspacesProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateDoc(
      BuildContext context, WidgetRef ref, String workspaceId) async {
    final titleCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('문서 만들기'),
        content: TextField(
          controller: titleCtrl,
          decoration: const InputDecoration(labelText: '제목'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
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

class _DocList extends ConsumerWidget {
  const _DocList({required this.workspaceId, required this.onDocTap});
  final String workspaceId;
  final ValueChanged<String> onDocTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentsProvider(workspaceId));
    return docsAsync.when(
      loading: () =>
          const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text('오류: $e', style: const TextStyle(fontSize: 12)),
      ),
      data: (docs) => docs.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('문서 없음', style: TextStyle(fontSize: 12)),
            )
          : Column(
              children: docs
                  .map((doc) => ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 24),
                        leading: const Icon(Icons.article_outlined, size: 16),
                        title: Text(doc.title,
                            style: const TextStyle(fontSize: 13)),
                        onTap: () => onDocTap(doc.id),
                      ))
                  .toList(),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspaces_outlined, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          const Text('워크스페이스 없음', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('만들기'),
          ),
        ],
      ),
    );
  }
}
