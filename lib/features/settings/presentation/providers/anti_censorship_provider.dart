import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

part 'anti_censorship_provider.g.dart';

/// Anti-censorship settings: fragment, padding, mixed SNI, and presets.
///
/// Auto-saves every change to SharedPreferences.
/// Profile presets auto-fill all fields (D-11).
class AntiCensorshipSettings {
  /// Active profile: 'none', 'light', 'moderate', 'aggressive'.
  final String profile;
  final bool fragmentEnabled;
  final int fragmentMin;
  final int fragmentMax;
  final int sleepMin;
  final int sleepMax;
  final bool paddingEnabled;
  final bool mixedSniEnabled;

  const AntiCensorshipSettings({
    this.profile = 'none',
    this.fragmentEnabled = false,
    this.fragmentMin = 10,
    this.fragmentMax = 100,
    this.sleepMin = 0,
    this.sleepMax = 0,
    this.paddingEnabled = false,
    this.mixedSniEnabled = false,
  });

  AntiCensorshipSettings copyWith({
    String? profile,
    bool? fragmentEnabled,
    int? fragmentMin,
    int? fragmentMax,
    int? sleepMin,
    int? sleepMax,
    bool? paddingEnabled,
    bool? mixedSniEnabled,
  }) => AntiCensorshipSettings(
    profile: profile ?? this.profile,
    fragmentEnabled: fragmentEnabled ?? this.fragmentEnabled,
    fragmentMin: fragmentMin ?? this.fragmentMin,
    fragmentMax: fragmentMax ?? this.fragmentMax,
    sleepMin: sleepMin ?? this.sleepMin,
    sleepMax: sleepMax ?? this.sleepMax,
    paddingEnabled: paddingEnabled ?? this.paddingEnabled,
    mixedSniEnabled: mixedSniEnabled ?? this.mixedSniEnabled,
  );
}

@Riverpod(keepAlive: true)
class AntiCensorshipNotifier extends _$AntiCensorshipNotifier {
  late SettingsLocalDatasource _datasource;

  @override
  AntiCensorshipSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    return AntiCensorshipSettings(
      profile: _datasource.getAntiCensorshipProfile(),
      fragmentEnabled: _datasource.getFragmentEnabled(),
      fragmentMin: _datasource.getFragmentMin(),
      fragmentMax: _datasource.getFragmentMax(),
      sleepMin: _datasource.getSleepMin(),
      sleepMax: _datasource.getSleepMax(),
      paddingEnabled: _datasource.getPaddingEnabled(),
      mixedSniEnabled: _datasource.getMixedSniEnabled(),
    );
  }

  /// Apply a preset profile (D-11).
  ///
  /// Values from UI-SPEC Profile Preset Values table.
  Future<void> setProfile(String profile) async {
    await _datasource.setAntiCensorshipProfile(profile);
    switch (profile) {
      case 'none':
        await _applyValues(
          fragmentEnabled: false,
          fragmentMin: 10,
          fragmentMax: 100,
          sleepMin: 0,
          sleepMax: 0,
          paddingEnabled: false,
          mixedSniEnabled: false,
        );
        state = const AntiCensorshipSettings(profile: 'none');
      case 'light':
        await _applyValues(
          fragmentEnabled: true,
          fragmentMin: 10,
          fragmentMax: 50,
          sleepMin: 0,
          sleepMax: 0,
          paddingEnabled: false,
          mixedSniEnabled: false,
        );
        state = const AntiCensorshipSettings(
          profile: 'light',
          fragmentEnabled: true,
          fragmentMin: 10,
          fragmentMax: 50,
        );
      case 'moderate':
        await _applyValues(
          fragmentEnabled: true,
          fragmentMin: 10,
          fragmentMax: 100,
          sleepMin: 1,
          sleepMax: 10,
          paddingEnabled: true,
          mixedSniEnabled: false,
        );
        state = const AntiCensorshipSettings(
          profile: 'moderate',
          fragmentEnabled: true,
          fragmentMin: 10,
          fragmentMax: 100,
          sleepMin: 1,
          sleepMax: 10,
          paddingEnabled: true,
        );
      case 'aggressive':
        await _applyValues(
          fragmentEnabled: true,
          fragmentMin: 1,
          fragmentMax: 100,
          sleepMin: 10,
          sleepMax: 50,
          paddingEnabled: true,
          mixedSniEnabled: true,
        );
        state = const AntiCensorshipSettings(
          profile: 'aggressive',
          fragmentEnabled: true,
          fragmentMin: 1,
          fragmentMax: 100,
          sleepMin: 10,
          sleepMax: 50,
          paddingEnabled: true,
          mixedSniEnabled: true,
        );
    }
  }

  Future<void> _applyValues({
    required bool fragmentEnabled,
    required int fragmentMin,
    required int fragmentMax,
    required int sleepMin,
    required int sleepMax,
    required bool paddingEnabled,
    required bool mixedSniEnabled,
  }) async {
    await _datasource.setFragmentEnabled(fragmentEnabled);
    await _datasource.setFragmentMin(fragmentMin);
    await _datasource.setFragmentMax(fragmentMax);
    await _datasource.setSleepMin(sleepMin);
    await _datasource.setSleepMax(sleepMax);
    await _datasource.setPaddingEnabled(paddingEnabled);
    await _datasource.setMixedSniEnabled(mixedSniEnabled);
  }

  // ── Individual setters (for manual customization) ─────────────────

  /// Toggle TLS ClientHello fragmentation.
  Future<void> setFragment(bool enabled) async {
    await _datasource.setFragmentEnabled(enabled);
    state = state.copyWith(fragmentEnabled: enabled);
  }

  /// Set minimum fragment size in bytes.
  Future<void> setFragmentMin(int v) async {
    await _datasource.setFragmentMin(v);
    state = state.copyWith(fragmentMin: v);
  }

  /// Set maximum fragment size in bytes.
  Future<void> setFragmentMax(int v) async {
    await _datasource.setFragmentMax(v);
    state = state.copyWith(fragmentMax: v);
  }

  /// Set minimum sleep between fragments in ms.
  Future<void> setSleepMin(int v) async {
    await _datasource.setSleepMin(v);
    state = state.copyWith(sleepMin: v);
  }

  /// Set maximum sleep between fragments in ms.
  Future<void> setSleepMax(int v) async {
    await _datasource.setSleepMax(v);
    state = state.copyWith(sleepMax: v);
  }

  /// Toggle TLS record padding.
  Future<void> setPadding(bool enabled) async {
    await _datasource.setPaddingEnabled(enabled);
    state = state.copyWith(paddingEnabled: enabled);
  }

  /// Toggle mixed case SNI field randomization.
  Future<void> setMixedSni(bool enabled) async {
    await _datasource.setMixedSniEnabled(enabled);
    state = state.copyWith(mixedSniEnabled: enabled);
  }
}
