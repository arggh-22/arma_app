/// Human-friendly formatting of a subscription/key expiry countdown.
///
/// Shared by the servers tab group header and the home dashboard default
/// server tiles so both render expiry identically.
class ExpiryInfo {
  const ExpiryInfo({
    required this.label,
    required this.isExpired,
    required this.isCritical,
    required this.isUrgent,
  });

  /// Short countdown label using the largest sensible unit — e.g. `2mo`,
  /// `3w`, `5d`, `8h`, `42m`, or `0d` once expired.
  final String label;

  /// True when the expiry moment has already passed.
  final bool isExpired;

  /// True when less than a day remains (or already expired) — callers should
  /// show a warning icon/color.
  final bool isCritical;

  /// True when 3 days or fewer remain (and not yet expired) — emphasize.
  final bool isUrgent;
}

/// Describes how much time is left until [expireDate].
///
/// Pass [now] in tests for a deterministic reference time.
ExpiryInfo describeExpiry(DateTime expireDate, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final remaining = expireDate.difference(reference);
  final isExpired = remaining.inSeconds <= 0;
  final isCritical = isExpired || remaining.inDays < 1;
  final isUrgent = !isExpired && remaining.inDays <= 3;

  return ExpiryInfo(
    label: isExpired ? '0d' : _formatRemaining(remaining),
    isExpired: isExpired,
    isCritical: isCritical,
    isUrgent: isUrgent,
  );
}

/// Formats a positive remaining [Duration] using the largest sensible unit:
/// months, weeks, days, hours, then minutes.
String _formatRemaining(Duration remaining) {
  final days = remaining.inDays;
  if (days >= 30) {
    return '${days ~/ 30}mo';
  }
  if (days >= 7) {
    return '${days ~/ 7}w';
  }
  if (days >= 1) {
    return '${days}d';
  }
  final hours = remaining.inHours;
  if (hours >= 1) {
    return '${hours}h';
  }
  final minutes = remaining.inMinutes;
  return '${minutes < 1 ? 1 : minutes}m';
}
