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

  /// `profile-update-always` header: if true, the app should force a fresh
  /// fetch every time it opens (spec §2).
  final bool profileUpdateAlways;

  /// `support-url` header: opened from a "Support" / "Contact" action.
  final String? supportUrl;

  /// `profile-web-page-url` header: personal cabinet / renew-subscription page.
  final String? profileWebPageUrl;

  /// `announce` header (Base64-decoded): admin notice to show as a banner.
  final String? announcement;

  const SubscriptionFetchResult({
    required this.servers,
    this.userinfo,
    this.profileTitle,
    this.profileUpdateIntervalHours,
    this.profileUpdateAlways = false,
    this.supportUrl,
    this.profileWebPageUrl,
    this.announcement,
  });
}

/// Fetches and parses subscription URLs (D-01, D-02, D-03, D-05).
///
/// - Sends a custom User-Agent header per CONF-08 / D-05
/// - Auto-detects body format via [SubscriptionParser.parseBody]
/// - Extracts bandwidth/expiry from `subscription-userinfo` header (D-03)
/// - Enforces 15s timeout and 5MB body size limit (T-03-15)
class SubscriptionService {
  /// Default User-Agent identifies this app as a VPN client.
  ///
  /// Subscription backends content-negotiate on User-Agent: a browser-like
  /// UA (e.g. `Mozilla/... Chrome/...`) makes the arma backend 302-redirect
  /// to an HTML landing page instead of serving the base64 subscription,
  /// so the parser sees HTML and finds zero servers. A recognized client UA
  /// (`arma`) is required to receive the actual server list.
  static const _defaultUserAgent = 'arma';

  /// HTTP request timeout (T-03-15).
  static const _timeout = Duration(seconds: 15);

  /// Maximum response body size in bytes — 5MB (T-03-15).
  static const _maxBodySize = 5 * 1024 * 1024;

  /// HTTP client. Injectable for testing; defaults to a shared client.
  final http.Client _client;

  SubscriptionService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch a subscription URL, parse the body, and return servers + userinfo.
  ///
  /// Uses the subscription's custom User-Agent if set, otherwise falls back
  /// to [_defaultUserAgent] (D-05 / CONF-08).
  ///
  /// Includes device identification headers for provider compatibility:
  /// - X-Hwid: Device hardware identifier
  /// - X-Device-Model: Device model (e.g., "Pixel 9")
  /// - X-Device-Os: Operating system (Android)
  /// - X-Ver-Os: OS version (e.g., "16")
  ///
  /// Throws on HTTP errors, timeouts, or oversized responses.
  Future<SubscriptionFetchResult> fetch(Subscription subscription) async {
    final headers = {
      'User-Agent': subscription.userAgent.isEmpty
          ? _defaultUserAgent
          : subscription.userAgent,
      'X-Hwid': '7adbd63a1e86a4f0',
      'X-Device-Model': 'Pixel 9',
      'X-Device-Os': 'Android',
      'X-Ver-Os': '16',
    };

    final fetched = await _fetchAndParse(subscription.url, headers);
    final response = fetched.response;

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

    // Body was parsed during the fetch/fallback (D-01, D-02, auto-detected).
    final servers = fetched.servers;

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
      profileUpdateAlways:
          (response.headers['profile-update-always']?.trim().toLowerCase()) ==
              'true',
      supportUrl: response.headers['support-url']?.trim(),
      profileWebPageUrl: response.headers['profile-web-page-url']?.trim(),
      announcement: _decodeAnnouncement(response.headers['announce']),
    );
  }

  /// Decodes the `announce` header. Per spec it is Base64-encoded (raw, no
  /// `base64:` prefix), but we tolerate a prefixed or already-plain value too.
  String? _decodeAnnouncement(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    final prefixed = _parseMaybeBase64Value(trimmed);
    if (prefixed != null && prefixed != trimmed) return prefixed;

    try {
      final decoded = utf8.decode(base64Decode(base64.normalize(trimmed)));
      if (decoded.trim().isNotEmpty) return decoded.trim();
    } catch (_) {
      // Not valid Base64 — fall through to the raw value.
    }
    return trimmed;
  }

  /// Fetches and parses the subscription, preferring the JSON format (spec §1).
  ///
  /// Requests `?format=json` first. Falls back to the untouched URL when that
  /// request either fails (non-200) OR returns a body that parses to zero
  /// servers — this covers providers that reject the unknown param (4xx) and
  /// those that silently ignore it and return a 200 landing/HTML page. Without
  /// the empty-body fallback a "200 + wrong body" would yield 0 servers and a
  /// refresh would wipe the subscription. The parser auto-detects whichever
  /// format comes back, so share-link/base64 subscriptions still work.
  Future<_FetchResult> _fetchAndParse(
    String url,
    Map<String, String> headers,
  ) async {
    final jsonUri = _withJsonFormat(url);
    final originalUri = Uri.parse(url);

    final jsonResponse =
        await _client.get(jsonUri, headers: headers).timeout(_timeout);
    final jsonServers = jsonResponse.statusCode == 200
        ? SubscriptionParser.parseBody(jsonResponse.body)
        : const <ServerConfig>[];
    if (jsonServers.isNotEmpty) {
      return _FetchResult(jsonResponse, jsonServers);
    }

    // Retry the untouched URL if the format=json attempt failed or yielded
    // nothing parseable — but never downgrade a usable response to a broken one.
    if (jsonUri != originalUri) {
      final plainResponse =
          await _client.get(originalUri, headers: headers).timeout(_timeout);
      final plainServers = plainResponse.statusCode == 200
          ? SubscriptionParser.parseBody(plainResponse.body)
          : const <ServerConfig>[];
      if (plainServers.isNotEmpty || jsonResponse.statusCode != 200) {
        return _FetchResult(plainResponse, plainServers);
      }
    }

    return _FetchResult(jsonResponse, jsonServers);
  }

  /// Adds `format=json` to the query, preserving the original raw query string
  /// verbatim (including any repeated keys) rather than rebuilding it.
  static Uri _withJsonFormat(String url) {
    final uri = Uri.parse(url);
    if (uri.queryParameters['format'] == 'json') return uri;
    final query = uri.query.isEmpty ? 'format=json' : '${uri.query}&format=json';
    return uri.replace(query: query);
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

/// A fetched subscription response together with its parsed servers, so the
/// JSON/plain fallback decision (based on parse success) doesn't re-parse.
class _FetchResult {
  const _FetchResult(this.response, this.servers);

  final http.Response response;
  final List<ServerConfig> servers;
}
