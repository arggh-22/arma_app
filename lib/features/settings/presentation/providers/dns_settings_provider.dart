import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/dns_presets.dart';

part 'dns_settings_provider.g.dart';

/// DNS configuration: protocol (DoH/DoT/Plain), remote DNS, direct DNS, FakeIP, filtering.
///
/// Auto-saves every change to SharedPreferences.
/// These settings take effect on the next VPN connection.
class DnsSettings {
  /// DNS protocol: 'doh', 'dot', or 'plain'.
  final String protocol;

  /// Remote DNS server URL (used for proxied traffic).
  final String remoteDns;

  /// Direct DNS server (used for domestic/direct traffic).
  final String directDns;

  /// Whether FakeIP DNS mode is enabled.
  final bool fakeIpEnabled;

  /// FakeIP CIDR range (e.g. '198.18.0.0/15').
  final String fakeIpCidr;

  /// Current DNS preset ID (null if custom).
  final String? presetId;

  /// DNS filtering options.
  final DnsFilteringOptions filtering;

  const DnsSettings({
    this.protocol = 'doh',
    this.remoteDns = 'https://1.1.1.1/dns-query',
    this.directDns = 'localhost',
    this.fakeIpEnabled = false,
    this.fakeIpCidr = '198.18.0.0/15',
    this.presetId,
    this.filtering = const DnsFilteringOptions(),
  });

  DnsSettings copyWith({
    String? protocol,
    String? remoteDns,
    String? directDns,
    bool? fakeIpEnabled,
    String? fakeIpCidr,
    String? presetId,
    DnsFilteringOptions? filtering,
  }) =>
      DnsSettings(
        protocol: protocol ?? this.protocol,
        remoteDns: remoteDns ?? this.remoteDns,
        directDns: directDns ?? this.directDns,
        fakeIpEnabled: fakeIpEnabled ?? this.fakeIpEnabled,
        fakeIpCidr: fakeIpCidr ?? this.fakeIpCidr,
        presetId: presetId ?? this.presetId,
        filtering: filtering ?? this.filtering,
      );
}

@Riverpod(keepAlive: true)
class DnsSettingsNotifier extends _$DnsSettingsNotifier {
  late SettingsLocalDatasource _datasource;

  @override
  DnsSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    return DnsSettings(
      protocol: _datasource.getDnsProtocol(),
      remoteDns: _datasource.getRemoteDns(),
      directDns: _datasource.getDirectDns(),
      fakeIpEnabled: _datasource.getFakeIpEnabled(),
      fakeIpCidr: _datasource.getFakeIpCidr(),
      presetId: _datasource.getDnsPresetId(),
      filtering: DnsFilteringOptions(
        blockAds: _datasource.getDnsBlockAds(),
        blockMalware: _datasource.getDnsBlockMalware(),
        blockAdultContent: _datasource.getDnsBlockAdultContent(),
        blockTrackers: _datasource.getDnsBlockTrackers(),
        customBlockList: _datasource.getDnsCustomBlockList(),
      ),
    );
  }

  /// Set DNS protocol: 'doh', 'dot', or 'plain'.
  Future<void> setProtocol(String protocol) async {
    await _datasource.setDnsProtocol(protocol);
    state = state.copyWith(protocol: protocol);
  }

  /// Set remote DNS server URL.
  Future<void> setRemoteDns(String dns) async {
    await _datasource.setRemoteDns(dns);
    state = state.copyWith(remoteDns: dns);
  }

  /// Set direct DNS server.
  Future<void> setDirectDns(String dns) async {
    await _datasource.setDirectDns(dns);
    state = state.copyWith(directDns: dns);
  }

  /// Toggle FakeIP DNS mode.
  Future<void> setFakeIpEnabled(bool enabled) async {
    await _datasource.setFakeIpEnabled(enabled);
    state = state.copyWith(fakeIpEnabled: enabled);
  }

  /// Set FakeIP CIDR range.
  Future<void> setFakeIpCidr(String cidr) async {
    await _datasource.setFakeIpCidr(cidr);
    state = state.copyWith(fakeIpCidr: cidr);
  }

  /// Apply a DNS preset.
  Future<void> applyPreset(DnsPreset preset) async {
    final dns = state.protocol == 'dot' ? preset.doT : preset.doH;
    await _datasource.setRemoteDns(dns);
    await _datasource.setDnsPresetId(preset.id);
    state = state.copyWith(remoteDns: dns, presetId: preset.id);
  }

  /// Toggle ad-blocking filter.
  Future<void> setBlockAds(bool enabled) async {
    await _datasource.setDnsBlockAds(enabled);
    state = state.copyWith(
      filtering: state.filtering.copyWith(blockAds: enabled),
    );
  }

  /// Toggle malware filter.
  Future<void> setBlockMalware(bool enabled) async {
    await _datasource.setDnsBlockMalware(enabled);
    state = state.copyWith(
      filtering: state.filtering.copyWith(blockMalware: enabled),
    );
  }

  /// Toggle adult content filter.
  Future<void> setBlockAdultContent(bool enabled) async {
    await _datasource.setDnsBlockAdultContent(enabled);
    state = state.copyWith(
      filtering: state.filtering.copyWith(blockAdultContent: enabled),
    );
  }

  /// Toggle tracker filter.
  Future<void> setBlockTrackers(bool enabled) async {
    await _datasource.setDnsBlockTrackers(enabled);
    state = state.copyWith(
      filtering: state.filtering.copyWith(blockTrackers: enabled),
    );
  }

  /// Set custom block list URL.
  Future<void> setCustomBlockList(String url) async {
    await _datasource.setDnsCustomBlockList(url);
    state = state.copyWith(
      filtering: state.filtering.copyWith(customBlockList: url),
    );
  }
}
