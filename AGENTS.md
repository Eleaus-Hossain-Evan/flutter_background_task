# flutour_background_task

Flutter test project for maintaining socket connections and receiving notifications in background.

## Platform-specific requirements for background tasks

### Android
- `minSdk: 21+` (required for WorkManager/background services)
- `targetSdk: flutter.targetSdkVersion` (check pubspec: 34)
- Add background service permissions to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.WAKE_LOCK" />
  ```

### iOS
- Modify `ios/Runner/Info.plist` to enable background capabilities:
  ```xml
  <key>UIBackgroundModes</key>
  <array>
    <string>fetch</string>
    <string>remote-notification</string>
    <string>processing</string>
  </array>
  ```
- Enable background task assertions in Xcode Signing & Capabilities

## Common commands

```bash
# Run app (debug)
flutter run

# Run app (release with debug signing)
flutter run --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Clean build artifacts
flutter clean && flutter pub get
```

## Key files to update for socket background functionality

- `lib/main.dart` - main application entry
- `android/app/src/main/kotlin/.../MainActivity.kt` - Add code to initialize background service
- `ios/Runner/AppDelegate.swift` - Handle background events
- `ios/Runner/Info.plist` - Add background modes (see above)
- `android/app/src/main/AndroidManifest.xml` - Add permissions and service declarations

## Note

This is a test project - dependencies for socket/background tasks will need to be added via `pubspec.yaml`.