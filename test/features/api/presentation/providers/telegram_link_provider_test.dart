import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/repositories/telegram_link_repository_impl.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/auth_state.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/telegram_link_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/telegram_link_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('telegram link providers', () {
    test('telegramLinkRepositoryProvider resolves repository implementation', () {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(client: http.Client())),
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(telegramLinkRepositoryProvider);

      expect(repository, isA<TelegramLinkRepositoryImpl>());
    });

    test('submit delegates to telegram link repository', () async {
      final fakeRepository = _FakeTelegramLinkRepository();
      final container = ProviderContainer(
        overrides: [
          telegramLinkRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(telegramLinkProvider.notifier);
      final outcome = await notifier.submit('12345');

      expect(fakeRepository.calls, 1);
      expect(fakeRepository.lastTelegramId, '12345');
      expect(outcome.type, TelegramLinkOutcomeType.linked);
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthState> authenticateDevice() {
    throw UnimplementedError();
  }

  @override
  Future<T> executeWithAuthRetry<T>(Future<T> Function(String token) action) {
    throw UnimplementedError();
  }

  @override
  Future<String> getValidToken() {
    throw UnimplementedError();
  }
}

class _FakeTelegramLinkRepository implements TelegramLinkRepository {
  int calls = 0;
  String? lastTelegramId;

  @override
  Future<TelegramLinkOutcome> linkTelegram(String telegramId) async {
    calls++;
    lastTelegramId = telegramId;
    return const TelegramLinkOutcome(type: TelegramLinkOutcomeType.linked);
  }
}
