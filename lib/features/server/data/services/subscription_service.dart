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

  const SubscriptionFetchResult({required this.servers, this.userinfo});
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

    // D-01, D-02: Parse body — auto-detects format
    final servers = SubscriptionParser.parseBody(response.body);

    // Tag servers with subscription ID and group name
    final taggedServers = servers
        .map((s) => s.copyWith(
              subscriptionId: subscription.id,
              groupName: subscription.name,
            ))
        .toList();

    return SubscriptionFetchResult(
      servers: taggedServers,
      userinfo: userinfo,
    );
  }
}
