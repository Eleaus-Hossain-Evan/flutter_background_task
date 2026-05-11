import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketEvent {
  final String type;
  final dynamic payload;

  const SocketEvent._(this.type, this.payload);
  const SocketEvent.connected() : this._('connected', null);
  const SocketEvent.disconnected() : this._('disconnected', null);
  const SocketEvent.notification(dynamic data) : this._('notification', data);
  const SocketEvent.error(dynamic err) : this._('error', err);
}

class SocketService {
  final String _url;
  IO.Socket? _socket;
  final _controller = StreamController<SocketEvent>.broadcast();

  SocketService({required String url}) : _url = url;

  Stream<SocketEvent> get events => _controller.stream;

  Future<void> connect() async {
    if (_socket != null) return;
    _socket = IO.io(
      _url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) => _controller.add(const SocketEvent.connected()));
    _socket!.onDisconnect((_) => _controller.add(const SocketEvent.disconnected()));
    _socket!.on('notification:new', (data) {
      _controller.add(SocketEvent.notification(data));
    });
    _socket!.onError((err) => _controller.add(SocketEvent.error(err)));
  }

  Future<void> disconnect() async {
    await _socket?.disconnect();
    await _socket?.close();
    _socket = null;
    await _controller.close();
  }

  void emit(String event, dynamic data) => _socket?.emit(event, data);
}