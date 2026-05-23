import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_key_model.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/default_server_key.dart';

void main() {
  group('DefaultServerKeyModel', () {
    test(
      'fromJson maps key_body/expire_date/status/used_traffic/data_limit',
      () {
        final model = DefaultServerKeyModel.fromJson({
          'id': 15,
          'name': 'Trial #1',
          'key_body': 'vless://example',
          'subscription_url': 'https://your-domain.com/sub/user_42_abcdef',
          'expire_date': '2026-05-24T18:30:00Z',
          'is_active': true,
          'status': 'active',
          'used_traffic': 104857600,
          'data_limit': 5368709120,
        });

        expect(model.keyBody, 'vless://example');
        expect(model.expireDate, DateTime.parse('2026-05-24T18:30:00Z'));
        expect(model.status, 'active');
        expect(model.usedTraffic, 104857600);
        expect(model.dataLimit, 5368709120);
      },
    );

    test('toDomain maps DTO into DefaultServerKey', () {
      final model = DefaultServerKeyModel.fromJson({
        'id': 15,
        'name': 'Trial #1',
        'key_body': 'vless://example',
        'subscription_url': 'https://your-domain.com/sub/user_42_abcdef',
        'expire_date': '2026-05-24T18:30:00Z',
        'is_active': true,
        'status': 'active',
        'used_traffic': 104857600,
        'data_limit': 5368709120,
      });

      final key = model.toDomain();

      expect(key, isA<DefaultServerKey>());
      expect(key.id, 15);
      expect(key.name, 'Trial #1');
      expect(key.keyBody, 'vless://example');
      expect(key.subscriptionUrl, 'https://your-domain.com/sub/user_42_abcdef');
      expect(key.expireDate, DateTime.parse('2026-05-24T18:30:00Z'));
      expect(key.isActive, isTrue);
      expect(key.status, 'active');
      expect(key.usedTraffic, 104857600);
      expect(key.dataLimit, 5368709120);
    });

    test('fromJson throws FormatException on malformed payload', () {
      expect(
        () => DefaultServerKeyModel.fromJson({'id': '15'}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
