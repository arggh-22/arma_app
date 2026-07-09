import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';

/// Persisted snapshot for default server API payloads.
class DefaultServerCacheModel {
  const DefaultServerCacheModel({required this.fetchedAt, required this.keys});

  final DateTime fetchedAt;
  final List<DefaultServerKey> keys;

  Map<String, dynamic> toJson() {
    return {
      'fetchedAt': fetchedAt.toIso8601String(),
      'keys': keys.map((key) => key.toJson()).toList(growable: false),
    };
  }

  factory DefaultServerCacheModel.fromJson(Map<String, dynamic> json) {
    final fetchedAtRaw = json['fetchedAt'];
    final keysRaw = json['keys'];

    if (fetchedAtRaw is! String) {
      throw const FormatException('Invalid cache payload: fetchedAt');
    }
    final fetchedAt = DateTime.tryParse(fetchedAtRaw);
    if (fetchedAt == null) {
      throw const FormatException('Invalid cache payload: fetchedAt');
    }

    if (keysRaw is! List) {
      throw const FormatException('Invalid cache payload: keys');
    }

    final keys = keysRaw
        .map((entry) {
          if (entry is! Map) {
            throw const FormatException('Invalid cache payload: keys');
          }
          return DefaultServerKey.fromJson(Map<String, dynamic>.from(entry));
        })
        .toList(growable: false);

    return DefaultServerCacheModel(fetchedAt: fetchedAt, keys: keys);
  }
}
