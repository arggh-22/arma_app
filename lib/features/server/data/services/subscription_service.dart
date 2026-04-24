import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_parser.dart';
import 'package:arma_proxy_vpn_client/features/server/data/parsers/subscription_userinfo_parser.dart';

/// Result of fetching and parsing a subscription URL.
class SubscriptionFetchResult {
  /// Parsed server configurations.
  final List<ServerConfig> servers;

  /// Parsed subscription-userinfo header data (bandwidth, expiry).
  final SubscriptionUserinfo? userinfo;

  /// Resolved profile title from headers/body metadata (if provided).
  final String? profileTitle;

  /// Optional update interval in hours from subscription metadata.
  final int? profileUpdateIntervalHours;

  const SubscriptionFetchResult({
    required this.servers,
    this.userinfo,
    this.profileTitle,
    this.profileUpdateIntervalHours,
  });
}

/// Fetches and parses subscription URLs (D-01, D-02, D-03, D-05).
///
/// - Sends a custom User-Agent header per CONF-08 / D-05
/// - Auto-detects body format via [SubscriptionParser.parseBody]
/// - Extracts bandwidth/expiry from `subscription-userinfo` header (D-03)
/// - Enforces 15s timeout and 5MB body size limit (T-03-15)
class SubscriptionService {
  /// Default User-Agent mimics a standard mobile browser to avoid
  /// provider fingerprinting (T-03-14).
  static const _defaultUserAgent =
      'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  /// HTTP request timeout (T-03-15).
  static const _timeout = Duration(seconds: 15);

  /// Maximum response body size in bytes — 5MB (T-03-15).
  static const _maxBodySize = 5 * 1024 * 1024;

  /// Fetch a subscription URL, parse the body, and return servers + userinfo.
  ///
  /// Uses the subscription's custom User-Agent if set, otherwise falls back
  /// to [_defaultUserAgent] (D-05 / CONF-08).
  ///
  /// Throws on HTTP errors, timeouts, or oversized responses.
  Future<SubscriptionFetchResult> fetch(Subscription subscription) async {
    final headers = {
      'User-Agent': subscription.userAgent.isEmpty
          ? _defaultUserAgent
          : subscription.userAgent,
    };

    final response = await http
        .get(Uri.parse(subscription.url), headers: headers)
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Subscription fetch failed: HTTP ${response.statusCode}',
      );
    }

    // T-03-15: Body size check to prevent resource exhaustion
    if (response.bodyBytes.length > _maxBodySize) {
      throw Exception(
        'Subscription response too large '
        '(>${_maxBodySize ~/ 1024 ~/ 1024}MB)',
      );
    }

    // D-03: Parse subscription-userinfo header
    final userinfo = parseSubscriptionUserinfo(
      response.headers['subscription-userinfo'],
    );

    final profileTitle = _extractProfileTitle(response.headers, response.body);
    final profileUpdateIntervalHours = _extractUpdateInterval(
      response.headers,
      response.body,
    );
    final effectiveGroupName = profileTitle ?? subscription.name;

    // D-01, D-02: Parse body — auto-detects format
    final servers = SubscriptionParser.parseBody(response.body);

    // Tag servers with subscription ID and group name
    final taggedServers = servers
        .map((s) => s.copyWith(
              subscriptionId: subscription.id,
              groupName: effectiveGroupName,
            ))
        .toList();

    return SubscriptionFetchResult(
      servers: taggedServers,
      userinfo: userinfo,
      profileTitle: profileTitle,
      profileUpdateIntervalHours: profileUpdateIntervalHours,
    );
  }

  String? _extractProfileTitle(Map<String, String> headers, String body) {
    final headerTitle = headers['profile-title'];
    final parsedHeaderTitle = _parseMaybeBase64Value(headerTitle);
    if (parsedHeaderTitle != null && parsedHeaderTitle.isNotEmpty) {
      return parsedHeaderTitle;
    }

    final fileName = _extractFilenameFromContentDisposition(
      headers['content-disposition'],
    );
    if (fileName != null && fileName.isNotEmpty) {
      return fileName;
    }

    final bodyDirective = _extractBodyDirective(body, 'profile-title');
    final parsedBodyTitle = _parseMaybeBase64Value(bodyDirective);
    if (parsedBodyTitle != null && parsedBodyTitle.isNotEmpty) {
      return parsedBodyTitle;
    }

    return null;
  }

  int? _extractUpdateInterval(Map<String, String> headers, String body) {
    final headerValue = headers['profile-update-interval']?.trim();
    if (headerValue != null) {
      final parsed = int.tryParse(headerValue);
      if (parsed != null) return parsed;
    }

    final bodyValue = _extractBodyDirective(body, 'profile-update-interval');
    if (bodyValue != null) {
      return int.tryParse(bodyValue.trim());
    }
    return null;
  }

  String? _extractFilenameFromContentDisposition(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(contentDisposition);
    return match?.group(1)?.trim();
  }

  String? _extractBodyDirective(String body, String key) {
    final lines = body.split(RegExp(r'\r?\n'));
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (!line.startsWith('#')) continue;
      final withoutHash = line.substring(1).trim();
      if (!withoutHash.toLowerCase().startsWith('${key.toLowerCase()}:')) {
        continue;
      }
      return withoutHash.substring(key.length + 1).trim();
    }
    return null;
  }

  String? _parseMaybeBase64Value(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.toLowerCase().startsWith('base64:')) {
      final payload = trimmed.substring('base64:'.length).trim();
      if (payload.isEmpty) return null;
      try {
        final decoded = utf8.decode(base64Decode(payload), allowMalformed: false);
        return decoded.trim();
      } catch (_) {
        return null;
      }
    }
    return trimmed;
  }
}
