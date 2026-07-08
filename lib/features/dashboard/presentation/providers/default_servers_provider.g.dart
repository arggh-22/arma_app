// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_servers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DefaultServersNotifier)
final defaultServersProvider = DefaultServersNotifierProvider._();

final class DefaultServersNotifierProvider
    extends $NotifierProvider<DefaultServersNotifier, DefaultServersState> {
  DefaultServersNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultServersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultServersNotifierHash();

  @$internal
  @override
  DefaultServersNotifier create() => DefaultServersNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DefaultServersState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DefaultServersState>(value),
    );
  }
}

String _$defaultServersNotifierHash() =>
    r'1f30300cbe67f2f3814dca31c14ed9b30fb2552f';

abstract class _$DefaultServersNotifier extends $Notifier<DefaultServersState> {
  DefaultServersState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DefaultServersState, DefaultServersState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DefaultServersState, DefaultServersState>,
              DefaultServersState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
