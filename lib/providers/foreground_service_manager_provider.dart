import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/background/foreground_service_manager_interface.dart';
import '../core/background/foreground_service_manager.dart';

final foregroundServiceManagerProvider = Provider<IForegroundServiceManager>((
  ref,
) {
  return ForegroundServiceManager();
});
