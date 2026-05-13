import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'foreground_service_manager_interface.dart';
import 'foreground_task_handler.dart';

typedef FlutterForegroundTaskInit = void Function();

class ForegroundServiceManager implements IForegroundServiceManager {
  @visibleForTesting
  static FlutterForegroundTaskInit? testInitOverride;

  @override
  Future<void> init() async {
    if (testInitOverride != null) {
      testInitOverride!();
      return;
    }
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'socket_channel',
        channelName: 'Live Connection',
        channelDescription: 'Keeps ride requests active',
        channelImportance: NotificationChannelImportance.DEFAULT,
        playSound: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(10000), // 10s heartbeat
        autoRunOnBoot: true,
      ),
    );
  }

  @override
  Future<bool> get isRunning => FlutterForegroundTask.isRunningService;

  @override
  void initCommunicationPort() => FlutterForegroundTask.initCommunicationPort();

  @override
  Future<void> start() async {
    if (await isRunning) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Waiting for rides',
        notificationText: 'You are online',
        callback: startCallback,
        serviceTypes: [
          ForegroundServiceTypes.dataSync,
        ],
      );
    }
  }

  @override
  Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  @override
  Future<void> requestAndroidPermissions() async {
    // if (!await FlutterForegroundTask.canDrawOverlays) {
    //   await FlutterForegroundTask.openSystemAlertWindowSettings();
    // }

    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }
}
