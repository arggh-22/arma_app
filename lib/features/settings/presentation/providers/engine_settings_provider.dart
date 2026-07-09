import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

part 'engine_settings_provider.g.dart';

/// Engine-level settings: sniffing, mux, and mux concurrency.
///
/// Auto-saves every change to SharedPreferences.
/// These settings take effect on the next VPN connection.
class EngineSettings {
  final bool sniffingEnabled;
  final bool muxEnabled;
  final int muxConcurrency;

  const EngineSettings({
    this.sniffingEnabled = true,
    this.muxEnabled = false,
    this.muxConcurrency = 4,
  });

  EngineSettings copyWith({
    bool? sniffingEnabled,
    bool? muxEnabled,
    int? muxConcurrency,
  }) => EngineSettings(
    sniffingEnabled: sniffingEnabled ?? this.sniffingEnabled,
    muxEnabled: muxEnabled ?? this.muxEnabled,
    muxConcurrency: muxConcurrency ?? this.muxConcurrency,
  );
}

@Riverpod(keepAlive: true)
class EngineSettingsNotifier extends _$EngineSettingsNotifier {
  late SettingsLocalDatasource _datasource;

  @override
  EngineSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    return EngineSettings(
      sniffingEnabled: _datasource.getSniffingEnabled(),
      muxEnabled: _datasource.getMuxEnabled(),
      muxConcurrency: _datasource.getMuxConcurrency(),
    );
  }

  /// Toggle traffic sniffing (protocol detection from content).
  Future<void> setSniffing(bool enabled) async {
    await _datasource.setSniffingEnabled(enabled);
    state = state.copyWith(sniffingEnabled: enabled);
  }

  /// Toggle mux (multiplexing multiple connections).
  Future<void> setMux(bool enabled) async {
    await _datasource.setMuxEnabled(enabled);
    state = state.copyWith(muxEnabled: enabled);
  }

  /// Set mux concurrency level (1–8).
  Future<void> setMuxConcurrency(int value) async {
    await _datasource.setMuxConcurrency(value);
    state = state.copyWith(muxConcurrency: value);
  }
}
