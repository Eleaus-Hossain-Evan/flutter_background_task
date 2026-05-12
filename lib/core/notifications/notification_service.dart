// import 'dart:convert';
// import 'dart:developer';

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class NotificationService {
//   static final _localNotifications = FlutterLocalNotificationsPlugin();

//   static Future<void> init() async {
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );
//     const iosSettings = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestSoundPermission: true,
//     );

//     await _localNotifications.initialize(
//       settings: InitializationSettings(
//         android: androidSettings,
//         iOS: iosSettings,
//       ),
//       onDidReceiveNotificationResponse: _onNotificationTap,
//       onDidReceiveBackgroundNotificationResponse: _onNotificationTap,
//     );
//   }

//   static Future<void> showRideRequest(Map<String, dynamic> data) async {
//     const androidDetails = AndroidNotificationDetails(
//       'ride_requests',
//       'Ride Requests',
//       channelDescription: 'Incoming ride alerts',
//       importance: Importance.max,
//       priority: Priority.high,
//       fullScreenIntent: true, // wakes screen like a call
//       playSound: true,
//       sound: RawResourceAndroidNotificationSound('ride_alert'), // custom sound
//     );

//     await _localNotifications.show(
//       id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
//       title: 'New Ride Request',
//       body: '${data['pickup']} → ${data['dropoff']}',
//       notificationDetails: const NotificationDetails(android: androidDetails),
//       payload: jsonEncode(data),
//     );
//   }

//   static void _onNotificationTap(NotificationResponse response) {
//     // Navigate to ride request screen via go_router
//     log(
//       'Notification tapped with payload: ${response.payload}',
//       name: 'NotificationService',
//     );
//   }
// }
