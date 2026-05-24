enum TelegramLinkOutcomeType {
  linked,
  alreadyLinked,
  invalidId,
  unauthorized,
  network,
  server,
  unknown,
}

class TelegramLinkOutcome {
  const TelegramLinkOutcome({
    required this.type,
    this.message,
  });

  final TelegramLinkOutcomeType type;
  final String? message;
}
