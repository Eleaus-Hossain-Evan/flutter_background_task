import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

typedef NotificationTapCallback = void Function(String? payload);

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  NotificationTapCallback? _onNotificationTap;

  LocalNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  void setNotificationTapCallback(NotificationTapCallback? callback) {
    _onNotificationTap = callback;
  }

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'local_notification_category',
          actions: <DarwinNotificationAction>[
            DarwinNotificationAction.plain(
              'view_action',
              'View',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.foreground,
              },
            ),
            DarwinNotificationAction.plain(
              'dismiss_action',
              'Dismiss',
              options: <DarwinNotificationActionOption>{
                DarwinNotificationActionOption.destructive,
              },
            ),
          ],
        ),
      ],
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    await _createNotificationChannels();
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'view_action') {
      _onNotificationTap?.call(response.payload);
    }
  }

  Future<void> _createNotificationChannels() async {
    const defaultChannel = AndroidNotificationChannel(
      'local_notifications',
      'Local Notifications',
      description: 'Channel for local notifications',
      importance: Importance.max,
    );

    const scheduledChannel = AndroidNotificationChannel(
      'scheduled_notifications',
      'Scheduled Notifications',
      description: 'Channel for scheduled notifications',
      importance: Importance.max,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(defaultChannel);
      await androidPlugin.createNotificationChannel(scheduledChannel);
    }
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'local_notifications',
      'Local Notifications',
      channelDescription: 'Channel for local notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'local_notification_category',
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
