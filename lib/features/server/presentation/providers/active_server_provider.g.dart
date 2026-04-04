// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'active_server_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier for tracking the currently active/selected server.
///
/// Persists the active server ID in SharedPreferences and resolves
/// the full [ServerConfig] from the server list.

@ProviderFor(ActiveServerNotifier)
final activeServerProvider = ActiveServerNotifierProvider._();

/// Riverpod notifier for tracking the currently active/selected server.
///
/// Persists the active server ID in SharedPreferences and resolves
/// the full [ServerConfig] from the server list.
final class ActiveServerNotifierProvider
    extends $NotifierProvider<ActiveServerNotifier, ServerConfig?> {
  /// Riverpod notifier for tracking the currently active/selected server.
  ///
  /// Persists the active server ID in SharedPreferences and resolves
  /// the full [ServerConfig] from the server list.
  ActiveServerNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeServerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeServerNotifierHash();

  @$internal
  @override
  ActiveServerNotifier create() => ActiveServerNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerConfig? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerConfig?>(value),
    );
  }
}

String _$activeServerNotifierHash() =>
    r'3db8fa0b645943050e507d739a2ba1dad6b64d4e';

/// Riverpod notifier for tracking the currently active/selected server.
///
/// Persists the active server ID in SharedPreferences and resolves
/// the full [ServerConfig] from the server list.

abstract class _$ActiveServerNotifier extends $Notifier<ServerConfig?> {
  ServerConfig? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ServerConfig?, ServerConfig?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ServerConfig?, ServerConfig?>,
              ServerConfig?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
