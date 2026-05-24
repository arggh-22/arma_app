import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_cache_model.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultServerCacheModel', () {
    test('round-trips fetchedAt and API key fields', () {
      final fetchedAt = DateTime.utc(2026, 5, 24, 12, 0, 0);
      final model = DefaultServerCacheModel(
        fetchedAt: fetchedAt,
        keys: [
          DefaultServerKey(
            id: 7,
            name: 'Default #7',
            keyBody: 'vless://test',
            subscriptionUrl: 'https://example.com/sub/7',
            expireDate: DateTime.utc(2026, 6, 1),
            isActive: true,
            status: 'active',
            usedTraffic: 10,
            dataLimit: 100,
          ),
        ],
      );

      final restored = DefaultServerCacheModel.fromJson(model.toJson());

      expect(restored.fetchedAt, fetchedAt);
      expect(restored.keys.single.id, 7);
      expect(restored.keys.single.subscriptionUrl, 'https://example.com/sub/7');
      expect(restored.keys.single.expireDate, DateTime.utc(2026, 6, 1));
    });
  });
}
