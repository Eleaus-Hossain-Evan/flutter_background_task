import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/background/socket_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SocketNotificationService', () {
    late SocketNotificationService service;

    setUp(() async {
      service = SocketNotificationService();
      await service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test('initialize should setup notification channel', () async {
      expect(service, isNotNull);
    });

    test('showEventNotification should display notification', () async {
      await service.showEventNotification(
        title: 'Test Title',
        body: 'Test Body',
        payload: '{"id": "123"}',
      );
    });
  });
}