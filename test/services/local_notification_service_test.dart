import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_task/services/local_notification_service.dart';

void main() {
  test('LocalNotificationService should be instantiable', () {
    final service = LocalNotificationService(
      plugin: FlutterLocalNotificationsPlugin(),
    );
    expect(service, isNotNull);
  });
}