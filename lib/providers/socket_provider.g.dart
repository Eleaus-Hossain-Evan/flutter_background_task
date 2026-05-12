// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socket_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(socketService)
final socketServiceProvider = SocketServiceProvider._();

final class SocketServiceProvider
    extends $FunctionalProvider<SocketService, SocketService, SocketService>
    with $Provider<SocketService> {
  SocketServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socketServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socketServiceHash();

  @$internal
  @override
  $ProviderElement<SocketService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SocketService create(Ref ref) {
    return socketService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocketService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocketService>(value),
    );
  }
}

String _$socketServiceHash() => r'9944a3374ccaefb72233cbb549d95b00a467345e';

@ProviderFor(socketEvent)
final socketEventProvider = SocketEventProvider._();

final class SocketEventProvider
    extends
        $FunctionalProvider<
          AsyncValue<SocketEvent>,
          SocketEvent,
          Stream<SocketEvent>
        >
    with $FutureModifier<SocketEvent>, $StreamProvider<SocketEvent> {
  SocketEventProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socketEventProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socketEventHash();

  @$internal
  @override
  $StreamProviderElement<SocketEvent> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SocketEvent> create(Ref ref) {
    return socketEvent(ref);
  }
}

String _$socketEventHash() => r'64293b02a35a7880dc91b97343976b9ea8d6ae4a';
