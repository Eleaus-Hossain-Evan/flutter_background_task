import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/background/socket_notification_service.dart';

void main() {
  group('SocketNotificationService', () {
    late SocketNotificationService service;

    test('can be instantiated', () {
      service = SocketNotificationService();
      expect(service, isNotNull);
    });

    test('has showEventNotification method', () {
      service = SocketNotificationService();
      expect(service.showEventNotification, isA<Function>());
    });

    test('has cancelAll method', () {
      service = SocketNotificationService();
      expect(service.cancelAll, isA<Function>());
    });

    test('has dispose method', () {
      service = SocketNotificationService();
      expect(service.dispose, isA<Function>());
    });
  });
}