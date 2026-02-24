import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/workspace_provider.dart';
import '../../features/workspace/repositories/workspace_repository.dart';
import '../notifications/widgets/notification_bell.dart';
import '../../theme.dart';

const double kSidebarWidth = 240;

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: NotonColors.bg,
      body: Row(
        children: [
          _Sidebar(onDocTap: (id) => context.go('/docs/$id'),
                   onChatTap: (id) => context.go('/chat/$id')),
          const VerticalDivider(width: 1, color: NotonColors.border),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Sidebar
// ──────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.onDocTap, required this.onChatTap});
  final ValueChanged<String> onDocTap;
  final ValueChanged<String> onChatTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(workspacesProvider);
    final selected = ref.watch(selectedWorkspaceProvider);

    return Container(
      width: kSidebarWidth,
      color: NotonColors.bgSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _SidebarHeader(
            workspaceName: selected?.name ?? 'NOTON',
            ref: ref,
          ),
          const Divider(height: 1, color: NotonColors.border),

          // ── Tree ──
          Expanded(
            child: workspacesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => _SidebarError(error: e),
              data: (workspaces) => workspaces.isEmpty
                  ? _EmptyState(
                      onCreateTap: () =>
                          _showCreateWorkspace(context, ref))
                  : _WorkspaceList(
                      workspaces: workspaces,
                      selected: selected,
                      onSelect: (ws) => ref
                          .read(selectedWorkspaceProvider.notifier)
                          .state = ws,
                      onDocTap: onDocTap,
                      onChatTap: onChatTap,
                      onCreateDoc: (wsId) =>
                          _showCreateDoc(context, ref, wsId),
                    ),
            ),
          ),

          const Divider(height: 1, color: NotonColors.border),
          // ── Footer ──
          _SidebarFooter(ref: ref, context: context),
        ],
      ),
    );
  }

  Future<void> _showCreateWorkspace(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CreateDialog(
        title: '워크스페이스 만들기',
        fields: [
          _DialogField(controller: nameCtrl, label: '이름', hint: 'My Team'),
          _DialogField(
              controller: slugCtrl, label: 'Slug', hint: 'my-team'),
        ],
        onConfirm: () async {
          await ref.read(workspaceRepositoryProvider).createWorkspace(
              nameCtrl.text.trim(), slugCtrl.text.trim());
          ref.invalidate(workspacesProvider);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _showCreateDoc(
      BuildContext context, WidgetRef ref, String workspaceId) async {
    final titleCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => _CreateDialog(
        title: '새 문서',
        fields: [
          _DialogField(
              controller: titleCtrl, label: '제목', hint: '제목 없음'),
        ],
        onConfirm: () async {
          await ref
              .read(workspaceRepositoryProvider)
              .createDocument(workspaceId, titleCtrl.text.trim());
          ref.invalidate(documentsProvider(workspaceId));
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Sidebar Header
// ──────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.workspaceName, required this.ref});
  final String workspaceName;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: NotonColors.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Center(
              child: Text('N',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              workspaceName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: NotonColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const NotificationBell(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Workspace List
// ──────────────────────────────────────────────

class _WorkspaceList extends ConsumerWidget {
  const _WorkspaceList({
    required this.workspaces,
    required this.selected,
    required this.onSelect,
    required this.onDocTap,
    required this.onChatTap,
    required this.onCreateDoc,
  });

  final List<Workspace> workspaces;
  final Workspace? selected;
  final ValueChanged<Workspace> onSelect;
  final ValueChanged<String> onDocTap;
  final ValueChanged<String> onChatTap;
  final ValueChanged<String> onCreateDoc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final ws in workspaces) ...[
          _WorkspaceSection(
            workspace: ws,
            isExpanded: selected?.id == ws.id,
            onTap: () => onSelect(ws),
            onDocTap: onDocTap,
            onChatTap: onChatTap,
            onCreateDoc: () => onCreateDoc(ws.id),
          ),
        ],
        const SizedBox(height: 4),
        _SidebarActionItem(
          icon: Icons.add,
          label: '워크스페이스 추가',
          onTap: () {},
        ),
      ],
    );
  }
}

class _WorkspaceSection extends ConsumerStatefulWidget {
  const _WorkspaceSection({
    required this.workspace,
    required this.isExpanded,
    required this.onTap,
    required this.onDocTap,
    required this.onChatTap,
    required this.onCreateDoc,
  });

  final Workspace workspace;
  final bool isExpanded;
  final VoidCallback onTap;
  final ValueChanged<String> onDocTap;
  final ValueChanged<String> onChatTap;
  final VoidCallback onCreateDoc;

  @override
  ConsumerState<_WorkspaceSection> createState() => _WorkspaceSectionState();
}

class _WorkspaceSectionState extends ConsumerState<_WorkspaceSection> {
  late bool _expanded;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Workspace row
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              widget.onTap();
            },
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _hovering
                    ? NotonColors.bgHover
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.arrow_drop_down
                        : Icons.arrow_right,
                    size: 16,
                    color: NotonColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.workspaces_outlined,
                      size: 14, color: NotonColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.workspace.name,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: NotonColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_hovering)
                    _IconBtn(
                      icon: Icons.add,
                      tooltip: '새 문서',
                      onTap: widget.onCreateDoc,
                    ),
                ],
              ),
            ),
          ),
        ),

        // Pages list
        if (_expanded) ...[
          _SidebarSectionLabel('페이지'),
          _DocList(
              workspaceId: widget.workspace.id,
              onDocTap: widget.onDocTap),
          _SidebarSectionLabel('채널'),
          _ChannelList(
              workspaceId: widget.workspace.id,
              onChatTap: widget.onChatTap),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _SidebarSectionLabel extends StatelessWidget {
  const _SidebarSectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 2),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: NotonColors.textTertiary,
          letterSpacing: 0.6,
        ),
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
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: LinearProgressIndicator(minHeight: 1),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Text('오류: $e',
            style: const TextStyle(
                fontSize: 11, color: NotonColors.error)),
      ),
      data: (docs) => docs.isEmpty
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text('페이지 없음',
                  style: const TextStyle(
                      fontSize: 12,
                      color: NotonColors.textTertiary)),
            )
          : Column(
              children: docs
                  .map((doc) => _SidebarItem(
                        icon: Icons.article_outlined,
                        label: doc.title,
                        onTap: () => onDocTap(doc.id),
                      ))
                  .toList(),
            ),
    );
  }
}

