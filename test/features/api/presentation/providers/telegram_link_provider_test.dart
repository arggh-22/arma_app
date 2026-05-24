import 'dart:async';

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

    test('submit trims input before repository call', () async {
      final fakeRepository = _FakeTelegramLinkRepository();
      final container = ProviderContainer(
        overrides: [
          telegramLinkRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(telegramLinkProvider.notifier);
      await notifier.submit('  12345  ');

      expect(fakeRepository.calls, 1);
      expect(fakeRepository.lastTelegramId, '12345');
      expect(container.read(telegramLinkProvider).lastSubmittedId, '12345');
    });

    test('submit rejects non-digit telegram ids before network call', () async {
      final fakeRepository = _FakeTelegramLinkRepository();
      final container = ProviderContainer(
        overrides: [
          telegramLinkRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(telegramLinkProvider.notifier);
      final outcome = await notifier.submit('123a5');

      expect(outcome.type, TelegramLinkOutcomeType.invalidId);
      expect(fakeRepository.calls, 0);
      expect(container.read(telegramLinkProvider).isSubmitting, isFalse);
    });

    test('submit rejects ids outside 5..20 digit length range', () async {
      final fakeRepository = _FakeTelegramLinkRepository();
      final container = ProviderContainer(
        overrides: [
          telegramLinkRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(telegramLinkProvider.notifier);
      final shortOutcome = await notifier.submit('1234');
      final longOutcome = await notifier.submit('123456789012345678901');

      expect(shortOutcome.type, TelegramLinkOutcomeType.invalidId);
      expect(longOutcome.type, TelegramLinkOutcomeType.invalidId);
      expect(fakeRepository.calls, 0);
    });

    test('submit blocks duplicate in-flight requests', () async {
      final completer = Completer<TelegramLinkOutcome>();
      final fakeRepository = _FakeTelegramLinkRepository(
        responder: (_) => completer.future,
      );
      final container = ProviderContainer(
        overrides: [
          telegramLinkRepositoryProvider.overrideWithValue(fakeRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(telegramLinkProvider.notifier);
      final first = notifier.submit('12345');
      final second = notifier.submit('12345');
      await Future<void>.delayed(Duration.zero);

      expect(fakeRepository.calls, 1);

      completer.complete(
        const TelegramLinkOutcome(type: TelegramLinkOutcomeType.linked),
      );
      await first;
      await second;
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
  _FakeTelegramLinkRepository({
    Future<TelegramLinkOutcome> Function(String telegramId)? responder,
  }) : _responder = responder;

  final Future<TelegramLinkOutcome> Function(String telegramId)? _responder;
  int calls = 0;
  String? lastTelegramId;

  @override
  Future<TelegramLinkOutcome> linkTelegram(String telegramId) async {
    calls++;
    lastTelegramId = telegramId;
    if (_responder != null) {
      return _responder(telegramId);
    }
    return const TelegramLinkOutcome(type: TelegramLinkOutcomeType.linked);
  }
}
