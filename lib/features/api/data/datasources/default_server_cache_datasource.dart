import 'dart:convert';

import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:hive_ce/hive_ce.dart';

/// Hive-backed persistence for default server API snapshots.
class DefaultServerCacheDatasource {
  const DefaultServerCacheDatasource(this._box);

  static const boxName = 'default_server_cache';
  static const storageKey = 'snapshot';

  final Box<dynamic> _box;

  Future<DefaultServerCacheModel?> read() async {
    try {
      final raw = _box.get(storageKey);
      if (raw == null) {
        return null;
      }

      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return DefaultServerCacheModel.fromJson(decoded);
        }
      }

      if (raw is Map) {
        return DefaultServerCacheModel.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {
      // Corrupt payloads degrade to no-cache.
      await clear();
    }

    return null;
  }

  Future<void> write(DefaultServerCacheModel cache) =>
      _box.put(storageKey, jsonEncode(cache.toJson()));

  Future<void> clear() => _box.delete(storageKey);
}
