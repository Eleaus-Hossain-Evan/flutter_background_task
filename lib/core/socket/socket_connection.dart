import 'package:socket_io_client/socket_io_client.dart' as IO;

abstract class SocketConnection {
  void onConnect(void Function() callback);
  void onDisconnect(void Function() callback);
  void onError(void Function(dynamic error) callback);
  void onConnectError(void Function(dynamic error) callback);
  void onAny(void Function(String event, dynamic data) callback);
  void connect();
  void disconnect();
  void emit(String event, dynamic data);
  void on(String event, void Function(dynamic data) callback);
}

class SocketIoConnection implements SocketConnection {
  late final IO.Socket _socket;

  SocketIoConnection(
    String url, {
    required Map<String, dynamic> auth,
  }) {
    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth(auth)
          .enableAutoConnect()
          .setTimeout(500)
          .enableMultiplex()
          .build(),
    );
  }

  @override
  void connect() => _socket.connect();

  @override
  void disconnect() => _socket.disconnect();

  @override
  void emit(String event, dynamic data) => _socket.emit(event, data);

  @override
  void onConnect(void Function() callback) {
    _socket.onConnect((_) => callback());
  }

  @override
  void onDisconnect(void Function() callback) {
    _socket.onDisconnect((_) => callback());
  }

  @override
  void onError(void Function(dynamic error) callback) {
    _socket.onError((error) => callback(error));
  }

  @override
  void onConnectError(void Function(dynamic error) callback) {
    _socket.onConnectError((error) => callback(error));
  }

  @override
  void onAny(void Function(String event, dynamic data) callback) {
    _socket.onAny((event, data) => callback(event, data));
  }

  @override
  void on(String event, void Function(dynamic data) callback) {
    _socket.on(event, (data) => callback(data));
  }
}
