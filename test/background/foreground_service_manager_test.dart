import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_background_task/core/background/foreground_service_manager.dart';

void main() {
  group('ForegroundServiceManager', () {
    test('init calls FlutterForegroundTask.init', () async {
      var called = false;
      ForegroundServiceManager.testInitOverride = () {
        called = true;
      };
      await ForegroundServiceManager().init();
      expect(called, isTrue);
    });
  });
}
