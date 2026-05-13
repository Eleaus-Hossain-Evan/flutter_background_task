import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_background_task/core/socket/socket_connection.dart';
import 'package:flutter_background_task/core/socket/socket_event.dart';
import 'package:flutter_background_task/core/socket/socket_service.dart';

class MockConnection extends Mock implements SocketConnection {}

void main() {
  test('SocketService emits Connected event on socket onConnect', () async {
    final mockConn = MockConnection();

    when(() => mockConn.onConnect(any())).thenAnswer((inv) {
      final cb = inv.positionalArguments[0] as void Function();
      cb();
    });

    final service = SocketService.withConnection(mockConn);
    final future = expectLater(
      service.eventStream,
      emits(SocketEvent.connected()),
    );
    service.connect();
    await future;
  });
}
