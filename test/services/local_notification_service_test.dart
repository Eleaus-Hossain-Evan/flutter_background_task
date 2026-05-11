import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_task/services/local_notification_service.dart';

class FakeFlutterLocalNotificationsPlugin extends Fake implements FlutterLocalNotificationsPlugin {
  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)? onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #resolvePlatformSpecificImplementation) {
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  test('LocalNotificationService should be instantiable', () {
    final service = LocalNotificationService(
      plugin: FlutterLocalNotificationsPlugin(),
    );
    expect(service, isNotNull);
  });

  test('initialize should initialize the plugin', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final service = LocalNotificationService(
      plugin: FakeFlutterLocalNotificationsPlugin(),
    );
    await service.initialize();
    expect(true, isTrue);
  });
}
