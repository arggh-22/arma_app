import 'package:hive_ce/hive_ce.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/datasources/routing_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/models/domain_rule_model.dart';
import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

part 'routing_settings_provider.g.dart';

/// Immutable state for all routing settings:
/// bypass LAN, region presets, custom domain rules, per-app proxy.
class RoutingSettings {
  final bool bypassLan;
  final Set<String> enabledRegions;
  final List<DomainRule> customRules;
  final bool perAppEnabled;
  final String perAppMode;
  final List<String> selectedApps;

  const RoutingSettings({
    this.bypassLan = true,
    this.enabledRegions = const {},
    this.customRules = const [],
    this.perAppEnabled = false,
    this.perAppMode = 'blacklist',
    this.selectedApps = const [],
  });

  RoutingSettings copyWith({
    bool? bypassLan,
    Set<String>? enabledRegions,
    List<DomainRule>? customRules,
    bool? perAppEnabled,
    String? perAppMode,
    List<String>? selectedApps,
  }) =>
      RoutingSettings(
        bypassLan: bypassLan ?? this.bypassLan,
        enabledRegions: enabledRegions ?? this.enabledRegions,
        customRules: customRules ?? this.customRules,
        perAppEnabled: perAppEnabled ?? this.perAppEnabled,
        perAppMode: perAppMode ?? this.perAppMode,
        selectedApps: selectedApps ?? this.selectedApps,
      );
}

/// Riverpod notifier managing all routing settings with persistence.
///
/// Reads from SharedPreferences (lightweight values) and Hive (domain rules).
/// Writes back immediately on each mutation — no save button needed.
@Riverpod(keepAlive: true)
class RoutingSettingsNotifier extends _$RoutingSettingsNotifier {
  late SettingsLocalDatasource _settingsDatasource;
  late RoutingLocalDatasource _routingDatasource;

  @override
  RoutingSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _settingsDatasource = SettingsLocalDatasource(prefs);
    final rulesBox = Hive.box<DomainRuleModel>('domain_rules');
    _routingDatasource = RoutingLocalDatasource(rulesBox);

    return RoutingSettings(
      bypassLan: _settingsDatasource.getBypassLan(),
      enabledRegions: _settingsDatasource.getEnabledRegions(),
      customRules: _routingDatasource.getAllRules(),
      perAppEnabled: _settingsDatasource.getPerAppEnabled(),
      perAppMode: _settingsDatasource.getPerAppMode(),
      selectedApps: _settingsDatasource.getSelectedApps(),
    );
  }

  /// Toggle bypass LAN routing.
  Future<void> setBypassLan(bool v) async {
    await _settingsDatasource.setBypassLan(v);
    state = state.copyWith(bypassLan: v);
  }

  /// Toggle a region preset on or off.
  Future<void> toggleRegion(String region) async {
    final regions = Set<String>.from(state.enabledRegions);
    if (regions.contains(region)) {
      regions.remove(region);
    } else {
      regions.add(region);
    }
    await _settingsDatasource.setEnabledRegions(regions);
    state = state.copyWith(enabledRegions: regions);
  }

  /// Add a new custom domain rule.
  Future<void> addRule(DomainRule rule) async {
    await _routingDatasource.addRule(rule);
    state = state.copyWith(customRules: _routingDatasource.getAllRules());
  }

  /// Change the action for an existing rule at [index].
  Future<void> updateRuleAction(int index, String action) async {
    final rule = state.customRules[index];
    await _routingDatasource.updateRule(
      index,
      DomainRule(domain: rule.domain, action: action),
    );
    state = state.copyWith(customRules: _routingDatasource.getAllRules());
  }

  /// Delete the rule at [index].
  Future<void> deleteRule(int index) async {
    await _routingDatasource.deleteRule(index);
    state = state.copyWith(customRules: _routingDatasource.getAllRules());
  }

  /// Restore a deleted rule (for undo). Appends at end (Hive is append-only).
  Future<void> insertRule(int index, DomainRule rule) async {
    await _routingDatasource.addRule(rule);
    state = state.copyWith(customRules: _routingDatasource.getAllRules());
  }

  /// Toggle per-app proxy on/off.
  Future<void> setPerAppEnabled(bool v) async {
    await _settingsDatasource.setPerAppEnabled(v);
    state = state.copyWith(perAppEnabled: v);
  }

  /// Switch per-app mode. Clears app selection when switching modes.
  Future<void> setPerAppMode(String mode) async {
    await _settingsDatasource.setPerAppMode(mode);
    await _settingsDatasource.setSelectedApps([]);
    state = state.copyWith(perAppMode: mode, selectedApps: []);
  }

  /// Toggle a single app in/out of the selected list.
  Future<void> toggleApp(String packageName) async {
    final apps = List<String>.from(state.selectedApps);
    if (apps.contains(packageName)) {
      apps.remove(packageName);
    } else {
      apps.add(packageName);
    }
    await _settingsDatasource.setSelectedApps(apps);
    state = state.copyWith(selectedApps: apps);
  }

  /// Replace selected app package names in one write.
  Future<void> setSelectedApps(List<String> packageNames) async {
    final unique = packageNames.toSet().toList();
    await _settingsDatasource.setSelectedApps(unique);
    state = state.copyWith(selectedApps: unique);
  }
}
