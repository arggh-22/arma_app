import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/telegram_link_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TelegramLinkState {
  const TelegramLinkState({
    required this.isSubmitting,
    this.lastOutcome,
    this.lastSubmittedId,
  });

  const TelegramLinkState.initial() : this(isSubmitting: false);

  final bool isSubmitting;
  final TelegramLinkOutcome? lastOutcome;
  final String? lastSubmittedId;

  TelegramLinkState copyWith({
    bool? isSubmitting,
    TelegramLinkOutcome? lastOutcome,
    String? lastSubmittedId,
  }) {
    return TelegramLinkState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      lastSubmittedId: lastSubmittedId ?? this.lastSubmittedId,
    );
  }
}

final telegramLinkProvider =
    NotifierProvider<TelegramLinkNotifier, TelegramLinkState>(
      TelegramLinkNotifier.new,
    );

class TelegramLinkNotifier extends Notifier<TelegramLinkState> {
  late final TelegramLinkRepository _repository;

  @override
  TelegramLinkState build() {
    _repository = ref.watch(telegramLinkRepositoryProvider);
    return const TelegramLinkState.initial();
  }

  Future<TelegramLinkOutcome> submit(String telegramId) async {
    state = state.copyWith(isSubmitting: true);
    final outcome = await _repository.linkTelegram(telegramId);
    state = state.copyWith(
      isSubmitting: false,
      lastOutcome: outcome,
      lastSubmittedId: telegramId,
    );
    return outcome;
  }
}
