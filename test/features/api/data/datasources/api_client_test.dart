import 'dart:io';

import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_key_model.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/device_auth_response.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/telegram_link_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('authenticateDevice sends spec body and X-API-Key header', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"token":"token-123","is_guest":true,"user_id":42}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
        apiKey: 'test-api-key',
      );

      final response = await apiClient.authenticateDevice(
        deviceId: 'device-abc-123',
        osType: 'android',
        appVersion: '1.2.3',
      );

      expect(response, isA<DeviceAuthResponse>());
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.toString(), 'https://example.com/api/v1/auth/device/');
      expect(capturedRequest.headers['X-API-Key'], 'test-api-key');
      expect(capturedRequest.headers['content-type'], 'application/json');
      expect(
        capturedRequest.body,
        '{"device_id":"device-abc-123","os_type":"android","app_version":"1.2.3"}',
      );
    });

    test('getKeys sends Authorization Token header and maps response list', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '[{"id":1,"name":"Main","key_body":"vless://example","subscription_url":"https://example.com/sub","expire_date":"2026-05-24T18:30:00Z","is_active":true,"status":"active","used_traffic":10,"data_limit":20}]',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
      );

      final keys = await apiClient.getKeys('token-abc');

      expect(capturedRequest.method, 'GET');
      expect(capturedRequest.url.toString(), 'https://example.com/api/v1/keys/');
      expect(capturedRequest.headers['Authorization'], 'Token token-abc');
      expect(keys, isA<List<DefaultServerKeyModel>>());
      expect(keys, hasLength(1));
    });

    test('retries once for transient 5xx then succeeds', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('{"detail":"temporary"}', 503);
        }
        return http.Response(
          '{"token":"token-123","is_guest":false,"user_id":8}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
        retryDelay: Duration.zero,
      );

      final response = await apiClient.authenticateDevice(
        deviceId: 'device-xyz',
        osType: 'android',
        appVersion: '1.2.3',
      );

      expect(response.userId, 8);
      expect(attempts, 2);
    });

    test('retries once for network errors then succeeds', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        if (attempts == 1) {
          throw const SocketException('network unavailable');
        }
        return http.Response(
          '{"token":"token-123","is_guest":false,"user_id":8}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
        retryDelay: Duration.zero,
      );

      await apiClient.authenticateDevice(
        deviceId: 'device-xyz',
        osType: 'android',
        appVersion: '1.2.3',
      );

      expect(attempts, 2);
    });

    test('does not retry 401 and error message is redacted', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        return http.Response('{"detail":"unauthorized"}', 401);
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
        retryDelay: Duration.zero,
      );

      final call = apiClient.getKeys('token-secret-very-long');
      await expectLater(
        call,
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message.contains('token-secret-very-long'), 'contains token', isFalse),
        ),
      );
      expect(attempts, 1);
    });

    test('linkTelegram sends bearer auth and telegram_id payload', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          '{"detail":"Link request sent","status":"linked"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
      );

      final response = await apiClient.linkTelegram(
        token: 'bearer-token-123',
        telegramId: '123456789',
      );

      expect(response, isA<TelegramLinkResponse>());
      expect(response.status, 'linked');
      expect(capturedRequest.method, 'POST');
      expect(
        capturedRequest.url.toString(),
        'https://example.com/api/v1/auth/telegram/link/',
      );
      expect(capturedRequest.headers['Authorization'], 'Bearer bearer-token-123');
      expect(capturedRequest.headers['content-type'], 'application/json');
      expect(capturedRequest.body, '{"telegram_id":"123456789"}');
    });

    test('linkTelegram retries once for transient 5xx then succeeds', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('{"detail":"temporary"}', 503);
        }
        return http.Response(
          '{"detail":"Link request sent","status":"linked"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
        retryDelay: Duration.zero,
      );

      final response = await apiClient.linkTelegram(
        token: 'bearer-token-123',
        telegramId: '123456789',
      );

      expect(response.status, 'linked');
      expect(attempts, 2);
    });

    test('linkTelegram does not retry 401 unauthorized', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        return http.Response('{"detail":"unauthorized"}', 401);
      });
      final apiClient = ApiClient(
        client: client,
        baseUrl: 'https://example.com/api/v1',
        retryDelay: Duration.zero,
      );

      final call = apiClient.linkTelegram(
        token: 'bearer-token-secret-very-long',
        telegramId: '123456789',
      );
      await expectLater(
        call,
        throwsA(
          isA<ApiClientException>()
              .having((e) => e.type, 'type', ApiClientErrorType.unauthorized)
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(attempts, 1);
    });
  });
}
