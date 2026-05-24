import 'package:arma_proxy_vpn_client/features/api/data/datasources/api_client.dart';
import 'package:arma_proxy_vpn_client/features/api/data/models/telegram_link_response.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/auth_repository.dart';
import 'package:arma_proxy_vpn_client/features/api/domain/repositories/telegram_link_repository.dart';

class TelegramLinkRepositoryImpl implements TelegramLinkRepository {
  TelegramLinkRepositoryImpl({
    required ApiClient apiClient,
    required AuthRepository authRepository,
  }) : _apiClient = apiClient,
       _authRepository = authRepository;

  final ApiClient _apiClient;
  final AuthRepository _authRepository;

  @override
  Future<TelegramLinkOutcome> linkTelegram(String telegramId) async {
    try {
      final response = await _authRepository.executeWithAuthRetry(
        (token) => _apiClient.linkTelegram(
          token: token,
          telegramId: telegramId,
        ),
      );
      return _mapResponse(response);
    } on AuthRepositoryException catch (error) {
      if (error.type == AuthRepositoryFailureType.unauthorizedAfterRetry) {
        return TelegramLinkOutcome(
          type: TelegramLinkOutcomeType.unauthorized,
          message: error.message,
        );
      }
      return TelegramLinkOutcome(
        type: TelegramLinkOutcomeType.unknown,
        message: error.message,
      );
    } on ApiClientException catch (error) {
      return _mapApiException(error);
    }
  }

  TelegramLinkOutcome _mapResponse(TelegramLinkResponse response) {
    final status = response.status?.toLowerCase();
    final detail = response.detail.toLowerCase();
    if (status == 'already_linked' || detail.contains('already linked')) {
      return TelegramLinkOutcome(
        type: TelegramLinkOutcomeType.alreadyLinked,
        message: response.detail,
      );
    }
    if (status == null || status == 'linked' || status == 'success') {
      return TelegramLinkOutcome(
        type: TelegramLinkOutcomeType.linked,
        message: response.detail,
      );
    }
    if (status == 'invalid_id') {
      return TelegramLinkOutcome(
        type: TelegramLinkOutcomeType.invalidId,
        message: response.detail,
      );
    }
    return TelegramLinkOutcome(
      type: TelegramLinkOutcomeType.unknown,
      message: response.detail,
    );
  }

  TelegramLinkOutcome _mapApiException(ApiClientException error) {
    switch (error.type) {
      case ApiClientErrorType.timeout:
      case ApiClientErrorType.network:
        return TelegramLinkOutcome(
          type: TelegramLinkOutcomeType.network,
          message: error.message,
        );
      case ApiClientErrorType.unauthorized:
        return TelegramLinkOutcome(
          type: TelegramLinkOutcomeType.unauthorized,
          message: error.message,
        );
      case ApiClientErrorType.server:
        return TelegramLinkOutcome(
          type: TelegramLinkOutcomeType.server,
          message: error.message,
        );
      case ApiClientErrorType.client:
        if (error.statusCode == 400) {
          return TelegramLinkOutcome(
            type: TelegramLinkOutcomeType.invalidId,
            message: error.message,
          );
        }
        if (error.statusCode == 409) {
          return TelegramLinkOutcome(
            type: TelegramLinkOutcomeType.alreadyLinked,
            message: error.message,
          );
        }
        return TelegramLinkOutcome(
          type: TelegramLinkOutcomeType.unknown,
          message: error.message,
        );
      case ApiClientErrorType.malformedResponse:
      case ApiClientErrorType.unknown:
        return TelegramLinkOutcome(
          type: TelegramLinkOutcomeType.unknown,
          message: error.message,
        );
    }
  }
}
