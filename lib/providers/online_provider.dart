import 'dart:async';

import 'package:flutter_background_task/core/background/foreground_service_manager_interface.dart';
import 'package:flutter_background_task/providers/foreground_service_manager_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'online_provider.g.dart';

@riverpod
class Online extends _$Online {
  static const _prefsKey = 'isOnline';

  late final IForegroundServiceManager _fgManager;

  @override
  AsyncValue<bool> build() {
    _fgManager = ref.read(foregroundServiceManagerProvider);
    init();
    return const AsyncValue.data(false);
  }

  Future<void> init() async {
    state = const AsyncValue.loading();
    try {
      await _fgManager.requestAndroidPermissions();
      final running = await _fgManager.isRunning;
      final prefs = await SharedPreferences.getInstance();
      state = AsyncValue.data(running);
      if (running && !(prefs.getBool(_prefsKey) ?? false)) {
        await set(true);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleOnline() async {
    final currentValue = state.value ?? false;
    state = AsyncValue.loading();

    try {
      if (currentValue) {
        await _stopBackgroundService();
      } else {
        await _startBackgroundService();
      }
      await set(!currentValue);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> set(bool value) async {
    state = AsyncValue.data(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }

  Future<void> _startBackgroundService() async {
    await _fgManager.start();
  }

  Future<void> _stopBackgroundService() async {
    unawaited(_fgManager.stop());
  }
}
