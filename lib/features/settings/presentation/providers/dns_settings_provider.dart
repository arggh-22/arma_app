import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

part 'dns_settings_provider.g.dart';

/// DNS configuration: protocol (DoH/DoT/Plain), remote DNS, direct DNS.
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

  const DnsSettings({
    this.protocol = 'doh',
    this.remoteDns = 'https://1.1.1.1/dns-query',
    this.directDns = 'localhost',
  });

  DnsSettings copyWith({
    String? protocol,
    String? remoteDns,
    String? directDns,
  }) =>
      DnsSettings(
        protocol: protocol ?? this.protocol,
        remoteDns: remoteDns ?? this.remoteDns,
        directDns: directDns ?? this.directDns,
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
}
