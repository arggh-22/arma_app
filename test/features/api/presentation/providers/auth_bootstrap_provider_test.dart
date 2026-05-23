import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/device_auth_response.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_bootstrap_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('authBootstrapProvider', () {
    test(
      'resolves startup auth and key prewarm only once per container lifecycle',
      () async {
        var keyFetchCalls = 0;
        final apiClient = ApiClient(
          client: MockClient((request) async {
            if (request.url.path.endsWith('/keys/')) {
              keyFetchCalls++;
            }
            return http.Response(
              '[{"id":1,"name":"Main","key_body":"vless://example","subscription_url":"https://example.com/sub","expire_date":"2026-05-24T18:30:00Z","is_active":true,"status":"active","used_traffic":10,"data_limit":20}]',
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
          baseUrl: 'https://example.com/api/v1',
        );
        final fakeRepository = _FakeAuthRepository();
        final container = ProviderContainer(
          overrides: [
            apiClientProvider.overrideWithValue(apiClient),
            authRepositoryProvider.overrideWithValue(fakeRepository),
          ],
        );
        addTearDown(container.dispose);

        await container.read(authBootstrapProvider.future);
        await container.read(authBootstrapProvider.future);

        expect(fakeRepository.getValidTokenCalls, 2);
        expect(keyFetchCalls, 1);
      },
    );

    test('surfaces typed auth errors from provider graph', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(
              failure: const AuthRepositoryException(
                type: AuthRepositoryFailureType.authenticationFailed,
                message: 'failed',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(authBootstrapProvider.future),
        throwsA(
          isA<AuthRepositoryException>().having(
            (error) => error.type,
            'type',
            AuthRepositoryFailureType.authenticationFailed,
          ),
        ),
      );
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failure});

  final AuthRepositoryException? failure;
  int getValidTokenCalls = 0;

  @override
  Future<AuthState> authenticateDevice() async {
    throw UnimplementedError();
  }

  @override
  Future<T> executeWithAuthRetry<T>(Future<T> Function(String token) action) async {
    final token = await getValidToken();
    return action(token);
  }

  @override
  Future<String> getValidToken() async {
    getValidTokenCalls++;
    if (failure case final error?) {
      throw error;
    }
    return 'startup-token';
  }
}
