import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_task/models/notification_model.dart';

import 'socket_connection.dart';
import 'socket_event.dart';

abstract class ISocketService {
  Stream<dynamic> get eventStream;
  void connect();
  void disconnect();
  void emit(String event, dynamic data);
}

class SocketService implements ISocketService {
  SocketService()
    : _connection = SocketIoConnection(
        'https://api.ambufast.com/notification',
        auth: {
          'token': 'b326b2dcadbcc872d35cce1ecca4e90a6e025cdf',
        },
      );
  @visibleForTesting
  SocketService.withConnection(this._connection);

  final SocketConnection _connection;
  final _controller = StreamController<SocketEvent>.broadcast();

  @override
  Stream<SocketEvent> get eventStream => _controller.stream;

  @override
  void connect() {
    _connection.onConnect(_handleConnect);
    _connection.onDisconnect(_handleDisconnect);
    _connection.onError(_handleError);
    _connection.onConnectError(_handleConnectError);
    _connection.onAny(_handleAny);
    _connection.connect();
    _connection.on('notification:new', _handleNotification);
  }

  void _handleConnect() {
    log('[onConnect]', name: 'SocketService');
    _emit(SocketEvent.connected());
  }

  void _handleDisconnect() {
    log('[onDisconnect]', name: 'SocketService');
    _emit(SocketEvent.disconnected());
  }

  void _handleError(dynamic error) {
    log('[onError]', error: error, name: 'SocketService', level: 1000);
    _emit(SocketEvent.error(error));
  }

  void _handleConnectError(dynamic error) {
    log(
      '[onConnectError]',
      error: error,
      name: 'SocketService',
      level: 1000,
    );
    _emit(SocketEvent.error(error));
  }

  void _handleAny(String event, dynamic data) {
    log('[onAny] \nevent: $event, \ndata: $data', name: 'SocketService');
  }

  void _handleNotification(dynamic data) {
    log('[onNotificationNew] \ndata: $data', name: 'SocketService');
    final model = NotificationModel.fromMap(data);
    _emit(SocketEvent.notification(model));
  }

  void _emit(SocketEvent event) {
    if (!_controller.isClosed) _controller.add(event);
  }

  @override
  void disconnect() => _connection.disconnect();

  @override
  void emit(String event, dynamic data) => _connection.emit(event, data);
}
