import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_background_task/services/local_notification_service.dart';

class FakeFlutterLocalNotificationsPlugin extends Fake implements FlutterLocalNotificationsPlugin {
  bool showCalled = false;
  int? lastId;
  String? lastTitle;
  String? lastBody;
  String? lastPayload;
  NotificationDetails? lastDetails;
  bool zonedScheduleCalled = false;
  DateTimeComponents? lastMatchDateTimeComponents;
  tz.TZDateTime? lastScheduledDate;
  bool cancelCalled = false;
  int? lastCancelledId;
  bool cancelAllCalled = false;

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
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
    bool androidAllowWhileIdle = false,
    AndroidScheduleMode? androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    zonedScheduleCalled = true;
    lastMatchDateTimeComponents = matchDateTimeComponents;
    lastScheduledDate = scheduledDate;
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelCalled = true;
    lastCancelledId = id;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCalled = true;
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

  test('scheduleDaily should schedule a daily recurring notification', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockPlugin = FakeFlutterLocalNotificationsPlugin();
    final service = LocalNotificationService(plugin: mockPlugin);
    await service.initialize();

    await service.scheduleDaily(
      id: 3,
      title: 'Daily Title',
      body: 'Daily Body',
      hour: 10,
      minute: 30,
      payload: 'daily_payload',
    );

    expect(mockPlugin.zonedScheduleCalled, isTrue);
    expect(mockPlugin.lastMatchDateTimeComponents, equals(DateTimeComponents.time));
  });

  test('scheduleWeekly should schedule weekly recurring notification', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockPlugin = FakeFlutterLocalNotificationsPlugin();
    final service = LocalNotificationService(plugin: mockPlugin);
    await service.initialize();

    await service.scheduleWeekly(
      id: 4,
      title: 'Weekly Title',
      body: 'Weekly Body',
      hour: 9,
      minute: 0,
      weekdays: [1, 3, 5],
      payload: 'weekly_payload',
    );

    expect(mockPlugin.zonedScheduleCalled, isTrue);
    expect(mockPlugin.lastMatchDateTimeComponents, equals(DateTimeComponents.dayOfWeekAndTime));
  });

  test('cancel should cancel a specific notification by id', () async {
    final mockPlugin = FakeFlutterLocalNotificationsPlugin();
    final service = LocalNotificationService(plugin: mockPlugin);

    await service.cancel(5);

    expect(mockPlugin.cancelCalled, isTrue);
    expect(mockPlugin.lastCancelledId, equals(5));
  });

  test('cancelAll should cancel all notifications', () async {
    final mockPlugin = FakeFlutterLocalNotificationsPlugin();
    final service = LocalNotificationService(plugin: mockPlugin);

    await service.cancelAll();

    expect(mockPlugin.cancelAllCalled, isTrue);
  });
}