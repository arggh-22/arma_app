import 'dart:async';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/services/default_server_refresh_service.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_cache_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/data/mappers/default_server_item_mapper.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
import 'package:arma_proxy_vpn_client/features/server/data/services/subscription_service.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'default_servers_provider.g.dart';

enum DefaultServersFailureType {
  timeout,
  offline,
  unauthorized,
  server,
  client,
  malformedResponse,
  unknown,
}

DefaultServersFailureType mapDefaultServersFailureType(Object error) {
  if (error is ApiClientException) {
    return switch (error.type) {
      ApiClientErrorType.timeout => DefaultServersFailureType.timeout,
      ApiClientErrorType.network => DefaultServersFailureType.offline,
      ApiClientErrorType.unauthorized => DefaultServersFailureType.unauthorized,
      ApiClientErrorType.server => DefaultServersFailureType.server,
      ApiClientErrorType.client => DefaultServersFailureType.client,
      ApiClientErrorType.malformedResponse =>
        DefaultServersFailureType.malformedResponse,
      ApiClientErrorType.unknown => DefaultServersFailureType.unknown,
    };
  }
  return DefaultServersFailureType.unknown;
}

typedef DefaultServersRetryDelay = Future<void> Function(Duration duration);

final defaultServersRetryScheduleProvider = Provider<List<Duration>>(
  (ref) => const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
  ],
);

final defaultServersRetryDelayProvider = Provider<DefaultServersRetryDelay>(
  (ref) =>
      (duration) => Future<void>.delayed(duration),
);

final defaultServersSubscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) => SubscriptionService(),
);

class DefaultServersState {
  const DefaultServersState({
    required this.items,
    required this.isRefreshing,
    required this.isOfflineData,
    required this.lastFailureType,
    required this.hasPendingRetry,
    required this.retryAttempt,
  });

  const DefaultServersState.initial()
    : items = const [],
      isRefreshing = false,
      isOfflineData = false,
      lastFailureType = null,
      hasPendingRetry = false,
      retryAttempt = 0;

  final List<DefaultServerItem> items;
  final bool isRefreshing;
  final bool isOfflineData;
  final DefaultServersFailureType? lastFailureType;
  final bool hasPendingRetry;
  final int retryAttempt;

  DefaultServersState copyWith({
    List<DefaultServerItem>? items,
    bool? isRefreshing,
    bool? isOfflineData,
    DefaultServersFailureType? lastFailureType,
    bool resetFailureType = false,
    bool? hasPendingRetry,
    int? retryAttempt,
  }) {
    return DefaultServersState(
      items: items ?? this.items,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOfflineData: isOfflineData ?? this.isOfflineData,
      lastFailureType: resetFailureType
          ? null
          : lastFailureType ?? this.lastFailureType,
      hasPendingRetry: hasPendingRetry ?? this.hasPendingRetry,
      retryAttempt: retryAttempt ?? this.retryAttempt,
    );
  }
}

@Riverpod(keepAlive: true)
class DefaultServersNotifier extends _$DefaultServersNotifier {
  bool _retryLoopRunning = false;

  @override
  DefaultServersState build() {
    Future<void>.microtask(_initialLoad);
    return const DefaultServersState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    await _load(triggerRetryQueue: true);
  }

  Future<void> _initialLoad() => _load();

  Future<void> _load({bool triggerRetryQueue = false}) async {
    try {
      final refreshResult = await ref
          .read(defaultServerRefreshServiceProvider)
          .refreshNow();
      final items = await _mapItems(refreshResult.keys);

      state = state.copyWith(
        items: items,
        isRefreshing: false,
        isOfflineData: false,
        resetFailureType: true,
        hasPendingRetry: false,
      );
    } on Object catch (error) {
      final failureType = _toFailureType(error);
      final cache = await ref.read(defaultServerCacheDatasourceProvider).read();
      final cachedItems = cache == null
          ? const <DefaultServerItem>[]
          : cache.keys
                .expand(DefaultServerItemMapper.mapAll)
                .toList(growable: false);

      state = state.copyWith(
        items: cachedItems,
        isRefreshing: false,
        isOfflineData: cache != null,
        lastFailureType: failureType,
      );

      final shouldRetryQueue =
          triggerRetryQueue &&
          !_looksUnauthorized(error) &&
          (_isRetryEligible(failureType, error: error) ||
              (failureType == DefaultServersFailureType.unknown &&
                  cache != null));
      if (shouldRetryQueue) {
        _startRetryQueue();
      }
    }
  }

