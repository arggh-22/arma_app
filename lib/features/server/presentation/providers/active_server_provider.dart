import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/settings/presentation/providers/theme_provider.dart';

part 'active_server_provider.g.dart';

/// Riverpod notifier for tracking the currently active/selected server.
///
/// Persists the active server ID in SharedPreferences and resolves
/// the full [ServerConfig] from the server list.
@riverpod
class ActiveServerNotifier extends _$ActiveServerNotifier {
  late SettingsLocalDatasource _datasource;

  @override
  ServerConfig? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    final activeId = _datasource.getActiveServerId();
    if (activeId == null) return null;

    final serversAsync = ref.watch(serverListProvider);
    return serversAsync.whenOrNull(
      data: (servers) {
        try {
          return servers.firstWhere((s) => s.id == activeId);
        } catch (_) {
          return null;
        }
      },
    );
  }

  /// Selects a server as active and persists the choice.
  ///
  /// Pass null to clear the active server.
  Future<void> selectServer(ServerConfig? server) async {
    await _datasource.setActiveServerId(server?.id);
    state = server;
  }
}
