import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/socket_service.dart';
import '../services/socket_service_provider.dart';
import '../services/local_notification_service.dart';
import '../providers/online_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifService = LocalNotificationService();
  await notifService.initialize();

  final container = ProviderContainer();

  final prefs = await SharedPreferences.getInstance();
  final persisted = prefs.getBool('isOnline') ?? false;
  container.read(onlineProvider.notifier).set(persisted);

  final socket = container.read(socketServiceProvider);
  socket.events.listen((event) async {
    if (event.type == 'notification') {
      final payload = event.payload as Map<String, dynamic>;
      await notifService.showWithActions(
        id: 0,
        title: payload['title'] ?? 'New notification',
        body: payload['body'] ?? '',
        payload: payload.toString(),
      );
    }
  });

  service.on('stopService').listen((_) {
    socket.disconnect();
    service.stopSelf();
  });
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'socket_channel',
    'Socket Events',
    description: 'Background notification channel',
    importance: Importance.max,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'socket_channel',
      initialNotificationTitle: 'Background Socket',
      initialNotificationContent: 'Running...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}
