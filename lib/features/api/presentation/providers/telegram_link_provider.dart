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
  Future<TelegramLinkOutcome>? _activeSubmit;

  @override
  TelegramLinkState build() {
    _repository = ref.watch(telegramLinkRepositoryProvider);
    return const TelegramLinkState.initial();
  }

  Future<TelegramLinkOutcome> submit(String telegramId) async {
    final inFlight = _activeSubmit;
    if (inFlight != null) {
      return inFlight;
    }

    final normalizedId = telegramId.trim();
    final validationFailure = _validate(normalizedId);
    if (validationFailure != null) {
      state = state.copyWith(
        isSubmitting: false,
        lastOutcome: validationFailure,
        lastSubmittedId: normalizedId,
      );
      return validationFailure;
    }

    state = state.copyWith(
      isSubmitting: true,
      lastSubmittedId: normalizedId,
    );
    final submit = _submitValidated(normalizedId);
    _activeSubmit = submit;
    return submit;
  }

  Future<TelegramLinkOutcome> _submitValidated(String normalizedId) async {
    try {
      final outcome = await _repository.linkTelegram(normalizedId);
      state = state.copyWith(
        isSubmitting: false,
        lastOutcome: outcome,
        lastSubmittedId: normalizedId,
      );
      return outcome;
    } catch (_) {
      const fallback = TelegramLinkOutcome(type: TelegramLinkOutcomeType.unknown);
      state = state.copyWith(
        isSubmitting: false,
        lastOutcome: fallback,
        lastSubmittedId: normalizedId,
      );
      return fallback;
    } finally {
      _activeSubmit = null;
    }
  }

  TelegramLinkOutcome? _validate(String telegramId) {
    if (telegramId.length < 5 || telegramId.length > 20) {
      return const TelegramLinkOutcome(type: TelegramLinkOutcomeType.invalidId);
    }
    final digitsOnly = RegExp(r'^\d+$');
    if (!digitsOnly.hasMatch(telegramId)) {
      return const TelegramLinkOutcome(type: TelegramLinkOutcomeType.invalidId);
    }
    return null;
  }
}
