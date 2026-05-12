import 'dart:async';
import 'dart:developer';

import 'package:flutter_background_task/models/notification_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'socket_event.dart';

abstract class ISocketService {
  Stream<dynamic> get eventStream;
  void connect();
  void disconnect();
  void emit(String event, dynamic data);
}

class SocketService implements ISocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  late final IO.Socket _socket;
  final _controller = StreamController<SocketEvent>.broadcast();

  @override
  Stream<SocketEvent> get eventStream => _controller.stream;

  @override
  void connect() {
    _socket = IO.io(
      'https://api.ambufast.com/notification',
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({
            'token': 'b326b2dcadbcc872d35cce1ecca4e90a6e025cdf',
          })
          // .enableAutoConnect()
          // .enableReconnection()
          // .setReconnectionDelay(2000)
          .build(),
    );

    _socket
      ..onConnect((_) {
        log('[onConnect]', name: 'SocketService');
        _emit(.connected());
      })
      ..onDisconnect((_) {
        log('[onDisconnect]', name: 'SocketService');
        _emit(.disconnected());
      })
      ..onError((error) {
        log('[onError]', error: error, name: 'SocketService', level: 1000);
        _emit(.error(error));
      })
      ..onConnectError((error) {
        log(
          '[onConnectError]',
          error: error,
          name: 'SocketService',
          level: 1000,
        );
        _emit(.error(error));
      })
      ..onPing((data) {
        log('[onPing] $data', name: 'SocketService');
      })
      ..onAny((event, data) {
        log('[onAny] \nevent: $event, \ndata: $data', name: 'SocketService');
      });

    _socket.connect();

    _socket.on('notification:new', (data) {
      log('[onNotificationNew] \ndata: $data', name: 'SocketService');
      final model = NotificationModel.fromMap(data);
      _emit(SocketEvent.notification(model));
    });
  }

  void _emit(SocketEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  @override
  void disconnect() => _socket.disconnect();

  @override
  void emit(String event, dynamic data) => _socket.emit(event, data);
}
