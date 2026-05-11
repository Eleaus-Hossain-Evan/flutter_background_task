# Implementation Plan – Persistent Socket + Background Service + Local Notifications (Riverpod‑generated)

---

## 1️⃣ Project‑wide Preparation

| Action | Detail |
|--------|--------|
| **Dependencies** | Ensure `pubspec.yaml` contains:
```yaml
dependencies:
  socket_io_client: ^2.0.3+1
  flutter_background_service: ^5.1.0
  flutter_local_notifications: ^17.2.2
  riverpod_annotation: ^4.0.2

dev_dependencies:
  riverpod_generator: ^4.0.3
  build_runner: ^2.13.1
```
| **Fetch** | Run `flutter pub get`. |
| **Imports (reference only)** | Add to `lib/main.dart`:
```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'core/notification_service.dart';
```
---

## 2️⃣ Riverpod Code‑Generation

| Provider | File | Key Code |
|---------|------|----------|
| **OnlineProvider** (bool) | `lib/providers/online_provider.dart` | ```dart
@riverpod
class Online extends _$Online {
  @override
  bool build() => false; // default offline
}
``` |
| **AppLifecycleProvider** (AppLifecycleState) | `lib/providers/app_lifecycle_provider.dart` | ```dart
@riverpod
class AppLifecycle extends _$AppLifecycle {
  @override
  AppLifecycleState build() => AppLifecycleState.resumed;
  void set(AppLifecycleState state) => state = state;
}
``` |
| **SocketProvider** (AsyncNotifier) | `lib/providers/socket_provider.dart` | *Watches `onlineProvider` and `appLifecycleProvider`.* Calls `FlutterBackgroundService` to `connect`, `disconnect`, and `setForeground`. |
| **SocketEventProvider** (optional UI holder) | `lib/providers/socket_event_provider.dart` | ```dart
@riverpod
class SocketEvent extends _$SocketEvent {
  @override
  SocketEvent? build() => null; // holds latest event
}
``` |

After creating the abstract classes run code‑generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
---

## 3️⃣ Notification Service – **Initialized in `main.dart`**

**File:** `lib/core/notification_service.dart`
```dart
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'socket_event.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings android = AndroidInitializationSettings('app_icon');
    const DarwinInitializationSettings iOS = DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: android,
      iOS: iOS,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final data = jsonDecode(response.payload ?? '');
        // TODO: navigate using a global navigator key or Riverpod router
      },
    );
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestPermission();
  }

  static Future<void> show(SocketEvent event) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'socket_channel',
      'Socket Events',
      channelDescription: 'Incoming socket messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      event.id.hashCode,
      event.title,
      event.body,
      details,
      payload: jsonEncode(event),
    );
  }
}
```
- Called from `main.dart` **before** `runApp`.
- Also called inside the background isolate (`_onStart`).
---

## 4️⃣ Background Service (flutter_background_service)

**File:** `lib/core/background_service.dart`
```dart
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'socket_service.dart';          // thin wrapper around socket_io_client
import 'notification_service.dart';
import 'socket_event.dart';

class BackgroundService {
  static Future<void> configure() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        autoStart: false, // start only when online
        onStart: _onStart,
        isForegroundMode: false,
        foregroundServiceNotificationId: 888,
        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Socket Service',
        initialNotificationContent: 'Initializing…',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }
}

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  final socket = SocketService();

  // UI → service commands
  service.on('connect').listen((_) async => await socket.connect());
  service.on('disconnect').listen((_) async => await socket.disconnect());
  service.on('setForeground').listen((event) async {
    final foreground = event! as bool;
    if (service is AndroidServiceInstance) {
      await service.setForegroundMode(foreground);
    }
  });

  // Socket events → UI + notification
  socket.onEvent((SocketEvent ev) async {
    await NotificationService.show(ev);
    await service.invoke('socketEvent', jsonEncode(ev));
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Re‑connect if needed, process pending events – max ~30 s window.
  return true;
}
```
- The **single socket lives in this isolate** – guarantees one persistent connection.
- UI interacts via `service.invoke('connect')`, `...('disconnect')`, and `...('setForeground', true/false)`.
- Events are sent back with `service.invoke('socketEvent', ...)` which the `SocketProvider` listens to.
---

## 5️⃣ UI Adjustments

### 5.1 `main.dart` – bootstrap order
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ initialise notifications (must be first)
  await NotificationService.initialize();

  // 2️⃣ configure background service (does NOT start it yet)
  await BackgroundService.configure();

  runApp(const ProviderScope(child: MyApp()));
}
```

### 5.2 `HomeScreen` (HookConsumerWidget)
```dart
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(onlineProvider);
    final latest = ref.watch(socketEventProvider);

    // Ask for notification permission once
    useEffect(() {
      NotificationService.requestPermission();
      return null;
    }, const []);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Switch(
            value: online,
            onChanged: (value) => ref.read(onlineProvider.notifier).state = value,
          ),
          const Text('Go Online', textAlign: TextAlign.center),
          if (latest != null) ...[
            const SizedBox(height: 20),
            Text('Last event: ${latest.title}', textAlign: TextAlign.center),
            Text(latest.body, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
```
- The Switch now directly toggles `onlineProvider`.
- Latest socket payload is displayed via `socketEventProvider`.

### 5.3 App‑Lifecycle observer (optional, to feed `appLifecycleProvider`)
```dart
class LifecycleWatcher extends StatefulWidget {
  final Widget child;
  const LifecycleWatcher({required this.child, super.key});
  @override
  State<LifecycleWatcher> createState() => _LifecycleWatcherState();
}

class _LifecycleWatcherState extends State<LifecycleWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).set(state);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```
Wrap `MyApp` with `LifecycleWatcher` so the provider receives `paused`/`resumed` events.
---

## 6️⃣ Platform‑Specific Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<application ...>
    <service
        android:name="id.flutter.flutter_background_service.BackgroundService"
        android:exported="false"
        android:foregroundServiceType="dataSync|mediaPlayback|location" />
</application>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
</array>
```

### iOS AppDelegate (`ios/Runner/AppDelegate.swift`)
```swift
import UIKit
import Flutter
import flutter_background_service_ios

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    SwiftFlutterBackgroundServicePlugin.taskIdentifier = "com.example.socketTask"
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```
---

## 7️⃣ Build & Verification Checklist (no tests required)
1. **Compile** for Android & iOS (`flutter build apk`, `flutter build ios`).
2. **Run** the app in debug mode.
3. **Toggle “Go Online”** – confirm socket connects (look at console logs).
4. **Background** the app while online – a persistent foreground notification appears on Android; iOS relies on background‑fetch.
5. **Trigger a server event** (via your Socket.io server). Verify:
   - A local notification pops up.
   - Tapping the notification re‑opens the app with the event displayed.
6. **Return to foreground** – foreground‑service notification disappears but the socket stays connected.
7. **Toggle Offline** – socket disconnects, background service stops, no further notifications.
8. **Permission flow** – on Android 13+ the user is prompted for notification permission; refusing does not crash.
---

## 8️⃣ Timeline (estimated effort)
| Phase | Approx. time |
|------|--------------|
| Dependencies & fetch | 5 min |
| Add Riverpod providers + generate | 20 min |
| NotificationService implementation | 10 min |
| BackgroundService implementation | 20 min |
| UI updates (main, HomeScreen, lifecycle observer) | 15 min |
| Platform manifest / Info.plist edits | 5 min |
| Build & functional verification | 15 min |
| Documentation/comments | 5 min |
| **Total** | **≈ 1.5 h** |
---

**End of Plan**
