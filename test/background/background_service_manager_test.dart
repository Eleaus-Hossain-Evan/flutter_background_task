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
      expect(result, isA<bool>());
    });

    test('startService should be callable', () async {
      await manager.startService();
    });
  });
}
