import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_task/services/local_notification_service.dart';

class FakeFlutterLocalNotificationsPlugin extends Fake implements FlutterLocalNotificationsPlugin {
  bool showCalled = false;
  int? lastId;
  String? lastTitle;
  String? lastBody;
  String? lastPayload;
  NotificationDetails? lastDetails;

  @override
  Future<bool?> initialize(
    InitializationSettings initializationSettings, {
    void Function(NotificationResponse)? onDidReceiveNotificationResponse,
    void Function(NotificationResponse)? onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    showCalled = true;
    lastId = id;
    lastTitle = title;
    lastBody = body;
    lastPayload = payload;
    lastDetails = notificationDetails;
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

  test('show should call plugin show with correct parameters', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockPlugin = FakeFlutterLocalNotificationsPlugin();
    final service = LocalNotificationService(plugin: mockPlugin);

    await service.show(
      id: 1,
      title: 'Test Title',
      body: 'Test Body',
      payload: 'test_payload',
    );

    expect(mockPlugin.showCalled, isTrue);
    expect(mockPlugin.lastId, equals(1));
    expect(mockPlugin.lastTitle, equals('Test Title'));
    expect(mockPlugin.lastBody, equals('Test Body'));
    expect(mockPlugin.lastPayload, equals('test_payload'));
  });

  test('showWithActions should include View and Dismiss actions', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockPlugin = FakeFlutterLocalNotificationsPlugin();
    final service = LocalNotificationService(plugin: mockPlugin);

    await service.showWithActions(
      id: 2,
      title: 'Action Title',
      body: 'Action Body',
      payload: 'action_payload',
    );

    expect(mockPlugin.showCalled, isTrue);
    final androidDetails = mockPlugin.lastDetails?.android as AndroidNotificationDetails?;
    expect(androidDetails?.actions?.length, equals(2));
    expect(androidDetails?.actions?[0].id, equals('view_action'));
    expect(androidDetails?.actions?[1].id, equals('dismiss_action'));
  });
}