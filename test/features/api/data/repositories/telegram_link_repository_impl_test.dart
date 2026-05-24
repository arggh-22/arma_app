import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/default_server_key_model.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/device_auth_response.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/telegram_link_response.dart';
import 'package:arma_proxy_vpn_client/features/api/data/repositories/telegram_link_repository_impl.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

void main() {
  group('TelegramLinkRepositoryImpl', () {
    late _StubApiClient apiClient;
    late _StubAuthRepository authRepository;
    late TelegramLinkRepositoryImpl repository;

    setUp(() {
      apiClient = _StubApiClient();
      authRepository = _StubAuthRepository();
      repository = TelegramLinkRepositoryImpl(
        apiClient: apiClient,
        authRepository: authRepository,
      );
    });

    test('returns linked outcome when API status is linked', () async {
      apiClient.linkHandler = ({required token, required telegramId}) async {
        return const TelegramLinkResponse(
          detail: 'Link request sent',
          status: 'linked',
        );
      };

      final outcome = await repository.linkTelegram('123456789');

      expect(outcome.type, TelegramLinkOutcomeType.linked);
      expect(authRepository.executeCalls, 1);
      expect(apiClient.lastToken, 'repo-token');
      expect(apiClient.lastTelegramId, '123456789');
    });

    test(
      'returns already_linked outcome when API status indicates already linked',
      () async {
        apiClient.linkHandler = ({required token, required telegramId}) async {
          return const TelegramLinkResponse(
            detail: 'Telegram is already linked',
            status: 'already_linked',
          );
        };

        final outcome = await repository.linkTelegram('123456789');

        expect(outcome.type, TelegramLinkOutcomeType.alreadyLinked);
      },
    );

    test('maps unauthorizedAfterRetry to unauthorized outcome', () async {
      authRepository.executeError = const AuthRepositoryException(
        type: AuthRepositoryFailureType.unauthorizedAfterRetry,
        message: 'Unauthorized after retry',
      );

      final outcome = await repository.linkTelegram('123456789');

      expect(outcome.type, TelegramLinkOutcomeType.unauthorized);
      expect(apiClient.lastTelegramId, isNull);
    });

    test('maps network/timeout failures to network outcome', () async {
      apiClient.linkError = const ApiClientException(
        type: ApiClientErrorType.network,
        message: 'network',
      );

      final networkOutcome = await repository.linkTelegram('123456789');

      expect(networkOutcome.type, TelegramLinkOutcomeType.network);

      apiClient.linkError = const ApiClientException(
        type: ApiClientErrorType.timeout,
        message: 'timeout',
      );
      final timeoutOutcome = await repository.linkTelegram('123456789');
      expect(timeoutOutcome.type, TelegramLinkOutcomeType.network);
    });

    test('maps server failures to server outcome', () async {
      apiClient.linkError = const ApiClientException(
        type: ApiClientErrorType.server,
        message: 'server',
        statusCode: 500,
      );

      final outcome = await repository.linkTelegram('123456789');

      expect(outcome.type, TelegramLinkOutcomeType.server);
    });

    test('maps client 400 to invalid_id outcome', () async {
      apiClient.linkError = const ApiClientException(
        type: ApiClientErrorType.client,
        message: 'bad request',
        statusCode: 400,
      );

      final outcome = await repository.linkTelegram('123456789');

      expect(outcome.type, TelegramLinkOutcomeType.invalidId);
    });

    test('maps client 409 to already_linked outcome', () async {
      apiClient.linkError = const ApiClientException(
        type: ApiClientErrorType.client,
        message: 'conflict',
        statusCode: 409,
      );

      final outcome = await repository.linkTelegram('123456789');

      expect(outcome.type, TelegramLinkOutcomeType.alreadyLinked);
    });

    test('maps unknown failures to unknown outcome', () async {
      apiClient.linkError = const ApiClientException(
        type: ApiClientErrorType.malformedResponse,
        message: 'bad payload',
      );

      final malformedOutcome = await repository.linkTelegram('123456789');
      expect(malformedOutcome.type, TelegramLinkOutcomeType.unknown);

      authRepository.executeError = const AuthRepositoryException(
        type: AuthRepositoryFailureType.authenticationFailed,
        message: 'auth failed',
      );
      final authOutcome = await repository.linkTelegram('123456789');
      expect(authOutcome.type, TelegramLinkOutcomeType.unknown);
    });

    test('maps unexpected thrown exceptions to unknown outcome', () async {
      apiClient.linkHandler = ({required token, required telegramId}) async {
        throw StateError('unexpected');
      };

      final outcome = await repository.linkTelegram('123456789');

      expect(outcome.type, TelegramLinkOutcomeType.unknown);
      expect(outcome.message, contains('unexpected'));
    });
  });
}

class _StubAuthRepository implements AuthRepository {
  int executeCalls = 0;
  AuthRepositoryException? executeError;

  @override
  Future<AuthState> authenticateDevice() {
    throw UnimplementedError();
  }

  @override
  Future<T> executeWithAuthRetry<T>(
    Future<T> Function(String token) action,
  ) async {
    executeCalls++;
    if (executeError case final AuthRepositoryException error?) {
      throw error;
    }
    return action('repo-token');
  }

  @override
  Future<String> getValidToken() {
    throw UnimplementedError();
  }
}

class _StubApiClient extends ApiClient {
  _StubApiClient()
    : super(
        client: MockClient((_) async => throw UnimplementedError()),
        baseUrl: 'https://example.com/api/v1',
      );

  Future<TelegramLinkResponse> Function({
    required String token,
    required String telegramId,
  })?
  linkHandler;
  ApiClientException? linkError;
  String? lastToken;
  String? lastTelegramId;

  @override
  Future<DeviceAuthResponse> authenticateDevice({
    required String deviceId,
    required String osType,
    required String appVersion,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<DefaultServerKeyModel>> getKeys(String token) {
    throw UnimplementedError();
  }

  @override
  Future<TelegramLinkResponse> linkTelegram({
    required String token,
    required String telegramId,
  }) async {
    lastToken = token;
    lastTelegramId = telegramId;
    if (linkError case final ApiClientException error?) {
      throw error;
    }
    final handler = linkHandler;
    if (handler != null) {
      return handler(token: token, telegramId: telegramId);
    }
    return const TelegramLinkResponse(
      detail: 'Link request sent',
      status: 'linked',
    );
  }
}
