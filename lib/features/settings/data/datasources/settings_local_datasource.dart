import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Local data source for user preferences backed by SharedPreferences.
///
/// Stores theme mode, locale, active server selection, and all Phase 4
/// settings: DNS, engine, anti-censorship, per-app proxy, and routing.
/// All values are lightweight (int/string/bool) — no sensitive data.
class SettingsLocalDatasource {
  static const _themeKey = 'theme_mode';
  static const _localeKey = 'locale';
  static const _activeServerKey = 'active_server_id';

  // DNS (D-06, D-07)
  static const _dnsProtocolKey = 'dns_protocol';
  static const _remoteDnsKey = 'remote_dns';
  static const _directDnsKey = 'direct_dns';

  // Engine (D-08, D-09)
  static const _sniffingKey = 'sniffing_enabled';
  static const _muxEnabledKey = 'mux_enabled';
  static const _muxConcurrencyKey = 'mux_concurrency';

  // Anti-Censorship (D-10, D-11)
  static const _fragmentEnabledKey = 'fragment_enabled';
  static const _fragmentMinKey = 'fragment_min';
  static const _fragmentMaxKey = 'fragment_max';
  static const _sleepMinKey = 'sleep_min';
  static const _sleepMaxKey = 'sleep_max';
  static const _paddingEnabledKey = 'padding_enabled';
  static const _mixedSniKey = 'mixed_sni_enabled';
  static const _antiCensorshipProfileKey = 'anti_censorship_profile';

  // Per-App Proxy (D-04)
  static const _perAppEnabledKey = 'per_app_enabled';
  static const _perAppModeKey = 'per_app_mode';
  static const _selectedAppsKey = 'selected_apps';

  // Routing (D-01)
  static const _enabledRegionsKey = 'enabled_regions';
  static const _bypassLanKey = 'bypass_lan';

  // UI / notification display
  static const _showDetailedNotificationKey = 'show_detailed_notification';
  static const _showDashboardStatisticsKey = 'show_dashboard_statistics';

  final SharedPreferences _prefs;

  SettingsLocalDatasource(this._prefs);

  // ── Theme / Locale / Active Server ─────────────────────────────────

  /// Returns theme mode index: 0=system, 1=light, 2=dark.
  int getThemeMode() => _prefs.getInt(_themeKey) ?? 0;

  /// Persists theme mode index.
  Future<void> setThemeMode(int mode) => _prefs.setInt(_themeKey, mode);

  /// Returns stored locale code (defaults to 'en').
  String getLocale() => _prefs.getString(_localeKey) ?? 'en';

  /// Persists locale code (e.g., 'fa', 'ru', 'zh').
  Future<void> setLocale(String locale) => _prefs.setString(_localeKey, locale);

  /// Returns the active server ID, or null if none selected.
  String? getActiveServerId() => _prefs.getString(_activeServerKey);

