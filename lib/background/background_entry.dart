import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/socket_service.dart';
import '../providers/socket_service_provider.dart';
import '../providers/online_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> backgroundEntryPoint(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifPlugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iOSInit = IOSInitializationSettings();
  await notifPlugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iOSInit),
  );

  final container = ProviderContainer();

  final prefs = await SharedPreferences.getInstance();
  final persisted = prefs.getBool('isOnline') ?? false;
  await container.read(onlineProvider.notifier).set(persisted);

  final socket = container.read(socketServiceProvider);
  socket.events.listen((event) async {
    if (event.type == 'notification') {
      final payload = event.payload as Map<String, dynamic>;
      await notifPlugin.show(
        0,
        payload['title'] ?? 'New notification',
        payload['body'] ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'socket_channel',
            'Socket Events',
            channelDescription: 'Background notification channel',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  service.on('stopService').listen((_) async {
    await socket.disconnect();
    service.stopSelf();
  });
}