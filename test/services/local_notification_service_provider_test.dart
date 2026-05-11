import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_background_task/services/local_notification_service.dart';
import 'package:flutter_background_task/services/local_notification_service_provider.dart';

void main() {
  test('localNotificationServiceProvider should provide LocalNotificationService', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(localNotificationServiceProvider);
    expect(service, isA<LocalNotificationService>());
  });
}