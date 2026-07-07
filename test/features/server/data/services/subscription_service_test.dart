import 'package:arma_proxy_vpn_client/features/server/data/services/subscription_service.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription _sub(String url) => Subscription(
      id: 'sub-1',
      name: 'Test',
      url: url,
      userAgent: 'arma',
      lastUpdated: DateTime.utc(2026, 1, 1),
      addedAt: DateTime.utc(2026, 1, 1),
    );

const _shareLinkBody =
    'vless://uuid@example.com:443?type=tcp&security=none#Node';

void main() {
  group('SubscriptionService format=json fallback', () {
    test('uses ?format=json when the server accepts it', () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.toString());
        return http.Response(_shareLinkBody, 200);
      });

      final result = await SubscriptionService(client: client).fetch(
        _sub('https://example.com/sub/TOKEN'),
      );

      expect(requested, ['https://example.com/sub/TOKEN?format=json']);
      expect(result.servers, hasLength(1));
    });

    test('retries the plain URL when ?format=json returns non-200', () async {
      final requested = <String>[];
      final client = MockClient((request) async {
        requested.add(request.url.toString());
        // Reject the extra query param, succeed on the untouched URL.
        if (request.url.queryParameters.containsKey('format')) {
          return http.Response('bad request', 400);
        }
        return http.Response(_shareLinkBody, 200);
      });

      final result = await SubscriptionService(client: client).fetch(
        _sub('https://example.com/sub/TOKEN'),
      );

      expect(requested, [
        'https://example.com/sub/TOKEN?format=json',
        'https://example.com/sub/TOKEN',
      ]);
      expect(result.servers, hasLength(1));
    });

    test('throws when both the JSON and plain requests fail', () async {
      final client = MockClient((request) async => http.Response('nope', 400));

      expect(
        () => SubscriptionService(client: client)
            .fetch(_sub('https://example.com/sub/TOKEN')),
        throwsA(isA<Exception>()),
      );
    });
  });
}
