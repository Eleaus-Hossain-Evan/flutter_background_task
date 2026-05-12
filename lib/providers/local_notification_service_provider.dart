import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/local_notification_service.dart';

part 'local_notification_service_provider.g.dart';

@Riverpod(keepAlive: true)
LocalNotificationService localNotificationService(Ref ref) =>
    LocalNotificationService();
