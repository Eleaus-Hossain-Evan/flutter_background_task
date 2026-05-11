import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef SocketEventCallback = void Function(dynamic data);

class BackgroundSocketService {
  static const String _baseUrl =
      'https://realtime-db-server.tekanalyticaltd.com';

  io.Socket? _socket;
  final _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<bool>.broadcast();

  SocketEventCallback? onConnected;
  SocketEventCallback? onDisconnected;
  SocketEventCallback? onError;

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<bool> get connectionStateStream =>
      _connectionStateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect([String? url]) {
    final serverUrl = url ?? _baseUrl;

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setReconnectionAttempts(5)
          .setReconnectionDelay(3000)
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      developer.log('Socket connected', name: 'BackgroundSocketService');
      _connectionStateController.add(true);
      onConnected?.call(null);
    });

    _socket!.onDisconnect((_) {
      developer.log('Socket disconnected', name: 'BackgroundSocketService');
      _connectionStateController.add(false);
      onDisconnected?.call(null);
    });

    _socket!.onReconnect((attempt) {
      developer.log(
        'Socket reconnecting... attempt $attempt',
        name: 'BackgroundSocketService',
      );
    });

    _socket!.onConnectError((error) {
      developer.log(
        'Socket connection error: $error',
        name: 'BackgroundSocketService',
        level: 1000,
      );
      onError?.call(error);
    });

    _socket!.onError((error) {
      developer.log(
        'Socket error: $error',
        name: 'BackgroundSocketService',
        level: 1000,
      );
      onError?.call(error);
    });

    _socket!.on('event', (data) {
      developer.log(
        'Received socket event: $data',
        name: 'BackgroundSocketService',
      );
      if (data is Map<String, dynamic>) {
        _eventController.add(data);
      } else if (data != null) {
        _eventController.add({'data': data});
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    _socket?.clearListeners();
    _socket?.close();
    _socket?.dispose();
    _socket = null;
    _eventController.close();
    _connectionStateController.close();
  }
}