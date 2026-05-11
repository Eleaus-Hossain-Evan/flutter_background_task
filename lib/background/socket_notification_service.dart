import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class SocketNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  static int _notificationIdCounter = 0;

  static const String _channelId = 'socket_events';
  static const String _channelName = 'Socket Events';
  static const String _channelDescription =
      'Notifications from background socket events';

  Future<void> initialize() async {
    if (_isInitialized && (_initCompleter?.isCompleted ?? true)) return;

    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            'socket_notification',
            actions: [
              DarwinNotificationAction.plain(
                'view_action',
                'View',
                options: {DarwinNotificationActionOption.foreground},
              ),
              DarwinNotificationAction.plain(
                'dismiss_action',
                'Dismiss',
                options: {DarwinNotificationActionOption.destructive},
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

      await _plugin.initialize(initSettings);
      await _createAndroidChannel();

      _isInitialized = true;
      _initCompleter?.complete();
    } catch (e) {
      developer.log(
        'Failed to initialize SocketNotificationService: $e',
        name: 'SocketNotificationService',
        level: 1000,
      );
      _initCompleter?.completeError(e);
      rethrow;
    }
  }

  Future<void> _createAndroidChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(androidChannel);
  }

  int _generateNotificationId() {
    _notificationIdCounter++;
    return _notificationIdCounter;
  }

  Future<void> showEventNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final id = _generateNotificationId();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      actions: [
        AndroidNotificationAction(
          'view_action',
          'View',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'dismiss_action',
          'Dismiss',
          cancelNotification: true,
        ),
      ],
    );

    const darwinDetails = DarwinNotificationDetails(
      categoryIdentifier: 'socket_notification',
      interruptionLevel: InterruptionLevel.active,
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final payloadData = jsonEncode({
      'id': id.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'rawPayload': payload,
    });

    await _plugin.show(id, title, body, details, payload: payloadData);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  void dispose() {
    _isInitialized = false;
  }
}