import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

class UiPreferences {
  final bool showDetailedNotification;
  final bool showDashboardStatistics;

  const UiPreferences({
    this.showDetailedNotification = true,
    this.showDashboardStatistics = true,
  });

  UiPreferences copyWith({
    bool? showDetailedNotification,
    bool? showDashboardStatistics,
  }) {
    return UiPreferences(
      showDetailedNotification:
          showDetailedNotification ?? this.showDetailedNotification,
      showDashboardStatistics:
          showDashboardStatistics ?? this.showDashboardStatistics,
    );
  }
}

class UiPreferencesNotifier extends Notifier<UiPreferences> {
  late SettingsLocalDatasource _datasource;
  final VpnPlatformService _platformService = VpnPlatformService();

  @override
  UiPreferences build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    return UiPreferences(
      showDetailedNotification: _datasource.getShowDetailedNotification(),
      showDashboardStatistics: _datasource.getShowDashboardStatistics(),
    );
  }

  Future<void> setShowDetailedNotification(bool enabled) async {
    await _datasource.setShowDetailedNotification(enabled);
    await _platformService.setNotificationDetailsEnabled(enabled);
    state = state.copyWith(showDetailedNotification: enabled);
  }

  Future<void> setShowDashboardStatistics(bool enabled) async {
    await _datasource.setShowDashboardStatistics(enabled);
    state = state.copyWith(showDashboardStatistics: enabled);
  }
}

final uiPreferencesProvider =
    NotifierProvider<UiPreferencesNotifier, UiPreferences>(
      UiPreferencesNotifier.new,
    );
