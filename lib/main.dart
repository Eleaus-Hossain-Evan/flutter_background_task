import 'package:flutter/material.dart';
import 'package:flutter_background_task/home/home_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background/background_entry.dart';
import 'providers/online_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo BG Task',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const HomeScreen(),
    );
  }
}