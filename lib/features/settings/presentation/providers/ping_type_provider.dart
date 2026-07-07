import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/ping_type.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

/// Selected latency-measurement [PingType] (Advanced Settings, spec §2).
/// Persisted to preferences; defaults to [PingType.http].
class PingTypeNotifier extends Notifier<PingType> {
  late SettingsLocalDatasource _datasource;

  @override
  PingType build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    return PingType.fromKey(_datasource.getPingType());
  }

  Future<void> set(PingType type) async {
    await _datasource.setPingType(type.key);
    state = type;
  }
}

final pingTypeProvider =
    NotifierProvider<PingTypeNotifier, PingType>(PingTypeNotifier.new);
