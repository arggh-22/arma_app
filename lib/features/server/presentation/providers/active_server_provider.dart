import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/presentation/providers/default_servers_provider.dart';
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

    // Default servers (ids prefixed `default-api-`) aren't in the imported
    // list. Resolve them against the live default-servers list so the config
    // is fresh and validated (a server that expired / was removed clears the
    // selection). While that list hasn't loaded yet, fall back to the persisted
    // snapshot so the selection shows immediately after a restart.
    if (activeId.startsWith('default-api')) {
      final defaultState = ref.watch(defaultServersProvider);
      for (final item in defaultState.items) {
        if (item.isConnectable && item.serverConfig?.id == activeId) {
          return item.serverConfig;
        }
      }
      if (defaultState.items.isEmpty) {
        return _restoreSnapshot();
      }
      // The default list has loaded but no longer contains this server.
      return null;
    }

    // Imported servers: resolve fresh from the list so edits/deletes are
    // reflected (a deleted server clears the selection).
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

  /// Deserializes the persisted active-server snapshot, or null if absent.
  ServerConfig? _restoreSnapshot() {
    final json = _datasource.getActiveServerConfigJson();
    if (json == null) return null;
    try {
      return ServerConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Selects a server as active and persists the choice (id + full snapshot).
  ///
  /// Pass null to clear the active server.
  Future<void> selectServer(ServerConfig? server) async {
    await _datasource.setActiveServerId(server?.id);
    await _datasource.setActiveServerConfigJson(
      server == null ? null : jsonEncode(server.toJson()),
    );
    state = server;
  }
}
