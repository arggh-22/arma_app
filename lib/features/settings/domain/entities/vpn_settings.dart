import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';

/// Aggregates all VPN-related settings from persistence into a single
/// immutable snapshot for the XrayConfigBuilder.
///
/// Constructed via [fromDatasource] to pull current persisted state.
class VpnSettings {
  final String dnsProtocol;
  final String remoteDns;
  final String directDns;
  final bool sniffingEnabled;
  final bool muxEnabled;
  final int muxConcurrency;
  final bool fragmentEnabled;
  final int fragmentMin;
  final int fragmentMax;
  final int sleepMin;
  final int sleepMax;
  final bool paddingEnabled;
  final bool mixedSniEnabled;
  final Set<String> enabledRegions;
  final bool bypassLan;
  final List<DomainRule> customRules;
  final bool perAppEnabled;
  final String perAppMode;
  final List<String> selectedApps;

  const VpnSettings({
    this.dnsProtocol = 'doh',
    this.remoteDns = 'https://1.1.1.1/dns-query',
    this.directDns = 'localhost',
    this.sniffingEnabled = true,
    this.muxEnabled = false,
    this.muxConcurrency = 4,
    this.fragmentEnabled = false,
    this.fragmentMin = 10,
    this.fragmentMax = 100,
    this.sleepMin = 0,
    this.sleepMax = 0,
    this.paddingEnabled = false,
    this.mixedSniEnabled = false,
    this.enabledRegions = const {},
    this.bypassLan = true,
    this.customRules = const [],
    this.perAppEnabled = false,
    this.perAppMode = 'blacklist',
    this.selectedApps = const [],
  });

  /// Build from datasource (reads current persisted state).
  factory VpnSettings.fromDatasource(
    SettingsLocalDatasource ds,
    List<DomainRule> rules,
  ) {
    return VpnSettings(
      dnsProtocol: ds.getDnsProtocol(),
      remoteDns: ds.getRemoteDns(),
      directDns: ds.getDirectDns(),
      sniffingEnabled: ds.getSniffingEnabled(),
      muxEnabled: ds.getMuxEnabled(),
      muxConcurrency: ds.getMuxConcurrency(),
      fragmentEnabled: ds.getFragmentEnabled(),
      fragmentMin: ds.getFragmentMin(),
      fragmentMax: ds.getFragmentMax(),
      sleepMin: ds.getSleepMin(),
      sleepMax: ds.getSleepMax(),
      paddingEnabled: ds.getPaddingEnabled(),
      mixedSniEnabled: ds.getMixedSniEnabled(),
      enabledRegions: ds.getEnabledRegions(),
      bypassLan: ds.getBypassLan(),
      customRules: rules,
      perAppEnabled: ds.getPerAppEnabled(),
      perAppMode: ds.getPerAppMode(),
      selectedApps: ds.getSelectedApps(),
    );
  }
}
