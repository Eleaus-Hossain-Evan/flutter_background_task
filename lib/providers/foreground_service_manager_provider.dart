import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/background/foreground_service_manager.dart';
import '../core/background/foreground_service_manager_interface.dart';

part 'foreground_service_manager_provider.g.dart';

@riverpod
IForegroundServiceManager foregroundServiceManager(Ref ref) =>
    ForegroundServiceManager();
