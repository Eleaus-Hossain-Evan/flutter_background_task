import 'package:flutter/material.dart';
import 'package:flutter_background_task/home/home_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background/background_entry.dart';
import 'providers/online_provider.dart';

final _rootContainer = ProviderContainer();
final ref = _rootContainer.ref;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ref.read(onlineProvider.notifier).init();

  await FlutterBackgroundService.initialize(
    androidConfiguration: AndroidConfiguration(
      notificationTitle: "Background Socket",
      notificationContent: "Running...",
      foregroundMode: true,
    ),
    iosConfiguration: null,
  );

  FlutterBackgroundService().setBackgroundService(
    onStart: backgroundEntryPoint,
  );

  runApp(
    ProviderScope(
      child: const MyApp(),
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