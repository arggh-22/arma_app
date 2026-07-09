import 'package:arma_proxy_vpn_client/core/constants/app_constants.dart';

/// Shared URI parsing utilities used by all protocol parsers.
///
/// Extracts common patterns: input validation, name truncation,
/// parameter extraction, and safe URI decoding.
class ParserUtils {
  ParserUtils._();

  /// Maximum allowed input length to prevent DoS (T-01-03-03).
  static const maxInputLength = 10000;

  /// Returns `null` if [value] is null or empty; otherwise returns [value].
  static String? nonEmpty(String? value) =>
      (value != null && value.isNotEmpty) ? value : null;

  /// Returns [value] if non-null and non-empty; otherwise returns [fallback].
  static String nonEmptyOr(String? value, String fallback) =>
      (value != null && value.isNotEmpty) ? value : fallback;

  /// Safely decodes a URI-encoded parameter.
  ///
  /// Returns `null` if [value] is null or empty. Falls back to the
  /// raw value if decoding fails.
  static String? decodeParam(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  /// Returns `true` if [input] exceeds [maxInputLength].
  static bool exceedsMaxLength(String input) => input.length > maxInputLength;

  /// Extracts and truncates a server name from [fragment].
  ///
  /// If the fragment is empty, falls back to `address:port`.
  /// Name is capped at [AppConstants.maxServerNameLength] characters.
  static String extractName(String fragment, String address, int port) {
    var name = fragment.isNotEmpty
        ? Uri.decodeComponent(fragment)
        : '$address:$port';
    if (name.length > AppConstants.maxServerNameLength) {
      name = name.substring(0, AppConstants.maxServerNameLength);
    }
    return name;
  }

  /// Validates that an address is non-empty and port is in valid range.
  static bool isValidHostPort(String address, int port) =>
      address.isNotEmpty && port > 0 && port <= 65535;
}
