// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_bootstrap_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Startup bootstrap that authenticates once and prewarms default key fetches.

@ProviderFor(AuthBootstrap)
final authBootstrapProvider = AuthBootstrapProvider._();

/// Startup bootstrap that authenticates once and prewarms default key fetches.
final class AuthBootstrapProvider
    extends $AsyncNotifierProvider<AuthBootstrap, void> {
  /// Startup bootstrap that authenticates once and prewarms default key fetches.
  AuthBootstrapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authBootstrapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authBootstrapHash();

  @$internal
  @override
  AuthBootstrap create() => AuthBootstrap();
}

String _$authBootstrapHash() => r'54d8eb5dc67f827cf0c2e4a2ac85acd6547c66f8';

/// Startup bootstrap that authenticates once and prewarms default key fetches.

abstract class _$AuthBootstrap extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
