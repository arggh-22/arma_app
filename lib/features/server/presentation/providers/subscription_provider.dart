import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/data/models/subscription_model.dart';
import 'package:arma_proxy_vpn_client/features/server/data/datasources/subscription_local_datasource.dart';
import 'package:arma_proxy_vpn_client/features/server/data/repositories/subscription_repository_impl.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/repositories/subscription_repository.dart';
import 'package:arma_proxy_vpn_client/features/server/data/services/subscription_service.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/server_list_provider.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/active_server_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/presentation/providers/connection_provider.dart';
import 'package:arma_proxy_vpn_client/features/connection/domain/entities/connection_status.dart';

part 'subscription_provider.g.dart';

/// Provides the [SubscriptionRepository] instance backed by Hive.
///
/// Keep-alive so the repository persists for the app's lifetime.
@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) {
  final box = Hive.box<SubscriptionModel>('subscriptions');
  final datasource = SubscriptionLocalDatasource(box);
  return SubscriptionRepositoryImpl(datasource);
}

/// Riverpod notifier managing the subscription lifecycle.
///
/// Exposes methods to add, refresh, and delete subscriptions.
/// Handles:
/// - D-13: Replace ALL servers from a subscription on refresh
/// - D-14: Auto-select first new server if active was in refreshed subscription
/// - D-04 / CONF-07: Auto-refresh on launch for autoUpdate=true subscriptions
@Riverpod(keepAlive: true)
class SubscriptionNotifier extends _$SubscriptionNotifier {
  final SubscriptionService _service = SubscriptionService();

  @override
  List<Subscription> build() {
    final repo = ref.watch(subscriptionRepositoryProvider);
    return repo.getAllSubscriptions();
  }

  /// Add a new subscription: fetch, parse, persist servers, persist metadata.
  ///
  /// Returns the number of servers imported.
  Future<int> addSubscription({
    required String url,
    required String name,
    String userAgent = '',
    bool autoUpdate = true,
  }) async {
    // Use provided name, or defer to profileTitle from subscription response
    // Only use domain as last resort if both are unavailable
    final subscription = Subscription(
      id: const Uuid().v4(),
      name: name.isNotEmpty ? name : '', // Keep empty to prioritize profileTitle
      url: url,
      userAgent: userAgent,
      lastUpdated: DateTime.now(),
      addedAt: DateTime.now(),
      autoUpdate: autoUpdate,
    );

    // Fetch and parse
    final result = await _service.fetch(subscription);
    // Priority: user-provided name > profileTitle from response > domain
    final resolvedName = () {
      if (name.isNotEmpty && name.trim().isNotEmpty) {
        return name.trim();
      }
      if ((result.profileTitle ?? '').trim().isNotEmpty) {
        return result.profileTitle!.trim();
      }
      return Uri.parse(url).host; // Last resort: use domain
    }();
    
    final resolvedAutoUpdate = result.profileUpdateIntervalHours != null
        ? result.profileUpdateIntervalHours! > 0
        : autoUpdate;

    // Update subscription with userinfo data
    final updated = subscription.copyWith(
      name: resolvedName,
      uploadBytes: result.userinfo?.uploadBytes,
      downloadBytes: result.userinfo?.downloadBytes,
      totalBytes: result.userinfo?.totalBytes,
      expireDate: result.userinfo?.expireDate,
      supportUrl: result.supportUrl,
      webPageUrl: result.profileWebPageUrl,
      autoUpdate: resolvedAutoUpdate,
    );

    // Persist subscription metadata
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.saveSubscription(updated);

    // Persist servers
    final serverNotifier = ref.read(serverListProvider.notifier);
    for (final server in result.servers) {
      await serverNotifier.addServer(server);
    }

    ref.invalidateSelf();
    ref.invalidate(serverListProvider);
    return result.servers.length;
  }

  /// Refresh a single subscription (D-13: replace ALL servers).
  ///
  /// D-14: If the active server belongs to this subscription, disconnect
  /// first and auto-select the first new server after refresh.
  ///
  /// Returns the number of servers in the refreshed subscription.
  Future<int> refreshSubscription(String subscriptionId) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    final subscription = repo.getSubscriptionById(subscriptionId);
    if (subscription == null) return 0;

    final result = await _service.fetch(subscription);

    // Guard against wiping the subscription: if the refresh yielded no servers
    // (e.g. a transient failure, or a server that returned an empty/HTML body),
    // keep the existing servers rather than deleting them and adding nothing.
    if (result.servers.isEmpty) {
      return 0;
    }

    final resolvedName = (result.profileTitle ?? '').trim().isNotEmpty
        ? result.profileTitle!.trim()
        : subscription.name;
    final resolvedAutoUpdate = result.profileUpdateIntervalHours != null
        ? result.profileUpdateIntervalHours! > 0
        : subscription.autoUpdate;

    // D-14: Check if active server belongs to this subscription
    final activeServer = ref.read(activeServerProvider);
    final connectionState = ref.read(connectionProvider);
    if (activeServer?.subscriptionId == subscriptionId) {
      // Disconnect if connected
      if (connectionState is Connected) {
        await ref.read(connectionProvider.notifier).disconnect();
      }
    }

    // D-13: Delete ALL old servers from this subscription
    final serverRepo = ref.read(serverRepositoryProvider);
    final allServers = await serverRepo.getAllConfigs();
    for (final server in allServers) {
      if (server.subscriptionId == subscriptionId) {
        await serverRepo.deleteConfig(server.id);
      }
    }

    // Add new servers
    final serverNotifier = ref.read(serverListProvider.notifier);
    for (final server in result.servers) {
      await serverNotifier.addServer(server);
    }

    // Update subscription metadata
    final updated = subscription.copyWith(
      name: resolvedName,
      uploadBytes: result.userinfo?.uploadBytes,
      downloadBytes: result.userinfo?.downloadBytes,
      totalBytes: result.userinfo?.totalBytes,
      expireDate: result.userinfo?.expireDate,
      supportUrl: result.supportUrl,
      webPageUrl: result.profileWebPageUrl,
      lastUpdated: DateTime.now(),
      autoUpdate: resolvedAutoUpdate,
    );
    await repo.saveSubscription(updated);

    // D-14: Auto-select first new server if old active was in this subscription
    if (activeServer?.subscriptionId == subscriptionId &&
        result.servers.isNotEmpty) {
      ref.read(activeServerProvider.notifier).selectServer(result.servers.first);
    }

    ref.invalidateSelf();
    ref.invalidate(serverListProvider);
    return result.servers.length;
  }

  /// Refresh all subscriptions that have autoUpdate enabled (D-04, CONF-07).
  ///
  /// Errors are logged but not propagated — auto-refresh is silent.
  Future<void> refreshAllAutoUpdate() async {
    final subscriptions = state.where((s) => s.autoUpdate).toList();
    for (final sub in subscriptions) {
      try {
        await refreshSubscription(sub.id);
      } catch (e) {
        debugPrint('[SubscriptionNotifier] Failed to refresh ${sub.name}: $e');
      }
    }
  }

  /// Delete a subscription and its associated servers.
  Future<void> deleteSubscription(String id) async {
    final repo = ref.read(subscriptionRepositoryProvider);
    await repo.deleteSubscription(id);

    // Delete associated servers
    final serverRepo = ref.read(serverRepositoryProvider);
    final allServers = await serverRepo.getAllConfigs();
    for (final server in allServers) {
      if (server.subscriptionId == id) {
        await serverRepo.deleteConfig(server.id);
      }
    }

    ref.invalidateSelf();
    ref.invalidate(serverListProvider);
  }
}
