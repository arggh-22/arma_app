import 'package:arma_proxy_vpn_client/features/api/domain/entities/telegram_link_outcome.dart';

abstract class TelegramLinkRepository {
  Future<TelegramLinkOutcome> linkTelegram(String telegramId);
}
