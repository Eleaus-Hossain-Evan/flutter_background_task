import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/notification_model.dart';
import 'socket_service.dart';

part 'socket_service_provider.g.dart';

@riverpod
SocketService socketService(Ref ref) => SocketService();

@riverpod
Stream<NotificationModel> notificationStream(Ref ref) {
  final socket = ref.watch(socketServiceProvider);
  socket
    ..init()
    ..on('notification:new');
  return socket.eventStream.map(
    (event) => NotificationModel.fromMap(event),
  );
}
