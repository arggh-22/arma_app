import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/default_server_auto_update_interval.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_refresh_scheduler_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DefaultServerAutoUpdateNotifier
    extends Notifier<DefaultServerAutoUpdateInterval> {
  late SettingsLocalDatasource _datasource;

  @override
  DefaultServerAutoUpdateInterval build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    return _datasource.getDefaultServerAutoUpdateInterval();
  }

  Future<void> setInterval(DefaultServerAutoUpdateInterval interval) async {
    await _datasource.setDefaultServerAutoUpdateInterval(interval);
    await ref
        .read(defaultServerRefreshSchedulerProvider.notifier)
        .applyInterval(interval);
    state = interval;
  }
}

final defaultServerAutoUpdateProvider =
    NotifierProvider<
      DefaultServerAutoUpdateNotifier,
      DefaultServerAutoUpdateInterval
    >(DefaultServerAutoUpdateNotifier.new);
