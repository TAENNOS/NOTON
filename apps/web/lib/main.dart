import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: NotonWebApp()));
}

class NotonWebApp extends ConsumerWidget {
  const NotonWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'NOTON',
      debugShowCheckedModeBanner: false,
      theme: buildNotonTheme(),
      routerConfig: router,
    );
  }
}
