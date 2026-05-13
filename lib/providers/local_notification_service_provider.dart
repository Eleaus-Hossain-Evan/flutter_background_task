import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/notifications/local_notification_service.dart';

part 'local_notification_service_provider.g.dart';

@Riverpod(keepAlive: true)
LocalNotificationService localNotificationService(Ref ref) =>
    LocalNotificationService();
