import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'online_provider.g.dart';

@riverpod
class Online extends _$Online {
  static const _prefsKey = 'isOnline';

  @override
  bool build() {
    return false;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}