import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/socket_service_provider.dart';
import 'online_provider.dart';

part 'socket_connection_provider.g.dart';

@riverpod
class SocketConnection extends _$SocketConnection {
  @override
  FutureOr<bool> build() async {
    final isOnline = ref.watch(onlineProvider);
    final socket = ref.watch(socketServiceProvider);

    if (isOnline) {
      await socket.connect();
      return true;
    } else {
      socket.disconnect();
      return false;
    }
  }

  Future<void> refresh() async => await ref.refresh(socketConnectionProvider.future);
}