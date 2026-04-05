// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'best_server_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Auto-select the best server based on latency (D-16).
/// Reactive provider: re-evaluates whenever latency data changes.

@ProviderFor(bestServer)
final bestServerProvider = BestServerFamily._();

/// Auto-select the best server based on latency (D-16).
/// Reactive provider: re-evaluates whenever latency data changes.

final class BestServerProvider
    extends $FunctionalProvider<ServerConfig?, ServerConfig?, ServerConfig?>
    with $Provider<ServerConfig?> {
  /// Auto-select the best server based on latency (D-16).
  /// Reactive provider: re-evaluates whenever latency data changes.
  BestServerProvider._({
    required BestServerFamily super.from,
    required List<ServerConfig> super.argument,
  }) : super(
         retry: null,
         name: r'bestServerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bestServerHash();

  @override
  String toString() {
    return r'bestServerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ServerConfig?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServerConfig? create(Ref ref) {
    final argument = this.argument as List<ServerConfig>;
    return bestServer(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServerConfig? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServerConfig?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BestServerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bestServerHash() => r'cabaee10712cde569044ee4a2220a21f77bf3d66';

/// Auto-select the best server based on latency (D-16).
/// Reactive provider: re-evaluates whenever latency data changes.

final class BestServerFamily extends $Family
    with $FunctionalFamilyOverride<ServerConfig?, List<ServerConfig>> {
  BestServerFamily._()
    : super(
        retry: null,
        name: r'bestServerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Auto-select the best server based on latency (D-16).
  /// Reactive provider: re-evaluates whenever latency data changes.

  BestServerProvider call(List<ServerConfig> servers) =>
      BestServerProvider._(argument: servers, from: this);

  @override
  String toString() => r'bestServerProvider';
}
