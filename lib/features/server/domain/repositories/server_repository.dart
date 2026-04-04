import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Abstract interface for server configuration persistence.
///
/// Implemented by [ServerRepositoryImpl] which delegates to
/// [ServerLocalDatasource] backed by a Hive box.
abstract class ServerRepository {
  /// Returns all stored server configurations.
  Future<List<ServerConfig>> getAllConfigs();

  /// Returns the config with the given [id], or null if not found.
  Future<ServerConfig?> getConfigById(String id);

  /// Persists a server configuration (upserts by [ServerConfig.id]).
  Future<void> saveConfig(ServerConfig config);

  /// Deletes the server configuration with the given [id].
  Future<void> deleteConfig(String id);

  /// Returns true if a config with the given [id] exists.
  Future<bool> exists(String id);
}
