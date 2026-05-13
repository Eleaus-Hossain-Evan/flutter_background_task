import 'package:flutter/material.dart';
import 'package:flutter_background_task/home/home_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/background/foreground_service_manager.dart';
import 'core/notifications/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize background service
  await LocalNotificationService.init();
  await ForegroundServiceManager.init();
  ForegroundServiceManager.initCommunicationPort();

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}
