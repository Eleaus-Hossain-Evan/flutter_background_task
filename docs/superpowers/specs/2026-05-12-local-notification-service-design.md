# Local Notification Service Design

## Overview

Comprehensive `LocalNotificationService` that encapsulates all flutter_local_notifications functionality including immediate notifications with actions (View/Dismiss) and scheduled notifications (daily/weekly). Built as a Riverpod-injected service for testability and integration with existing background service.

## Architecture

- **Service Class**: `LocalNotificationService` - handles all notification operations
- **Provider**: Riverpod provider `localNotificationServiceProvider` for dependency injection
- **Location**: `lib/services/local_notification_service.dart`

## Public API

### Initialization

```dart
Future<void> initialize()
```

Initializes the Flutter Local Notifications plugin with platform-specific settings for Android and iOS. Should be called once at app startup.

### Immediate Notifications

```dart
Future<void> show({
  required int id,
  required String title,
  required String body,
  String? payload,
})
```

Shows a basic notification without actions.

### Notifications with Actions

```dart
Future<void> showWithActions({
  required int id,
  required String title,
  required String body,
  String? payload,
})
```

Shows a notification with two actions:
- **View**: Opens the app (showsUserInterface: true), triggers callback with payload
- **Dismiss**: Dismisses notification (cancelNotification: true), no callback

### Scheduled Notifications

```dart
Future<void> scheduleDaily({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
  String? payload,
})
```

Schedules a daily recurring notification at the specified time.

```dart
Future<void> scheduleWeekly({
  required int id,
  required String title,
  required String body,
  required int hour,
  required int minute,
  required List<int> weekdays,
  String? payload,
})
```

Schedules a weekly recurring notification. Weekdays: 1=Monday, 7=Sunday.

### Cancellation

```dart
Future<void> cancel(int id)
```

Cancels a specific notification by ID.

```dart
Future<void> cancelAll()
```

Cancels all pending notifications.

### Permission Handling

```dart
Future<bool> requestPermissions()
```

Requests notification permissions on Android and iOS. Returns true if granted.

## Implementation Details

### Initialization Settings

**Android**:
- Use `@mipmap/ic_launcher` as the icon
- Create notification channel with Importance.max and Priority.high

**iOS (Darwin)**:
- Request alert, badge, and sound permissions
- Define notification category with View and Dismiss actions

### Notification Channels

- **Default Channel**: `local_notifications` - For immediate notifications
- **Scheduled Channel**: `scheduled_notifications` - For scheduled notifications

### Timezone Handling

Use `timezone` package for `TZDateTime` to handle scheduled notifications properly. Initialize timezone data at service initialization.

### Callback Handling

The service accepts an optional `onNotificationTap` callback that is invoked when the user taps the "View" action. This callback receives the notification's payload (if any).

## Platform-Specific Configuration

### Android Requirements

- `WAKE_LOCK` permission for scheduled notifications
- `SCHEDULE_EXACT_ALARM` permission for precise scheduling (Android 12+)
- Foreground service permission for background notifications

### iOS Requirements

- Background modes: `fetch`, `remote-notification`, `processing`
- Set UNUserNotificationCenter delegate in AppDelegate.swift

## Error Handling

- Wrap platform-specific calls in try-catch
- Log errors for debugging
- Gracefully handle permission denials

## Testing Considerations

- Service should be injectable via Riverpod for mocking
- Unit tests can mock the FlutterLocalNotificationsPlugin
- Integration tests verify actual notification behavior on device

## Dependencies

Required packages (already in pubspec.yaml):
- `flutter_local_notifications: ^17.2.2`
- `timezone: ^0.9.2` (for scheduled notifications)

Required: Add `timezone: ^0.9.2` to pubspec.yaml (not currently present).