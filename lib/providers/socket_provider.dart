import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/socket/socket_event.dart';
import '../core/socket/socket_service.dart';

part 'socket_provider.g.dart';

@riverpod
SocketService socketService(Ref ref) {
  final service = SocketService();
  ref.onDispose(service.disconnect);
  return service;
}

@riverpod
Stream<SocketEvent> socketEvent(Ref ref) {
  final socket = ref.watch(socketServiceProvider);
  socket.connect();
  return socket.eventStream;
}
