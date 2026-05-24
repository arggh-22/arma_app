import 'package:flutter_test/flutter_test.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/device_auth_response.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';

void main() {
  group('DeviceAuthResponse', () {
    test('fromJson maps token/is_guest/user_id and announcement fields', () {
      final model = DeviceAuthResponse.fromJson({
        'token': 'opaque_token_123',
        'is_guest': true,
        'user_id': 42,
        'announcement_title': 'Maintenance',
        'announcement_text': 'Tonight at 22:00 UTC',
      });

      expect(model.token, 'opaque_token_123');
      expect(model.isGuest, isTrue);
      expect(model.userId, 42);
      expect(model.announcementTitle, 'Maintenance');
      expect(model.announcementText, 'Tonight at 22:00 UTC');
    });

    test('toDomain maps DTO into AuthState', () {
      final model = DeviceAuthResponse.fromJson({
        'token': 'opaque_token_123',
        'is_guest': false,
        'user_id': 7,
        'announcement_title': 'Title',
        'announcement_text': 'Text body',
      });

      final state = model.toDomain(
        deviceId: 'device-abc',
        expiresAt: DateTime.utc(2026, 5, 24),
      );

      expect(state, isA<AuthState>());
      expect(state.token, 'opaque_token_123');
      expect(state.isAuthenticated, isTrue);
      expect(state.isGuest, isFalse);
      expect(state.userId, 7);
      expect(state.deviceId, 'device-abc');
      expect(state.expiresAt, DateTime.utc(2026, 5, 24));
      expect(state.announcementTitle, 'Title');
      expect(state.announcementText, 'Text body');
    });

    test('fromJson throws FormatException on malformed payload', () {
      expect(
        () => DeviceAuthResponse.fromJson({'token': 123, 'is_guest': true}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => DeviceAuthResponse.fromJson({
          'token': 'opaque_token_123',
          'is_guest': true,
          'user_id': 1,
          'announcement_title': 123,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
