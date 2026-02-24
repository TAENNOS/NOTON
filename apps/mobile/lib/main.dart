import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: NotonApp()));
}

class NotonApp extends StatelessWidget {
  const NotonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOTON',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5CE7)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('NOTON Mobile', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
