import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_task/background/background_socket_service.dart';
import 'package:flutter_background_task/background/socket_notification_service.dart';

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = SocketNotificationService();
  await notificationService.initialize();

  final socketService = BackgroundSocketService();

  socketService.onConnected = (data) {
    service.invoke('onConnected', {'status': 'connected'});
  };

  socketService.onDisconnected = (data) {
    service.invoke('onDisconnected', {'status': 'disconnected'});
  };

  socketService.onError = (data) {
    service.invoke('onError', {'error': data?.toString() ?? 'unknown'});
  };

  socketService.eventStream.listen((event) async {
    final title = event['title']?.toString() ?? 'New Event';
    final body = event['body']?.toString() ??
        event['message']?.toString() ??
        'You have a new notification';
    final payload = event.toString();

    await notificationService.showEventNotification(
      title: title,
      body: body,
      payload: payload,
    );

    service.invoke('onEvent', event);
  });

  socketService.connect();

  service.on('stopService').listen((event) {
    socketService.dispose();
    notificationService.dispose();
    service.stopSelf();
  });

  service.on('reconnect').listen((event) {
    if (!socketService.isConnected) {
      socketService.disconnect();
      socketService.connect();
    }
  });

  service.on('checkStatus').listen((event) {
    service.invoke(
      'status',
      {
        'isConnected': socketService.isConnected,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  });
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'socket_events',
    'Socket Events',
    description: 'Background socket notification channel',
    importance: Importance.max,
  );

  final flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'socket_events',
      initialNotificationTitle: 'Background Service',
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