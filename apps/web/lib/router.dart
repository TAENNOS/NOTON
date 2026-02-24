import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/shell/shell_screen.dart';
import 'features/docs/screens/doc_editor_screen.dart';
import 'features/chat/screens/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ref.watch(authStatusProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      if (authStatus == AuthStatus.loading) return null;
      final isAuth = authStatus == AuthStatus.authenticated;
      final isOnAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register');

      if (!isAuth && !isOnAuth) return '/login';
      if (isAuth && isOnAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (_, __) => const _HomeView(),
          ),
          GoRoute(
            path: '/docs/:id',
            builder: (_, state) =>
                DocEditorScreen(docId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/chat/:channelId',
            builder: (_, state) =>
                ChatScreen(channelId: state.pathParameters['channelId']!),
          ),
        ],
      ),
    ],
  );
});

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.article_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('사이드바에서 문서를 선택하거나 만드세요'),
        ],
      ),
    );
  }
}
