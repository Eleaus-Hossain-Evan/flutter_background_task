import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_background_task/providers/online_provider.dart';
import 'package:flutter_background_task/core/background/foreground_service_manager_interface.dart';
import 'package:flutter_background_task/providers/foreground_service_manager_provider.dart';

class MockFgManager extends Mock implements IForegroundServiceManager {}

void main() {
  test('Online provider uses injected IForegroundServiceManager', () async {
    final mockMgr = MockFgManager();
    when(() => mockMgr.isRunning).thenAnswer((_) async => false);
    when(() => mockMgr.start()).thenAnswer((_) async => {});
    when(() => mockMgr.requestAndroidPermissions()).thenAnswer((_) async => {});

    final container = ProviderContainer(
      overrides: [
        foregroundServiceManagerProvider.overrideWithValue(mockMgr),
      ],
    );
    addTearDown(() => container.dispose());

    final notifier = container.read(onlineProvider.notifier);
    await notifier.toggleOnline();

    verify(() => mockMgr.start()).called(1);
  });
}
