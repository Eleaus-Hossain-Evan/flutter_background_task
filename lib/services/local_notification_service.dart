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
}