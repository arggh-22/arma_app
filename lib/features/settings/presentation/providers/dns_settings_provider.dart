import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

part 'dns_settings_provider.g.dart';

/// DNS configuration: protocol (DoH/DoT/Plain), remote DNS, direct DNS, FakeIP.
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

  const DnsSettings({
    this.protocol = 'doh',
    this.remoteDns = 'https://1.1.1.1/dns-query',
    this.directDns = 'localhost',
    this.fakeIpEnabled = false,
    this.fakeIpCidr = '198.18.0.0/15',
  });

  DnsSettings copyWith({
    String? protocol,
    String? remoteDns,
    String? directDns,
    bool? fakeIpEnabled,
    String? fakeIpCidr,
  }) =>
      DnsSettings(
        protocol: protocol ?? this.protocol,
        remoteDns: remoteDns ?? this.remoteDns,
        directDns: directDns ?? this.directDns,
        fakeIpEnabled: fakeIpEnabled ?? this.fakeIpEnabled,
        fakeIpCidr: fakeIpCidr ?? this.fakeIpCidr,
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
}
