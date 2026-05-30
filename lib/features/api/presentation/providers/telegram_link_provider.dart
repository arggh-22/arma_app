import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/telegram_link_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TelegramLinkState {
  const TelegramLinkState({
    required this.isSubmitting,
    this.isLinked = false,
    this.lastOutcome,
    this.lastSubmittedCode,
  });

  const TelegramLinkState.initial() : this(isSubmitting: false);

  final bool isSubmitting;
  final bool isLinked;
  final TelegramLinkOutcome? lastOutcome;
  final String? lastSubmittedCode;

  TelegramLinkState copyWith({
    bool? isSubmitting,
    bool? isLinked,
    TelegramLinkOutcome? lastOutcome,
    String? lastSubmittedCode,
  }) {
    return TelegramLinkState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLinked: isLinked ?? this.isLinked,
      lastOutcome: lastOutcome ?? this.lastOutcome,
      lastSubmittedCode: lastSubmittedCode ?? this.lastSubmittedCode,
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

  Future<TelegramLinkOutcome> submit(String code) async {
    final inFlight = _activeSubmit;
    if (inFlight != null) {
      return inFlight;
    }

    final normalizedCode = code.trim();
    final validationFailure = _validate(normalizedCode);
    if (validationFailure != null) {
      state = state.copyWith(
        isSubmitting: false,
        lastOutcome: validationFailure,
        lastSubmittedCode: normalizedCode,
      );
      return validationFailure;
    }

    state = state.copyWith(
      isSubmitting: true,
      lastSubmittedCode: normalizedCode,
    );
    final submit = _submitValidated(normalizedCode);
    _activeSubmit = submit;
    return submit;
  }

  Future<TelegramLinkOutcome> _submitValidated(String normalizedCode) async {
    try {
      final outcome = await _repository.linkTelegram(normalizedCode);
      final linked = outcome.type == TelegramLinkOutcomeType.linked ||
          outcome.type == TelegramLinkOutcomeType.alreadyLinked;
      state = state.copyWith(
        isSubmitting: false,
        isLinked: linked,
        lastOutcome: outcome,
        lastSubmittedCode: normalizedCode,
      );
      return outcome;
    } catch (_) {
      const fallback = TelegramLinkOutcome(type: TelegramLinkOutcomeType.unknown);
      state = state.copyWith(
        isSubmitting: false,
        lastOutcome: fallback,
        lastSubmittedCode: normalizedCode,
      );
      return fallback;
    } finally {
      _activeSubmit = null;
    }
  }

  /// Validates that the code is exactly 6 digits.
  TelegramLinkOutcome? _validate(String code) {
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      return const TelegramLinkOutcome(type: TelegramLinkOutcomeType.invalidId);
    }
    return null;
  }
}
