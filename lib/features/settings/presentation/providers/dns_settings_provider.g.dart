// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dns_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DnsSettingsNotifier)
final dnsSettingsProvider = DnsSettingsNotifierProvider._();

final class DnsSettingsNotifierProvider
    extends $NotifierProvider<DnsSettingsNotifier, DnsSettings> {
  DnsSettingsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dnsSettingsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dnsSettingsNotifierHash();

  @$internal
  @override
  DnsSettingsNotifier create() => DnsSettingsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DnsSettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DnsSettings>(value),
    );
  }
}

String _$dnsSettingsNotifierHash() =>
    r'0ab6f3e03d2d3d7646767047f0786c9117532c97';

abstract class _$DnsSettingsNotifier extends $Notifier<DnsSettings> {
  DnsSettings build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DnsSettings, DnsSettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DnsSettings, DnsSettings>,
              DnsSettings,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
