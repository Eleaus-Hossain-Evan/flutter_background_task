# Background Service Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a comprehensive background service that maintains a persistent Socket.IO connection and displays local notifications with View/Dismiss actions when server events arrive.

**Architecture:** Centralized service manager pattern where the background isolate handles socket connection and notification display independently from the UI. UI controls service lifecycle via FlutterBackgroundService API. Socket runs in isolated context with aggressive reconnection (5 attempts, 3s interval). All socket events trigger notifications with deep-link navigation capability.

**Tech Stack:** flutter_background_service: ^5.0.10+1, socket_io_client: ^2.0.3+1, flutter_local_notifications: ^17.2.2, hooks_riverpod, shared_preferences

---

## File Structure

```
lib/
├── background/
│   ├── background_service_manager.dart  # NEW - UI control interface
│   ├── background_socket_service.dart   # NEW - Socket.IO in isolate
│   ├── socket_notification_service.dart # NEW - Notification in isolate
│   └── background_service_entry.dart    # MODIFY - Replace existing
├── home/
│   ├── home_screen.dart                 # MODIFY - Toggle integration
│   └── notification_detail_screen.dart  # NEW - Navigation target
├── providers/
│   └── background_service_provider.dart # NEW - Riverpod integration
android/
└── app/src/main/
    └── AndroidManifest.xml              # MODIFY - Permissions
ios/
└── Runner/
    └── Info.plist                       # MODIFY - Background modes
```

---

## Task 1: Create BackgroundSocketService

**Files:**
- Create: `lib/background/background_socket_service.dart`
- Test: `test/background/background_socket_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/background/background_socket_service.dart';

void main() {
  group('BackgroundSocketService', () {
    late BackgroundSocketService service;

    setUp(() {
      service = BackgroundSocketService();
    });

    test('connect should initialize socket with correct config', () {
      service.connect('https://test-server.com');
    });

    test('disconnect should close socket connection', () {
      service.connect('https://test-server.com');
      service.disconnect();
    });

    test('dispose should clean up resources', () {
      service.connect('https://test-server.com');
      service.dispose();
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/background/background_socket_service_test.dart`
Expected: FAIL - file does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef SocketEventCallback = void Function(dynamic data);

class BackgroundSocketService {
  static const String _baseUrl =
      'https://realtime-db-server.techanalyticaltd.com';

  io.Socket? _socket;
  final _eventController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController =
      StreamController<bool>.broadcast();

