// Sealed event model
import 'package:flutter_background_task/models/notification_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'socket_event.freezed.dart';

@freezed
sealed class SocketEvent with _$SocketEvent {
  const factory SocketEvent.connected() = ConnectedEvent;
  const factory SocketEvent.disconnected() = DisconnectedEvent;
  const factory SocketEvent.error(dynamic message) = ErrorEvent;
  const factory SocketEvent.notification(NotificationModel data) =
      NotificationEvent;
}
