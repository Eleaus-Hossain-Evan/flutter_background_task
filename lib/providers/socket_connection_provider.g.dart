// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'socket_connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SocketConnection)
final socketConnectionProvider = SocketConnectionProvider._();

final class SocketConnectionProvider
    extends $AsyncNotifierProvider<SocketConnection, bool> {
  SocketConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socketConnectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socketConnectionHash();

  @$internal
  @override
  SocketConnection create() => SocketConnection();
}

String _$socketConnectionHash() => r'96b341e5923694e997c15f0669269a1334cd664e';

abstract class _$SocketConnection extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