  SocketEventCallback? onConnected;
  SocketEventCallback? onDisconnected;
  SocketEventCallback? onError;

  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<bool> get connectionStateStream =>
      _connectionStateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect([String? url]) {
    final serverUrl = url ?? _baseUrl;

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setReconnectionAttempts(5)
          .setReconnectionDelay(3000)
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      developer.log('Socket connected', name: 'BackgroundSocketService');
      _connectionStateController.add(true);
      onConnected?.call(null);
    });

    _socket!.onDisconnect((_) {
      developer.log('Socket disconnected', name: 'BackgroundSocketService');
      _connectionStateController.add(false);
      onDisconnected?.call(null);
    });

    _socket!.onReconnect((attempt) {
      developer.log(
        'Socket reconnecting... attempt $attempt',
        name: 'BackgroundSocketService',
      );
    });

    _socket!.onConnectError((error) {
      developer.log(
        'Socket connection error: $error',
        name: 'BackgroundSocketService',
        level: 1000,
      );
      onError?.call(error);
    });

    _socket!.onError((error) {
      developer.log(
        'Socket error: $error',
        name: 'BackgroundSocketService',
        level: 1000,
      );
      onError?.call(error);
    });

    _socket!.on('event', (data) {
      developer.log(
        'Received socket event: $data',
        name: 'BackgroundSocketService',
      );
      if (data is Map<String, dynamic>) {
        _eventController.add(data);
      } else if (data != null) {
        _eventController.add({'data': data});
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void dispose() {
    _socket?.clearListeners();
    _socket?.close();
    _socket?.dispose();
    _socket = null;
    _eventController.close();
    _connectionStateController.close();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/background/background_socket_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/background/background_socket_service.dart test/background/background_socket_service_test.dart
git commit -m "feat: add BackgroundSocketService for isolate-scoped socket management"
```

---

## Task 2: Create SocketNotificationService

**Files:**
- Create: `lib/background/socket_notification_service.dart`
- Test: `test/background/socket_notification_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/background/socket_notification_service.dart';

void main() {
  group('SocketNotificationService', () {
    late SocketNotificationService service;

    setUp(() async {
      service = SocketNotificationService();
      await service.initialize();
    });

    tearDown(() {
      service.dispose();
    });

    test('initialize should setup notification channel', () async {
    });

    test('showEventNotification should display notification', () async {
      await service.showEventNotification(
        title: 'Test Title',
        body: 'Test Body',
        payload: '{"id": "123"}',
      );
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/background/socket_notification_service_test.dart`
Expected: FAIL - file does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class SocketNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  int _notificationIdCounter = 0;

  static const String _channelId = 'socket_events';
  static const String _channelName = 'Socket Events';
  static const String _channelDescription =
      'Notifications from background socket events';

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinSettings = DarwinInitializationSettings(
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

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    await _createAndroidChannel();

    _isInitialized = true;
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
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/background/socket_notification_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/background/socket_notification_service.dart test/background/socket_notification_service_test.dart
git commit -m "feat: add SocketNotificationService for isolate-scoped notifications"
```

---

## Task 3: Create BackgroundServiceEntry (Isolate Entry Point)

**Files:**
- Create: `lib/background/background_service_entry.dart` (replace existing)

- [ ] **Step 1: Write new isolate entry point**

```dart
import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'background_socket_service.dart';
import 'socket_notification_service.dart';

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = SocketNotificationService();
  await notificationService.initialize();

  final socketService = BackgroundSocketService();

  socketService.onConnected = (data) {
    service.invoke('onConnected', {'status': 'connected'});
  };

  socketService.onDisconnected = (data) {
    service.invoke('onDisconnected', {'status': 'disconnected'});
  };

  socketService.onError = (data) {
    service.invoke('onError', {'error': data?.toString() ?? 'unknown'});
  };

  socketService.eventStream.listen((event) async {
    final title = event['title']?.toString() ?? 'New Event';
    final body = event['body']?.toString() ??
        event['message']?.toString() ??
        'You have a new notification';
    final payload = event.toString();

    await notificationService.showEventNotification(
      title: title,
      body: body,
      payload: payload,
    );

    service.invoke('onEvent', event);
  });

  socketService.connect();

  service.on('stopService').listen((event) {
    socketService.dispose();
    notificationService.dispose();
    service.stopSelf();
  });

  service.on('reconnect').listen((event) {
    if (!socketService.isConnected) {
      socketService.disconnect();
      socketService.connect();
    }
  });

  service.on('checkStatus').listen((event) {
    service.invoke(
      'status',
      {
        'isConnected': socketService.isConnected,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  });
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'socket_events',
    'Socket Events',
    description: 'Background socket notification channel',
    importance: Importance.max,
  );

  final flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'socket_events',
      initialNotificationTitle: 'Background Service',
      initialNotificationContent: 'Running...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}
```

- [ ] **Step 2: Update main.dart import**

Modify `lib/main.dart`:
```dart
import 'background/background_service_entry.dart' show initializeBackgroundService;
```

- [ ] **Step 3: Run flutter analyze**
Run: `flutter analyze`
Expected: No errors

- [ ] **Step 4: Commit**
```bash
git add lib/background/background_service_entry.dart lib/main.dart
git commit -m "feat: replace background_entry with centralized BackgroundServiceEntry"
```

---

## Task 4: Create BackgroundServiceManager

**Files:**
- Create: `lib/background/background_service_manager.dart`
- Test: `test/background/background_service_manager_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/background/background_service_manager.dart';

void main() {
  group('BackgroundServiceManager', () {
    late BackgroundServiceManager manager;

    setUp(() {
      manager = BackgroundServiceManager();
    });

    test('isRunning should return false when service not started', () async {
      final result = await manager.isRunning();
    });

    test('startService should configure service', () async {
      await manager.startService();
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**
Run: `flutter test test/background/background_service_manager_test.dart`
Expected: FAIL - file does not exist

- [ ] **Step 3: Write minimal implementation**

```dart
import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundServiceManager {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> startService() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      await _service.start();
    }
  }

  Future<void> stopService() async {
    await _service.invoke('stopService');
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  Stream<Map<String, dynamic>?> get onServiceEvent {
    return _service.on('event');
  }

  Stream<Map<String, dynamic>?> get onServiceConnect {
    return _service.on('onConnected');
  }

  Stream<Map<String, dynamic>?> get onServiceDisconnect {
    return _service.on('onDisconnected');
  }
}
```

- [ ] **Step 4: Run test to verify it passes**
Run: `flutter test test/background/background_service_manager_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**
```bash
git add lib/background/background_service_manager.dart test/background/background_service_manager_test.dart
git commit -m "feat: add BackgroundServiceManager for UI control"
```

---

## Task 5: Create BackgroundServiceProvider (Riverpod Integration)

**Files:**
- Create: `lib/providers/background_service_provider.dart`

- [ ] **Step 1: Write the provider implementation**

```dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../background/background_service_manager.dart';
import '../models/notification_model.dart';

part 'background_service_provider.g.dart';

final backgroundServiceManagerProvider =
    Provider<BackgroundServiceManager>((ref) {
  return BackgroundServiceManager();
});

@riverpod
class BackgroundService extends _$BackgroundService {
  static const _pendingNotificationKey = 'pending_notification';

  @override
  bool build() => false;

  Future<void> startService() async {
    final manager = ref.read(backgroundServiceManagerProvider);
    await manager.startService();
    state = true;
  }

  Future<void> stopService() async {
    final manager = ref.read(backgroundServiceManagerProvider);
    await manager.stopService();
    state = false;
  }

  Future<bool> isServiceRunning() async {
    final manager = ref.read(backgroundServiceManagerProvider);
    return await manager.isRunning();
  }

  Future<void> checkPendingNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(_pendingNotificationKey);

    if (pendingJson != null && pendingJson.isNotEmpty) {
      try {
        final data = jsonDecode(pendingJson);
        final notification = NotificationModel.fromMap(data);

        prefs.remove(_pendingNotificationKey);

        ref.read(pendingNotificationProvider.notifier).state = notification;
      } catch (e) {
        prefs.remove(_pendingNotificationKey);
      }
    }
  }

  Future<void> storePendingNotification(NotificationModel notification) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingNotificationKey, notification.toJson());
  }
}

final pendingNotificationProvider =
    StateProvider<NotificationModel?>((ref) => null);
```

- [ ] **Step 2: Run code generation**
Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: `background_service_provider.g.dart` created

- [ ] **Step 3: Run flutter analyze**
Run: `flutter analyze`
Expected: No errors

- [ ] **Step 4: Commit**
```bash
git add lib/providers/background_service_provider.dart lib/providers/background_service_provider.g.dart
git commit -m "feat: add BackgroundServiceProvider for Riverpod integration"
```

---

## Task 6: Create NotificationDetailScreen

**Files:**
- Create: `lib/home/notification_detail_screen.dart`

- [ ] **Step 1: Write the screen implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/background_service_provider.dart';
import '../models/notification_model.dart';

class NotificationDetailScreen extends ConsumerWidget {
  final NotificationModel? initialNotification;

  const NotificationDetailScreen({
    super.key,
    this.initialNotification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingNotification = ref.watch(pendingNotificationProvider);
    final notification = initialNotification ?? pendingNotification;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Details'),
      ),
      body: notification == null
          ? const Center(child: Text('No notification data'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.data.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${notification.data.type}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notification.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Timestamp: ${notification.timestamp.toIso8601String()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (notification.data.data.hello.isNotEmpty)
                    Text(
                      'Data: ${notification.data.data.hello}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**
Run: `flutter analyze`
Expected: No errors

- [ ] **Step 3: Commit**
```bash
git add lib/home/notification_detail_screen.dart
git commit -m "feat: add NotificationDetailScreen for notification navigation"
```

---

## Task 7: Update HomeScreen

**Files:**
- Modify: `lib/home/home_screen.dart`

- [ ] **Step 1: Update HomeScreen with service integration**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/online_provider.dart';
import '../providers/background_service_provider.dart';
import 'notification_detail_screen.dart';
import '../models/notification_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingNotification();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPendingNotification();
    }
  }

  Future<void> _checkPendingNotification() async {
    await ref.read(backgroundServiceProvider.notifier).checkPendingNotification();
    final pending = ref.read(pendingNotificationProvider);
    if (pending != null && mounted) {
      _navigateToDetail(pending);
    }
  }

  void _navigateToDetail(NotificationModel notification) {
    ref.read(pendingNotificationProvider.notifier).state = null;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(
          initialNotification: notification,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(onlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Switch(
            value: isOnline,
            onChanged: (value) async {
              await ref.read(onlineProvider.notifier).set(value);
              if (value) {
                await ref.read(backgroundServiceProvider.notifier).startService();
              } else {
                await ref.read(backgroundServiceProvider.notifier).stopService();
              }
            },
          ),
          const Text('Go Online', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run flutter analyze**
Run: `flutter analyze`
Expected: No errors

- [ ] **Step 3: Commit**
```bash
git add lib/home/home_screen.dart
git commit -m "feat: update HomeScreen to control background service"
```

---

## Task 8: Update Android Manifest

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Update AndroidManifest.xml** - Replace content with:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_DATA_SYNC"/>
    <uses-permission android:name="android.permission.WAKE_LOCK"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    
    <application
        android:label="flutter_background_task"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
        <service
            android:name="id.flutter.flutter_background_service.BackgroundService"
            android:foregroundServiceType="dataSync"
            android:exported="false"
            android:stopWithTask="false" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT"/>
            <data android:mimeType="text/plain"/>
        </intent>
    </queries>
</manifest>
```

- [ ] **Step 2: Commit**
```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "chore: update AndroidManifest with background service permissions"
```

---

## Task 9: Update iOS Info.plist

**Files:**
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: Update Info.plist** - Add after `<dict>` opening tag:

```xml
	<key>UIBackgroundModes</key>
	<array>
		<string>fetch</string>
		<string>remote-notification</string>
		<string>processing</string>
	</array>
```

- [ ] **Step 2: Commit**
```bash
git add ios/Runner/Info.plist
git commit -m "chore: update Info.plist with background modes"
```

---

## Task 10: Build Verification

- [ ] **Step 1: Run flutter pub get**
Run: `flutter pub get`
Expected: Dependencies resolved

- [ ] **Step 2: Run flutter analyze**
Run: `flutter analyze`
Expected: No errors or warnings

- [ ] **Step 3: Build Android APK**
Run: `flutter build apk --debug`
Expected: APK built successfully

- [ ] **Step 4: Build iOS for simulator**
Run: `flutter build ios --simulator --no-codesign`
Expected: iOS build successful

- [ ] **Step 5: Final commit**
```bash
git add -A
git commit -m "chore: verify builds for Android and iOS"
```

---

## Task 11: Clean Up and Remove Old Files

**Files to remove:**
- `lib/background/background_entry.dart`
- `lib/services/socket_service.dart`
- `lib/services/socket_service_provider.dart`
- `lib/providers/socket_connection_provider.dart`
- `lib/providers/local_notification_service_provider.dart`
- `lib/services/local_notification_service.dart`
- `lib/services/socket_service_provider.g.dart`
- `lib/providers/socket_connection_provider.g.dart`

- [ ] **Step 1: Remove old files**

```bash
rm lib/background/background_entry.dart lib/services/socket_service.dart lib/services/socket_service_provider.dart lib/providers/socket_connection_provider.dart lib/providers/local_notification_service_provider.dart lib/services/local_notification_service.dart lib/services/socket_service_provider.g.dart lib/providers/socket_connection_provider.g.dart
```

- [ ] **Step 2: Run flutter analyze**
Run: `flutter analyze`
Expected: No errors

- [ ] **Step 3: Commit cleanup**
```bash
git add -A
git commit -m "refactor: remove old service files replaced by background services"
```

---

## Self-Review Checklist

1. **Spec coverage:** All spec requirements implemented
2. **Placeholder scan:** No placeholders found
3. **Type consistency:** All types match across tasks