class _ChannelList extends ConsumerWidget {
  const _ChannelList(
      {required this.workspaceId, required this.onChatTap});
  final String workspaceId;
  final ValueChanged<String> onChatTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Channels list — reuse chatRepositoryProvider
    return _SidebarItem(
      icon: Icons.tag,
      label: 'general',
      onTap: () => onChatTap('general'),
    );
  }
}

// ──────────────────────────────────────────────
//  Sidebar Item (hover effect)
// ──────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: widget.active
                ? NotonColors.bgActive
                : _hovering
                    ? NotonColors.bgHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16), // indent
              Icon(widget.icon,
                  size: 14, color: NotonColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: NotonColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarActionItem extends StatefulWidget {
  const _SidebarActionItem(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SidebarActionItem> createState() => _SidebarActionItemState();
}

class _SidebarActionItemState extends State<_SidebarActionItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovering ? NotonColors.bgHover : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  size: 14, color: NotonColors.textTertiary),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: const TextStyle(
                      fontSize: 13, color: NotonColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(
      {required this.icon,
      required this.tooltip,
      required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: NotonColors.bgActive,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: NotonColors.textSecondary),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Sidebar Footer
// ──────────────────────────────────────────────

class _SidebarFooter extends StatefulWidget {
  const _SidebarFooter({required this.ref, required this.context});
  final WidgetRef ref;
  final BuildContext context;

  @override
  State<_SidebarFooter> createState() => _SidebarFooterState();
}

class _SidebarFooterState extends State<_SidebarFooter> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () async {
          await widget.ref.read(authStatusProvider.notifier).logout();
          if (widget.context.mounted) widget.context.go('/login');
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: _hovering ? NotonColors.bgHover : Colors.transparent,
          child: const Row(
            children: [
              Icon(Icons.logout_outlined,
                  size: 15, color: NotonColors.textSecondary),
              SizedBox(width: 8),
              Text('로그아웃',
                  style: TextStyle(
                      fontSize: 13, color: NotonColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Empty State
// ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});
  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: NotonColors.bgHover,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspaces_outlined,
                  size: 20, color: NotonColors.textTertiary),
            ),
            const SizedBox(height: 12),
            const Text('워크스페이스가 없습니다',
                style: TextStyle(
                    fontSize: 13, color: NotonColors.textSecondary)),
            const SizedBox(height: 16),
            SizedBox(
              height: 32,
              child: FilledButton(
                onPressed: onCreateTap,
                child: const Text('만들기', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarError extends StatelessWidget {
  const _SidebarError({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
        child: Text('$error',
            style: const TextStyle(
                fontSize: 12, color: NotonColors.error)),
      );
}

// ──────────────────────────────────────────────
//  Reusable Create Dialog
// ──────────────────────────────────────────────

class _DialogField {
  const _DialogField(
      {required this.controller,
      required this.label,
      required this.hint});
  final TextEditingController controller;
  final String label;
  final String hint;
}

class _CreateDialog extends StatelessWidget {
  const _CreateDialog({
    required this.title,
    required this.fields,
    required this.onConfirm,
  });
  final String title;
  final List<_DialogField> fields;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: fields
              .map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.label,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: NotonColors.textPrimary)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: f.controller,
                          autofocus: fields.indexOf(f) == 0,
                          decoration: InputDecoration(hintText: f.hint),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
      actions: [
        OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        FilledButton(
            onPressed: onConfirm, child: const Text('만들기')),
      ],
    );
  }
}
