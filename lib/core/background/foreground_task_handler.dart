// lib/core/background/foreground_task_handler.dart

import 'dart:async';
import 'dart:developer';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../models/notification_model.dart';
import '../notifications/local_notification_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SocketTaskHandler());
}

class SocketTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    log(
      '=============================\nForeground task started by ${starter.name} at $timestamp \n=============================',
      name: 'SocketTaskHandler',
    );
    IO.Socket socket = IO.io(
      'https://api.ambufast.com/notification',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({
            'token': 'a0830e7ec7a7de1f67503f14249602db5144a0a5',
          })
          .enableAutoConnect()
          .setTimeout(500)
          .enableMultiplex()
          .build(),
    );

    socket.onConnect((_) {
      print('connect');
      socket.emit('msg', 'test');
    });

    //When an event received from server, data is added to the stream
    socket.onDisconnect((data) {
      log('disconnect');
    });
    socket.onError((error) {
      print('error: $error');
    });
    socket.onConnectError((error) {
      print('connect error: $error');
    });
    socket.onAny((event, data) => print('onAny: $event: $data'));

    socket.connect();

    socket.on('notification:new', (data) {
      log('[onNotificationNew] \ndata: $data', name: 'SocketService');
      final model = NotificationModel.fromMap(data);
      final notificationService = LocalNotificationService();
      notificationService.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: model.message,
        body: model.data.message,
      );
    });
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    log(
      'onRepeatEvent at $timestamp',
      name: 'SocketTaskHandler',
    );
    // Heartbeat / ping to keep socket alive
    // _socket.emit('ping', null);
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) {
    log(
      '=============================\nForeground task destroyed at $timestamp \n=============================',
      name: 'SocketTaskHandler',
    );
    // _socket.disconnect();
    return Future.value();
  }
}
