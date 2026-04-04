import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/server_config_model.dart';
import 'package:arma_proxy_vpn_client/core/error/exceptions.dart';

/// Local data source for server configurations backed by a Hive box.
///
/// All operations are synchronous reads / async writes against
/// a `Box<ServerConfigModel>` keyed by config ID.
class ServerLocalDatasource {
  final Box<ServerConfigModel> _box;

  ServerLocalDatasource(this._box);

  /// Returns all stored models.
  List<ServerConfigModel> getAll() => _box.values.toList();

  /// Returns the model with [id], or null if not found.
  ServerConfigModel? getById(String id) {
    try {
      return _box.values.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Persists a model, keyed by its [ServerConfigModel.id].
  Future<void> save(ServerConfigModel model) async {
    try {
      await _box.put(model.id, model);
    } catch (e) {
      throw StorageException('Failed to save config: $e');
    }
  }

  /// Deletes the model with the given [id].
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete config: $e');
    }
  }

  /// Returns true if a config with the given [id] exists.
  bool exists(String id) => _box.containsKey(id);
}
