// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'default_server_keys_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Supports manual retry by calling `ref.refresh(defaultServerKeysProvider)`.

@ProviderFor(defaultServerKeys)
final defaultServerKeysProvider = DefaultServerKeysProvider._();

/// Supports manual retry by calling `ref.refresh(defaultServerKeysProvider)`.

final class DefaultServerKeysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DefaultServerKey>>,
          List<DefaultServerKey>,
          FutureOr<List<DefaultServerKey>>
        >
    with
        $FutureModifier<List<DefaultServerKey>>,
        $FutureProvider<List<DefaultServerKey>> {
  /// Supports manual retry by calling `ref.refresh(defaultServerKeysProvider)`.
  DefaultServerKeysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'defaultServerKeysProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$defaultServerKeysHash();

  @$internal
  @override
  $FutureProviderElement<List<DefaultServerKey>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DefaultServerKey>> create(Ref ref) {
    return defaultServerKeys(ref);
  }
}

String _$defaultServerKeysHash() => r'345a72e68e80168d8235d925e6301b1eb5ad2796';
