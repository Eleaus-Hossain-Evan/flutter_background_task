import 'dart:async';
import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as sic;

class SocketService {
  static const baseUrlSocket =
      'https://realtime-db-server.techanalyticaltd.com';

  final sic.Socket _socket;

  SocketService()
    : _socket = sic.io(
        baseUrlSocket,
        sic.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

  void init() {
    _socket
      ..onConnect(
        (payload) => log('socket connected: $payload', name: 'SocketService'),
      )
      ..onDisconnect(
        (payload) =>
            log('socket disconnected: $payload', name: 'SocketService'),
      )
      ..onReconnect(
        (payload) => log('socket reconnected: $payload', name: 'SocketService'),
      )
      ..onError(
        (payload) =>
            log('socket error: $payload', name: 'SocketService', level: 1000),
      )
      ..onConnectError(
        (payload) => log(
          'socket connect error: $payload',
          name: 'SocketService',
          level: 1000,
        ),
      );
    _socket.connect();
  }

  void connect() => init();

  void disconnect() => dispose();

  void dispose() {
    _socket.clearListeners();
    _socket.close();
    _socket.dispose();
  }

  final events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get eventStream => events.stream;

  void on(String eventName) {
    _socket.on(eventName, (payload) {
      log(
        'Received socket event: $eventName with payload: $payload',
        name: 'SocketService',
      );
      events.add(payload as Map<String, dynamic>);
    });
  }
}
