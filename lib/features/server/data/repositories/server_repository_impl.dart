import 'package:flutter/foundation.dart';
import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/data/datasources/server_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/repositories/server_repository.dart';

/// Concrete implementation of [ServerRepository] backed by Hive local storage.
///
/// Validates data read from Hive per threat model T-01-02-01:
/// null-checks required fields, validates protocolIndex range,
/// skips corrupted records with a warning.
class ServerRepositoryImpl implements ServerRepository {
  final ServerLocalDatasource _datasource;

  ServerRepositoryImpl(this._datasource);

  @override
  Future<List<ServerConfig>> getAllConfigs() async {
    final models = _datasource.getAll();
    final configs = <ServerConfig>[];

    for (final model in models) {
      final config = _validateAndConvert(model);
      if (config != null) {
        configs.add(config);
      }
    }

    return configs;
  }

  @override
  Future<ServerConfig?> getConfigById(String id) async {
    final model = _datasource.getById(id);
    if (model == null) return null;
    return _validateAndConvert(model);
  }

  @override
  Future<void> saveConfig(ServerConfig config) async {
    final model = ServerConfigModelMapper.fromDomain(config);
    await _datasource.save(model);
  }

  @override
  Future<void> deleteConfig(String id) async {
    await _datasource.delete(id);
  }

  @override
  Future<bool> exists(String id) async {
    return _datasource.exists(id);
  }

  /// Validates a Hive model and converts to domain entity.
  ///
  /// Returns null for corrupted records (T-01-02-01 mitigation):
  /// - Missing required fields (id, name, address, port)
  /// - protocolIndex out of ProtocolType enum range
  ServerConfig? _validateAndConvert(ServerConfigModel model) {
    try {
      // Validate protocolIndex is within enum range
      if (model.protocolIndex < 0 ||
          model.protocolIndex >= ProtocolType.values.length) {
        debugPrint(
          'Warning: Skipping corrupted config "${model.id}" — '
          'invalid protocolIndex: ${model.protocolIndex}',
        );
        return null;
      }

      // Validate required string fields are non-empty
      if (model.id.isEmpty || model.name.isEmpty || model.address.isEmpty) {
        debugPrint(
          'Warning: Skipping corrupted config "${model.id}" — '
          'empty required field',
        );
        return null;
      }

      // Validate port range
      if (model.port < 1 || model.port > 65535) {
        debugPrint(
          'Warning: Skipping corrupted config "${model.id}" — '
          'invalid port: ${model.port}',
        );
        return null;
      }

      return model.toDomain();
    } catch (e) {
      debugPrint(
        'Warning: Skipping corrupted config "${model.id}" — '
        'conversion error: $e',
      );
      return null;
    }
  }
}
