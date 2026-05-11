import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/online_provider.dart';
import '../providers/socket_connection_provider.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(onlineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Switch(
            value: isOnline,
            onChanged: (value) async {
              await ref.read(onlineProvider.notifier).set(value);
            },
          ),
          const Text(
            'Go Online',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
