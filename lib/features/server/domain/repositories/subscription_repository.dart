import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';

/// Abstract interface for subscription persistence.
///
/// Implemented by [SubscriptionRepositoryImpl] which delegates to
/// [SubscriptionLocalDatasource] backed by a Hive box.
abstract class SubscriptionRepository {
  /// Returns all stored subscriptions.
  List<Subscription> getAllSubscriptions();

  /// Returns the subscription with the given [id], or null if not found.
  Subscription? getSubscriptionById(String id);

  /// Persists a subscription (upserts by [Subscription.id]).
  Future<void> saveSubscription(Subscription subscription);

  /// Deletes the subscription with the given [id].
  Future<void> deleteSubscription(String id);

  /// Updates subscription usage info from the subscription-userinfo header.
  Future<void> updateSubscriptionInfo(
    String id, {
    int? uploadBytes,
    int? downloadBytes,
    int? totalBytes,
    DateTime? expireDate,
  });
}
