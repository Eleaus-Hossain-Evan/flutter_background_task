// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'online_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Online)
final onlineProvider = OnlineProvider._();

final class OnlineProvider extends $NotifierProvider<Online, AsyncValue<bool>> {
  OnlineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onlineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onlineHash();

  @$internal
  @override
  Online create() => Online();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<bool> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<bool>>(value),
    );
  }
}

String _$onlineHash() => r'b12e3a8237dd7f8ee40a13a5be043c7a084e8b94';

abstract class _$Online extends $Notifier<AsyncValue<bool>> {
  AsyncValue<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, AsyncValue<bool>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, AsyncValue<bool>>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
