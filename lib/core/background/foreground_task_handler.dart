import 'dart:async';
import 'dart:developer';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../models/notification_model.dart';
import '../notifications/local_notification_service.dart';
import '../notifications/notification_service.dart';
import '../socket/socket_event.dart';
import '../socket/socket_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(
    SocketTaskHandler(
      socketService: SocketService(),
      notificationService: LocalNotificationService(),
    ),
  );
}

class SocketTaskHandler extends TaskHandler {
  SocketTaskHandler({
    required ISocketService socketService,
    required NotificationService notificationService,
  })  : _socketService = socketService,
        _notificationService = notificationService;

  final ISocketService _socketService;
  final NotificationService _notificationService;
  StreamSubscription<dynamic>? _subscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    log(
      '=============================\nForeground task started by ${starter.name} at $timestamp \n=============================',
      name: 'SocketTaskHandler',
    );

    _subscription = _socketService.eventStream.listen((event) {
      if (event is SocketEvent) _handleSocketEvent(event);
    });

    _socketService.connect();
  }

  void _handleSocketEvent(SocketEvent event) {
    event.when(
      connected: () => log('[Connected]', name: 'SocketTaskHandler'),
      disconnected: () => log('[Disconnected]', name: 'SocketTaskHandler'),
      error: (error) => log('[Error] $error', name: 'SocketTaskHandler'),
      notification: _handleNotification,
    );
  }

  void _handleNotification(NotificationModel model) {
    log('[Notification] ${model.message}', name: 'SocketTaskHandler');
    _notificationService.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: model.message,
      body: model.data.message,
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    log('onRepeatEvent at $timestamp', name: 'SocketTaskHandler');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) {
    log(
      '=============================\nForeground task destroyed at $timestamp \n=============================',
      name: 'SocketTaskHandler',
    );
    _subscription?.cancel();
    _socketService.disconnect();
    return Future.value();
  }
}
