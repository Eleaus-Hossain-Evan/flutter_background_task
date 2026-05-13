import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_background_task/core/notifications/notification_service.dart';
import 'package:flutter_background_task/core/notifications/local_notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MockLocalPlugin extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  test('LocalNotificationService.show forwards to plugin with correct payload', () async {
    final mockPlugin = MockLocalPlugin();
    when(() => mockPlugin.show(
      id: any(named: 'id'),
      title: any(named: 'title'),
      body: any(named: 'body'),
      notificationDetails: any(named: 'notificationDetails'),
      payload: any(named: 'payload'),
    )).thenAnswer((_) async {});

    LocalNotificationService.replacePlugin(mockPlugin);
    final service = LocalNotificationService();

    await service.show(
      id: 1,
      title: 'Test',
      body: 'Body',
    );

    verify(() => mockPlugin.show(
      id: 1,
      title: 'Test',
      body: 'Body',
      notificationDetails: any(named: 'notificationDetails'),
      payload: any(named: 'payload'),
    )).called(1);
  });
}
