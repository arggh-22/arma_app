import 'dart:convert';

import 'package:arma_proxy_vpn_client/features/server/data/parsers/clash_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/share_link_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/sip008_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses subscription HTTP response bodies into [ServerConfig] lists.
///
/// Auto-detects the subscription format:
/// 1. **SIP008 JSON** — starts with `[` or `{`
/// 2. **Clash YAML** — contains `proxies:`
/// 3. **Base64-encoded share links** — base64 string containing share link URIs
/// 4. **Plain text share links** — one share link per line
///
/// Only parses known schemes (vless://, vmess://, trojan://, ss://,
/// hysteria2://) per T-03-04 threat mitigation.
class SubscriptionParser {
  SubscriptionParser._();

  /// Parses a subscription body string into a list of [ServerConfig].
  ///
  /// Returns an empty list if the body is empty or contains no valid
  /// server configurations.
  static List<ServerConfig> parseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];

    // 1. SIP008 JSON detection — starts with [ or {
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      final sip008Result = Sip008Parser.tryParse(trimmed);
      if (sip008Result != null && sip008Result.isNotEmpty) {
        return sip008Result;
      }
    }

    // 2. Clash YAML detection — contains proxies:
    if (trimmed.contains('proxies:')) {
      final clashResult = ClashParser.tryParse(trimmed);
      if (clashResult != null && clashResult.isNotEmpty) {
        return clashResult;
      }
    }

    // 3. Try base64 decode, fall back to plain text
    final text = _tryBase64Decode(trimmed) ?? trimmed;

    // 4. Split by lines and parse each as a share link
    return _parseShareLinks(text);
  }

  /// Attempts to decode a base64 string.
  ///
  /// Normalizes URL-safe characters and fixes missing padding.
  /// Returns the decoded UTF-8 string, or `null` if decoding fails.
  static String? _tryBase64Decode(String input) {
    try {
      // Normalize URL-safe base64 to standard base64
      var normalized = input.replaceAll('-', '+').replaceAll('_', '/');

      // Fix missing padding
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }

      final bytes = base64Decode(normalized);
      final decoded = utf8.decode(bytes, allowMalformed: false);

      // Verify the decoded content looks like share links
      // (contains :// which is present in all share link schemes)
      if (decoded.contains('://')) return decoded;

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Splits text by lines and parses each line as a share link.
  ///
  /// Only valid share links (parsed by [ShareLinkParser]) are included.
  /// Invalid lines are silently skipped per the mixed valid/invalid spec.
  static List<ServerConfig> _parseShareLinks(String text) {
    final lines = text.split(RegExp(r'\r?\n'));
    final results = <ServerConfig>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      final config = ShareLinkParser.parse(trimmedLine);
      if (config != null) {
        results.add(config);
      }
    }

    return results;
  }
}
