# flutour_background_task

Flutter test project for maintaining socket connections and receiving notifications in background.

## Platform-specific requirements for background tasks

### Android
- `minSdk: 21+` (required for flutter_foreground_tasks)
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

# CRITICAL RULES - MUST FOLLOW

## RESPONSES

- Keep responses concise and to the point - unless the user asks otherwise

## PLANNING MODE

- Always ask clarifying questions
- Never assume design, tech stack or features
- Use deep-dive sub-agents to assist with research
- Use deep-dive sub-agents to review the different aspects of your plan before presenting to the user

## CHANGE / EDIT MODE

- Never implement features yourself when possible - use sub-agents!
- Identify changes from the plan that can be implemented in parallel, and use sub-agents to implement the features efficiently
- When using sub-agents to implement features, act as a coordinator only
- Use the best model for the task - premium models for complex tasks (like coding) and mid-tier models for simpler tasks, like documentation
- After completing features (large or small), always run commands like lint, type check and next build to check code quality
