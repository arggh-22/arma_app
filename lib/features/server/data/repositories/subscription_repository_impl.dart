import 'package:flutter/foundation.dart';
import 'package:arma_proxy_vpn_client/features/server/data/datasources/subscription_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/subscription_model.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/repositories/subscription_repository.dart';

/// Concrete implementation of [SubscriptionRepository] backed by Hive.
///
/// Converts between domain [Subscription] entities and Hive [SubscriptionModel]s.
/// Validates data read from Hive, skipping corrupted records with a warning.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionLocalDatasource _datasource;

  SubscriptionRepositoryImpl(this._datasource);

  @override
  List<Subscription> getAllSubscriptions() {
    final models = _datasource.getAll();
    final subscriptions = <Subscription>[];

    for (final model in models) {
      final sub = _validateAndConvert(model);
      if (sub != null) {
        subscriptions.add(sub);
      }
    }

    return subscriptions;
  }

  @override
  Subscription? getSubscriptionById(String id) {
    final model = _datasource.getById(id);
    if (model == null) return null;
    return _validateAndConvert(model);
  }

  @override
  Future<void> saveSubscription(Subscription subscription) async {
    final model = SubscriptionModel.fromDomain(subscription);
    await _datasource.save(model);
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _datasource.delete(id);
  }

  @override
  Future<void> updateSubscriptionInfo(
    String id, {
    int? uploadBytes,
    int? downloadBytes,
    int? totalBytes,
    DateTime? expireDate,
  }) async {
    final existing = _datasource.getById(id);
    if (existing == null) return;

    final updated = SubscriptionModel(
      id: existing.id,
      name: existing.name,
      url: existing.url,
      userAgent: existing.userAgent,
      uploadBytes: uploadBytes ?? existing.uploadBytes,
      downloadBytes: downloadBytes ?? existing.downloadBytes,
      totalBytes: totalBytes ?? existing.totalBytes,
      expireMillis: expireDate?.millisecondsSinceEpoch ?? existing.expireMillis,
      lastUpdatedMillis: DateTime.now().millisecondsSinceEpoch,
      addedAtMillis: existing.addedAtMillis,
      autoUpdate: existing.autoUpdate,
    );

    await _datasource.save(updated);
  }

  /// Validates a Hive model and converts to domain entity.
  ///
  /// Returns null for corrupted records:
  /// - Missing required fields (id, name, url)
  Subscription? _validateAndConvert(SubscriptionModel model) {
    try {
      // Validate required string fields are non-empty
      if (model.id.isEmpty || model.name.isEmpty || model.url.isEmpty) {
        debugPrint(
          'Warning: Skipping corrupted subscription "${model.id}" — '
          'empty required field',
        );
        return null;
      }

      return model.toDomain();
    } catch (e) {
      debugPrint(
        'Warning: Skipping corrupted subscription "${model.id}" — '
        'conversion error: $e',
      );
      return null;
    }
  }
}
