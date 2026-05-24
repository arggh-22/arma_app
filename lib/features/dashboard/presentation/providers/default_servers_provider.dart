import 'dart:async';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_cache_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/default_server_keys_provider.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/data/mappers/default_server_item_mapper.dart';
import 'package:arma_proxy_vpn_client/features/dashboard/domain/entities/default_server_item.dart';
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
  @override
  DefaultServersState build() {
    Future<void>.microtask(_initialLoad);
    return const DefaultServersState.initial();
  }

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    await _load(useRefreshProvider: true);
  }

  Future<void> _initialLoad() async {
    await _load();
  }

  Future<void> _load({bool useRefreshProvider = false}) async {
    try {
      final keys = await _fetchKeys(useRefreshProvider: useRefreshProvider);
      await _persistCache(keys);
      final items = _mapItems(keys);

      state = state.copyWith(
        items: items,
        isRefreshing: false,
        isOfflineData: false,
        resetFailureType: true,
      );
    } on Object catch (error) {
      final failureType = _toFailureType(error);
      final cache = await ref.read(defaultServerCacheDatasourceProvider).read();
      final cachedItems = cache == null ? const <DefaultServerItem>[] : _mapItems(cache.keys);

      state = state.copyWith(
        items: cachedItems,
        isRefreshing: false,
        isOfflineData: cache != null,
        lastFailureType: failureType,
      );
    }
  }

  Future<List<DefaultServerKey>> _fetchKeys({
    required bool useRefreshProvider,
  }) {
    if (useRefreshProvider) {
      return ref.refresh(defaultServerKeysProvider.future);
    }
    return ref.read(defaultServerKeysProvider.future);
  }

  Future<void> _persistCache(List<DefaultServerKey> keys) {
    return ref.read(defaultServerCacheDatasourceProvider).write(
      DefaultServerCacheModel(
        fetchedAt: DateTime.now(),
        keys: keys,
      ),
    );
  }

  List<DefaultServerItem> _mapItems(List<DefaultServerKey> keys) {
    return keys.map(DefaultServerItemMapper.map).toList(growable: false);
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
