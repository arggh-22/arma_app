/// Extracts country flag emojis from server names.
///
/// Unicode regional indicator symbols form flag emojis:
/// 🇦 = U+1F1E6 (regional A) through 🇿 = U+1F1FF (regional Z).
/// A pair like U+1F1F3 U+1F1F1 = 🇳🇱 (Netherlands).
class FlagEmojiExtractor {
  FlagEmojiExtractor._();

  /// Matches a pair of regional indicator symbols (country flags).
  static final _flagRegex = RegExp(
    '[\u{1F1E6}-\u{1F1FF}][\u{1F1E6}-\u{1F1FF}]',
    unicode: true,
  );

  /// Extracts the first country flag emoji from [text], or null if none found.
  static String? extract(String text) {
    final match = _flagRegex.firstMatch(text);
    return match?.group(0);
  }
}