  Future<List<DefaultServerItem>> _mapItems(List<DefaultServerKey> keys) async {
    final service = ref.read(defaultServersSubscriptionServiceProvider);
    final allItems = <DefaultServerItem>[];

    for (final key in keys) {
      try {
        final resolved = await service.fetch(_toSyntheticSubscription(key));
        allItems.addAll(
          DefaultServerItemMapper.mapResolved(key, resolved.servers),
        );
      } on Object {
        allItems.addAll(DefaultServerItemMapper.mapAll(key));
      }
    }

    return allItems;
  }

  Subscription _toSyntheticSubscription(DefaultServerKey key) {
    final syntheticTimestamp = DateTime.fromMillisecondsSinceEpoch(0);
    return Subscription(
      id: 'default-api-key-${key.id}',
      name: key.name,
      url: key.subscriptionUrl,
      // Client UA is required — a browser UA makes the arma backend redirect
      // to an HTML page instead of serving the subscription (see
      // SubscriptionService._defaultUserAgent).
      userAgent: 'arma',
      lastUpdated: syntheticTimestamp,
      addedAt: syntheticTimestamp,
      autoUpdate: false,
    );
  }

  bool _isRetryEligible(
    DefaultServersFailureType failureType, {
    Object? error,
  }) {
    if (failureType == DefaultServersFailureType.timeout ||
        failureType == DefaultServersFailureType.offline) {
      return true;
    }

    if (error != null) {
      final raw = error.toString().toLowerCase();
      return raw.contains('timeout') ||
          raw.contains('network') ||
          raw.contains('offline');
    }

    return false;
  }

  bool _looksUnauthorized(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('unauthorized') || raw.contains('401');
  }

  void _startRetryQueue() {
    if (_retryLoopRunning) {
      return;
    }

    _retryLoopRunning = true;
    state = state.copyWith(hasPendingRetry: true, retryAttempt: 0);
    Future<void>.microtask(_runRetryQueue);
  }

  Future<void> _runRetryQueue() async {
    final delays = ref.read(defaultServersRetryScheduleProvider);
    for (var attempt = 0; attempt < delays.length; attempt++) {
      await ref.read(defaultServersRetryDelayProvider)(delays[attempt]);
      if (!ref.mounted) {
        return;
      }

      state = state.copyWith(
        hasPendingRetry: true,
        retryAttempt: attempt + 1,
        isRefreshing: true,
      );

      await _load(triggerRetryQueue: false);
      if (!ref.mounted) {
        return;
      }

      final failureType = state.lastFailureType;
      final shouldContinue =
          failureType != null &&
          (_isRetryEligible(failureType) ||
              (failureType == DefaultServersFailureType.unknown &&
                  state.isOfflineData));
      if (!shouldContinue) {
        break;
      }
    }

    if (ref.mounted) {
      state = state.copyWith(hasPendingRetry: false);
    }
    _retryLoopRunning = false;
  }

  DefaultServersFailureType _toFailureType(Object error) {
    final resolvedError = _unwrapFailure(error);
    final mapped = mapDefaultServersFailureType(resolvedError);
    if (mapped != DefaultServersFailureType.unknown) {
      return mapped;
    }

    final raw = resolvedError.toString();
    if (raw.contains('ApiClientErrorType.timeout')) {
      return DefaultServersFailureType.timeout;
    }
    if (raw.contains('ApiClientErrorType.network')) {
      return DefaultServersFailureType.offline;
    }
    if (raw.contains('ApiClientErrorType.unauthorized')) {
      return DefaultServersFailureType.unauthorized;
    }
    if (raw.contains('ApiClientErrorType.server')) {
      return DefaultServersFailureType.server;
    }
    if (raw.contains('ApiClientErrorType.client')) {
      return DefaultServersFailureType.client;
    }
    if (raw.contains('ApiClientErrorType.malformedResponse')) {
      return DefaultServersFailureType.malformedResponse;
    }

    return DefaultServersFailureType.unknown;
  }

  Object _unwrapFailure(Object error) {
    var current = error;
    final visited = <Object>{};

    while (visited.add(current)) {
      final dynamic value = current;

      try {
        final nestedException = value.exception;
        if (nestedException is Object) {
          current = nestedException;
          continue;
        }
      } catch (_) {}

      try {
        final nestedError = value.error;
        if (nestedError is Object) {
          current = nestedError;
          continue;
        }
      } catch (_) {}

      break;
    }

    return current;
  }
}
