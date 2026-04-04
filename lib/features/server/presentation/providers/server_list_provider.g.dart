// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [ServerRepository] instance backed by Hive.
///
/// Keep-alive so the repository persists for the app's lifetime.

@ProviderFor(serverRepository)
final serverRepositoryProvider = ServerRepositoryProvider._();

/// Provides the [ServerRepository] instance backed by Hive.
///
/// Keep-alive so the repository persists for the app's lifetime.

final class ServerRepositoryProvider
    extends
        $FunctionalProvider<
          ServerRepository,
          ServerRepository,
          ServerRepository
        >
    with $Provider<ServerRepository> {
  /// Provides the [ServerRepository] instance backed by Hive.
  ///
  /// Keep-alive so the repository persists for the app's lifetime.
  ServerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverRepositoryHash();

  @$internal
  @override
  $ProviderElement<ServerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServerRepository create(Ref ref) {
    return serverRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerRepository>(value),
    );
  }
}

String _$serverRepositoryHash() => r'2b53a21d61a287821e8477d6f15db8deea58cf50';

/// Riverpod notifier for the reactive list of saved server configurations.
///
/// Exposes methods to add and delete servers, automatically refreshing
/// the list when changes occur.

@ProviderFor(ServerListNotifier)
final serverListProvider = ServerListNotifierProvider._();

/// Riverpod notifier for the reactive list of saved server configurations.
///
/// Exposes methods to add and delete servers, automatically refreshing
/// the list when changes occur.
final class ServerListNotifierProvider
    extends $AsyncNotifierProvider<ServerListNotifier, List<ServerConfig>> {
  /// Riverpod notifier for the reactive list of saved server configurations.
  ///
  /// Exposes methods to add and delete servers, automatically refreshing
  /// the list when changes occur.
  ServerListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'serverListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$serverListNotifierHash();

  @$internal
  @override
  ServerListNotifier create() => ServerListNotifier();
}

String _$serverListNotifierHash() =>
    r'ed1ba7230b40759cac8f1cd31b7f637eac78d247';

/// Riverpod notifier for the reactive list of saved server configurations.
///
/// Exposes methods to add and delete servers, automatically refreshing
/// the list when changes occur.

abstract class _$ServerListNotifier extends $AsyncNotifier<List<ServerConfig>> {
  FutureOr<List<ServerConfig>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<ServerConfig>>, List<ServerConfig>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<ServerConfig>>, List<ServerConfig>>,
              AsyncValue<List<ServerConfig>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
