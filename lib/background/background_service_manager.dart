import 'package:flutter_background_service/flutter_background_service.dart';

class BackgroundServiceManager {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<bool> startService() async {
    final isRunning = await _service.isRunning();
    if (!isRunning) {
      _service.start();
    }
    return await _service.isRunning();
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
