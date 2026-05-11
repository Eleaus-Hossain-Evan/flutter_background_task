import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'socket_service.dart';

part 'socket_service_provider.g.dart';

@riverpod
SocketService socketService(SocketServiceRef ref) {
  const socketUrl = 'https://your-socket-server.com';
  return SocketService(url: socketUrl);
}
