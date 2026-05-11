# Background Service Design Specification

**Date:** 2026-05-12  
**Project:** flutter_background_task  
**Feature:** Comprehensive BackgroundService with Socket.IO and Local Notifications

---

## 1. Overview

A background service that maintains a persistent Socket.IO connection and displays local notifications when server events arrive. The service starts/stops based on user toggle (online/offline).

### 1.1 Requirements Summary

| Requirement | Value |
|-------------|-------|
| Socket persistence | Keep-alive while service is running |
| Reconnection | Aggressive (5 attempts, 3s interval) |
| Notifications | All socket events trigger notifications |
| Notification actions | View (navigate) + Dismiss |
| Target navigation | NotificationDetailScreen |
| Service control | Start/stop with user toggle |
| Status UI | None (silent service) |

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         UI Layer                           │
│  ┌──────────────┐  ┌───────────────────┐  ┌─────────────┐   │
│  │  HomeScreen │  │NotificationDetailScreen│ │OnlineToggle│   │
│  └──────────────┘  └───────────────────┘  └─────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Riverpod Providers                        │
│  ┌──────────────────────────────┐                         │
│  │ backgroundServiceProvider    │                         │
│  │ (controls start/stop)         │                         │
│  └──────────────────────────────┘                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           FlutterBackgroundService (Isolate)               │
│  ┌──────────────────┐  ┌───────────────────┐               │
│  │ BackgroundSocket │  │ SocketNotification │               │
│  │    Service       │  │    Service        │               │
│  │ (Socket.IO)      │  │ (LocalNotif)      │               │
│  └──────────────────┘  └───────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Components

### 3.1 BackgroundServiceManager

**File:** `lib/background/background_service_manager.dart`

**Purpose:** Controls service lifecycle from UI via Riverpod provider.

**Interface:**
```dart
class BackgroundServiceManager {
  Future<void> startService();
  Future<void> stopService();
  Future<bool> isRunning();
}
```

### 3.2 BackgroundSocketService

**File:** `lib/background/background_socket_service.dart`

**Purpose:** Manages Socket.IO connection in isolate.

**Configuration:**
```dart
static const baseUrl = 'https://realtime-db-server.techanalyticaltd.com';

socket = io.io(
  baseUrl,
  io.OptionBuilder()
    .setTransports(['websocket'])
    .setReconnectionAttempts(5)
    .setReconnectionDelay(3000)
    .enableAutoConnect()
    .build(),
);
```

**Callbacks:**
- `onConnected` → logs connection
- `onDisconnected` → logs disconnection
- `onEvent(data)` → forwards to notification service
- `onConnectError` → logs error

### 3.3 SocketNotificationService

**File:** `lib/background/socket_notification_service.dart`

**Purpose:** Displays notifications from socket events.

**Notification Config:**
- Channel ID: `socket_events`
- Channel Name: `Socket Events`
- Importance: Maximum
- Actions: View, Dismiss

**Methods:**
```dart
Future<void> initialize();
Future<void> showEventNotification({
  required String title,
  required String body,
  required String payload,
});
Future<void> cancelAll();
```

### 3.4 BackgroundServiceEntry

**File:** `lib/background/background_service_entry.dart`

**Purpose:** Isolate entry point for `onStart` callback.

**Responsibilities:**
1. Initialize `SocketNotificationService`
2. Create and connect `BackgroundSocketService`
3. Listen for socket events → trigger notifications
4. Handle `stopService` command from UI
5. Handle `checkStatus` command for status polling

**No Riverpod dependency** — creates isolated instances.

---

## 4. Data Flow

### 4.1 Service Start Flow

```
User toggles Online ON
        │
        ▼
backgroundServiceProvider.start()
        │
        ▼
FlutterBackgroundService.start()
        │
        ▼
onStart() fires in isolate
        │
        ▼
Initialize SocketNotificationService
        │
        ▼
Create BackgroundSocketService
        │
        ▼
Socket connects automatically
```

### 4.2 Event Notification Flow

```
Server sends socket event
        │
        ▼
BackgroundSocketService.onEvent()
        │
        ▼
BackgroundServiceEntry receives event
        │
        ▼
SocketNotificationService.showEventNotification()
        │
        ▼
Notification displayed with View/Dismiss actions
```

### 4.3 Navigation Flow

```
User taps "View" action
        │
        ▼
FlutterLocalNotificationsPlugin handles action
        │
        ▼
onDidReceiveNotificationResponse callback
        │
        ▼
Store notification data in SharedPreferences
        │
        ▼
App navigates to NotificationDetailScreen
```

---

## 5. File Structure

```
lib/
├── background/
│   ├── background_service_entry.dart     # Isolate entry point
│   ├── background_socket_service.dart    # Socket.IO management
│   ├── socket_notification_service.dart  # Notification display
│   └── background_service_manager.dart   # UI control interface
├── home/
│   ├── home_screen.dart                  # Toggle UI
│   └── notification_detail_screen.dart  # Navigation target
├── providers/
│   └── background_service_provider.dart  # Riverpod integration
└── main.dart
```

---

## 6. Platform Configuration

### 6.1 Android

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

<service
    android:name="id.flutter.flutter_background_service.BackgroundService"
    android:foregroundServiceType="dataSync"
    android:exported="false"
    android:stopWithTask="false"/>
```

### 6.2 iOS

**File:** `ios/Runner/Info.plist`

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
```

---

## 7. Error Handling

| Scenario | Behavior |
|----------|----------|
| Socket connection fails | Auto-retry 5 times with 3s intervals |
| All retries exhausted | Stop reconnecting, service continues running |
| Notification permission denied | Log warning, continue without notifications |
| Service killed by OS | Android: restart automatically |
| Network changes | Socket auto-reconnects via built-in reconnection |

---

## 8. Notification Specification

### 8.1 Channel Configuration

**Android:**
- ID: `socket_events`
- Name: `Socket Events`
- Importance: Maximum
- Description: Notifications from background socket events

**iOS:**
- Category: `socket_notification`
- Interruption Level: Active

### 8.2 Notification Actions

| Action ID | Label | Behavior |
|-----------|-------|----------|
| `view_action` | View | Opens app to NotificationDetailScreen |
| `dismiss_action` | Dismiss | Closes notification |

### 8.3 Payload Structure

```json
{
  "id": "unique_event_id",
  "title": "Event Title",
  "body": "Event Body",
  "timestamp": "2026-05-12T10:30:00Z",
  "data": {}
}
```

---

## 9. Service Configuration

### 9.1 AndroidConfiguration

```dart
AndroidConfiguration(
  onStart: onStart,
  autoStart: false,           // Start only when user toggles online
  isForegroundMode: true,     // Keep service alive
  notificationChannelId: 'socket_events',
  initialNotificationTitle: 'Background Service',
  initialNotificationContent: 'Running...',
  foregroundServiceNotificationId: 888,
)
```

### 9.2 iOSConfiguration

```dart
IosConfiguration(
  autoStart: false,
  onForeground: onStart,
  onBackground: onIosBackground,
)
```

---

## 10. Implementation Notes

1. **Isolate Isolation**: Background service runs in separate isolate. Do NOT use Riverpod providers from main app — create standalone instances.

2. **Reconnection**: Use `socket_io_client` built-in reconnection with:
   - `setReconnectionAttempts(5)`
   - `setReconnectionDelay(3000)`

3. **Memory Management**: Dispose services properly on `stopService` command.

4. **Notification IDs**: Use timestamp-based IDs to ensure uniqueness.

5. **Deep Linking**: Store pending notification payload in SharedPreferences for navigation after app resumes.