import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'socket_service.dart';

part 'socket_service_provider.g.dart';

@riverpod
SocketService socketService(Ref ref) {
  const socketUrl = 'https://your-socket-server.com';
  return SocketService(url: socketUrl);
}