  /// Persists or clears the active server ID.
  Future<void> setActiveServerId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeServerKey);
    } else {
      await _prefs.setString(_activeServerKey, id);
    }
  }

  // ── DNS (D-06, D-07) ──────────────────────────────────────────────

  /// DNS protocol: "doh", "dot", or "plain".
  String getDnsProtocol() => _prefs.getString(_dnsProtocolKey) ?? 'doh';

  Future<void> setDnsProtocol(String protocol) =>
      _prefs.setString(_dnsProtocolKey, protocol);

  /// Remote DNS server URL.
  String getRemoteDns() =>
      _prefs.getString(_remoteDnsKey) ?? 'https://1.1.1.1/dns-query';

  Future<void> setRemoteDns(String dns) => _prefs.setString(_remoteDnsKey, dns);

  /// Direct DNS server (used for domestic/direct traffic).
  String getDirectDns() => _prefs.getString(_directDnsKey) ?? 'localhost';

  Future<void> setDirectDns(String dns) => _prefs.setString(_directDnsKey, dns);

  // ── FakeIP DNS ────────────────────────────────────────────────────

  static const _fakeIpEnabledKey = 'fakeip_enabled';
  static const _fakeIpCidrKey = 'fakeip_cidr';

  /// FakeIP DNS mode. Default OFF.
  bool getFakeIpEnabled() => _prefs.getBool(_fakeIpEnabledKey) ?? false;

  Future<void> setFakeIpEnabled(bool enabled) =>
      _prefs.setBool(_fakeIpEnabledKey, enabled);

  /// FakeIP CIDR range. Default 198.18.0.0/15.
  String getFakeIpCidr() => _prefs.getString(_fakeIpCidrKey) ?? '198.18.0.0/15';

  Future<void> setFakeIpCidr(String cidr) =>
      _prefs.setString(_fakeIpCidrKey, cidr);

  // ── Engine Settings (D-08, D-09) ──────────────────────────────────

  /// Traffic sniffing — detect protocol type from content. Default ON.
  bool getSniffingEnabled() => _prefs.getBool(_sniffingKey) ?? true;

  Future<void> setSniffingEnabled(bool enabled) =>
      _prefs.setBool(_sniffingKey, enabled);

  /// Mux (multiplexing) — combine multiple connections. Default OFF.
  bool getMuxEnabled() => _prefs.getBool(_muxEnabledKey) ?? false;

  Future<void> setMuxEnabled(bool enabled) =>
      _prefs.setBool(_muxEnabledKey, enabled);

  /// Mux concurrency level.
  int getMuxConcurrency() => _prefs.getInt(_muxConcurrencyKey) ?? 4;

  Future<void> setMuxConcurrency(int concurrency) =>
      _prefs.setInt(_muxConcurrencyKey, concurrency);

  // ── Anti-Censorship (D-10, D-11) ──────────────────────────────────

  /// TLS ClientHello fragmentation.
  bool getFragmentEnabled() => _prefs.getBool(_fragmentEnabledKey) ?? false;

  Future<void> setFragmentEnabled(bool enabled) =>
      _prefs.setBool(_fragmentEnabledKey, enabled);

  /// Minimum fragment size in bytes.
  int getFragmentMin() => _prefs.getInt(_fragmentMinKey) ?? 10;

  Future<void> setFragmentMin(int min) => _prefs.setInt(_fragmentMinKey, min);

  /// Maximum fragment size in bytes.
  int getFragmentMax() => _prefs.getInt(_fragmentMaxKey) ?? 100;

  Future<void> setFragmentMax(int max) => _prefs.setInt(_fragmentMaxKey, max);

  /// Minimum sleep between fragments in ms.
  int getSleepMin() => _prefs.getInt(_sleepMinKey) ?? 0;

  Future<void> setSleepMin(int min) => _prefs.setInt(_sleepMinKey, min);

  /// Maximum sleep between fragments in ms.
  int getSleepMax() => _prefs.getInt(_sleepMaxKey) ?? 0;

  Future<void> setSleepMax(int max) => _prefs.setInt(_sleepMaxKey, max);

  /// Add padding to TLS records.
  bool getPaddingEnabled() => _prefs.getBool(_paddingEnabledKey) ?? false;

  Future<void> setPaddingEnabled(bool enabled) =>
      _prefs.setBool(_paddingEnabledKey, enabled);

  /// Randomize letter case in SNI field.
  bool getMixedSniEnabled() => _prefs.getBool(_mixedSniKey) ?? false;

  Future<void> setMixedSniEnabled(bool enabled) =>
      _prefs.setBool(_mixedSniKey, enabled);

  /// Anti-censorship profile: "none", "light", "moderate", "aggressive".
  String getAntiCensorshipProfile() =>
      _prefs.getString(_antiCensorshipProfileKey) ?? 'none';

  Future<void> setAntiCensorshipProfile(String profile) =>
      _prefs.setString(_antiCensorshipProfileKey, profile);

  // ── Per-App Proxy (D-04) ──────────────────────────────────────────

  /// Whether per-app proxy routing is enabled.
  bool getPerAppEnabled() => _prefs.getBool(_perAppEnabledKey) ?? false;

  Future<void> setPerAppEnabled(bool enabled) =>
      _prefs.setBool(_perAppEnabledKey, enabled);

  /// Per-app mode: "blacklist" or "whitelist".
  String getPerAppMode() => _prefs.getString(_perAppModeKey) ?? 'blacklist';

  Future<void> setPerAppMode(String mode) =>
      _prefs.setString(_perAppModeKey, mode);

  /// List of selected app package names (JSON-encoded).
  List<String> getSelectedApps() {
    final json = _prefs.getString(_selectedAppsKey);
    if (json == null || json.isEmpty) return <String>[];
    final decoded = jsonDecode(json);
    return (decoded as List<dynamic>).cast<String>();
  }

  Future<void> setSelectedApps(List<String> apps) =>
      _prefs.setString(_selectedAppsKey, jsonEncode(apps));

  // ── Routing (D-01) ────────────────────────────────────────────────

  /// Set of enabled region codes (JSON-encoded).
  Set<String> getEnabledRegions() {
    final json = _prefs.getString(_enabledRegionsKey);
    if (json == null || json.isEmpty) return <String>{};
    final decoded = jsonDecode(json);
    return (decoded as List<dynamic>).cast<String>().toSet();
  }

  Future<void> setEnabledRegions(Set<String> regions) =>
      _prefs.setString(_enabledRegionsKey, jsonEncode(regions.toList()));

  /// Bypass LAN traffic (don't route local network through VPN).
  bool getBypassLan() => _prefs.getBool(_bypassLanKey) ?? true;

  Future<void> setBypassLan(bool bypass) =>
      _prefs.setBool(_bypassLanKey, bypass);

  // ── DNS Presets and Filtering ──────────────────────────────────────────

  static const _dnsPresetIdKey = 'dns_preset_id';
  static const _dnsBlockAdsKey = 'dns_block_ads';
  static const _dnsBlockMalwareKey = 'dns_block_malware';
  static const _dnsBlockAdultContentKey = 'dns_block_adult_content';
  static const _dnsBlockTrackersKey = 'dns_block_trackers';
  static const _dnsCustomBlockListKey = 'dns_custom_block_list';

  /// Current DNS preset ID (null if custom).
  String? getDnsPresetId() => _prefs.getString(_dnsPresetIdKey);

  Future<void> setDnsPresetId(String? id) async {
    if (id == null) {
      await _prefs.remove(_dnsPresetIdKey);
    } else {
      await _prefs.setString(_dnsPresetIdKey, id);
    }
  }

  /// Block ads filter.
  bool getDnsBlockAds() => _prefs.getBool(_dnsBlockAdsKey) ?? false;

  Future<void> setDnsBlockAds(bool enabled) =>
      _prefs.setBool(_dnsBlockAdsKey, enabled);

  /// Block malware filter.
  bool getDnsBlockMalware() => _prefs.getBool(_dnsBlockMalwareKey) ?? false;

  Future<void> setDnsBlockMalware(bool enabled) =>
      _prefs.setBool(_dnsBlockMalwareKey, enabled);

  /// Block adult content filter.
  bool getDnsBlockAdultContent() =>
      _prefs.getBool(_dnsBlockAdultContentKey) ?? false;

  Future<void> setDnsBlockAdultContent(bool enabled) =>
      _prefs.setBool(_dnsBlockAdultContentKey, enabled);

  /// Block trackers filter.
  bool getDnsBlockTrackers() => _prefs.getBool(_dnsBlockTrackersKey) ?? false;

  Future<void> setDnsBlockTrackers(bool enabled) =>
      _prefs.setBool(_dnsBlockTrackersKey, enabled);

  /// Custom block list URL.
  String getDnsCustomBlockList() =>
      _prefs.getString(_dnsCustomBlockListKey) ?? '';

  Future<void> setDnsCustomBlockList(String url) =>
      _prefs.setString(_dnsCustomBlockListKey, url);

  // ── UI / Notification display ───────────────────────────────────────────

  /// Whether to show detailed VPN notification with server and traffic stats.
  bool getShowDetailedNotification() =>
      _prefs.getBool(_showDetailedNotificationKey) ?? true;

  Future<void> setShowDetailedNotification(bool enabled) =>
      _prefs.setBool(_showDetailedNotificationKey, enabled);

  /// Whether to show traffic statistics card on dashboard.
  bool getShowDashboardStatistics() =>
      _prefs.getBool(_showDashboardStatisticsKey) ?? true;

  Future<void> setShowDashboardStatistics(bool enabled) =>
      _prefs.setBool(_showDashboardStatisticsKey, enabled);
}
