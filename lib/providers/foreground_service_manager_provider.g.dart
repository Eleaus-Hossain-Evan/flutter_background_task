// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'foreground_service_manager_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(foregroundServiceManager)
final foregroundServiceManagerProvider = ForegroundServiceManagerProvider._();

final class ForegroundServiceManagerProvider
    extends
        $FunctionalProvider<
          IForegroundServiceManager,
          IForegroundServiceManager,
          IForegroundServiceManager
        >
    with $Provider<IForegroundServiceManager> {
  ForegroundServiceManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foregroundServiceManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foregroundServiceManagerHash();

  @$internal
  @override
  $ProviderElement<IForegroundServiceManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IForegroundServiceManager create(Ref ref) {
    return foregroundServiceManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IForegroundServiceManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IForegroundServiceManager>(value),
    );
  }
}

String _$foregroundServiceManagerHash() =>
    r'e3779ee1f67243ecfd20f1309ef63f286ef53827';
