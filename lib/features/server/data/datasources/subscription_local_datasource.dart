import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/subscription_model.dart';
import 'package:arma_proxy_vpn_client/core/error/exceptions.dart';

/// Local data source for subscriptions backed by a Hive box.
///
/// All operations are synchronous reads / async writes against
/// a `Box<SubscriptionModel>` keyed by subscription ID.
class SubscriptionLocalDatasource {
  final Box<SubscriptionModel> _box;

  SubscriptionLocalDatasource(this._box);

  /// Returns all stored subscription models.
  List<SubscriptionModel> getAll() => _box.values.toList();

  /// Returns the model with [id], or null if not found.
  SubscriptionModel? getById(String id) {
    try {
      return _box.values.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Persists a subscription model, keyed by its [SubscriptionModel.id].
  Future<void> save(SubscriptionModel model) async {
    try {
      await _box.put(model.id, model);
    } catch (e) {
      throw StorageException('Failed to save subscription: $e');
    }
  }

  /// Persists multiple subscription models in a batch.
  Future<void> saveAll(List<SubscriptionModel> models) async {
    try {
      final entries = {for (final m in models) m.id: m};
      await _box.putAll(entries);
    } catch (e) {
      throw StorageException('Failed to save subscriptions: $e');
    }
  }

  /// Deletes the subscription with the given [id].
  Future<void> delete(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw StorageException('Failed to delete subscription: $e');
    }
  }

  /// Returns true if a subscription with the given [id] exists.
  bool exists(String id) => _box.containsKey(id);
}
