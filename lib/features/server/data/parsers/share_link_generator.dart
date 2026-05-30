import 'dart:convert';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Generates standard share link URIs from [ServerConfig].
///
/// Produces valid share links for all 5 supported protocols:
/// - VLESS: `vless://uuid@host:port?params#name`
/// - VMess: `vmess://base64(JSON)` (legacy format for max compatibility)
/// - Trojan: `trojan://password@host:port?params#name`
/// - Shadowsocks: `ss://base64(method:password)@host:port#name` (SIP002)
/// - Hysteria2: `hysteria2://password@host:port?params#name`
///
/// Generated links can be re-parsed by [ShareLinkParser.parse()].
class ShareLinkGenerator {
  ShareLinkGenerator._();

  /// Generates a share link URI string for the given [server] config.
  ///
  /// Uses a Dart 3 switch expression for exhaustive protocol dispatch.
  static String generate(ServerConfig server) => switch (server.protocol) {
        ProtocolType.vless => _generateVlessLink(server),
        ProtocolType.vmess => _generateVmessLink(server),
        ProtocolType.trojan => _generateTrojanLink(server),
        ProtocolType.shadowsocks => _generateSsLink(server),
        ProtocolType.hysteria2 => _generateHy2Link(server),
      };

  /// Generates a VLESS share link.
  ///
  /// Format: `vless://uuid@address:port?params#name`
  static String _generateVlessLink(ServerConfig server) {
    final params = <String, String>{};
    params['type'] = server.network;
    params['security'] = server.security;

    _addIfNotEmpty(params, 'sni', server.sni);
    _addIfNotEmpty(params, 'host', server.host);
    _addIfEncoded(params, 'path', server.path);
    _addIfNotEmpty(params, 'fp', server.fingerprint);
    _addIfNotEmpty(params, 'flow', server.flow);
    _addIfNotEmpty(params, 'pbk', server.publicKey);
    _addIfNotEmpty(params, 'sid', server.shortId);
    _addIfEncoded(params, 'spx', server.spiderX);
    _addIfNotEmpty(params, 'alpn', server.alpn);

    if (server.network == 'grpc') {
      _addIfNotEmpty(params, 'serviceName', server.serviceName);
    }
    if (server.network == 'xhttp' && server.xhttpMode != 'auto') {
      params['mode'] = server.xhttpMode;
    }

    final query = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final fragment = Uri.encodeComponent(server.name);

    return 'vless://${server.uuid}@${server.address}:${server.port}'
        '?$query#$fragment';
  }

  /// Generates a VMess share link in legacy base64-JSON format.
  ///
  /// Format: `vmess://base64(JSON)`
  /// Uses legacy format for maximum client compatibility (per Pitfall 8).
  static String _generateVmessLink(ServerConfig server) {
    final json = <String, String>{
      'v': '2',
      'ps': server.name,
      'add': server.address,
      'port': server.port.toString(),
      'id': server.uuid ?? '',
      'aid': server.alterId.toString(),
      'net': server.network,
      'type': 'none',
      'host': server.host ?? '',
      'path': server.path ?? '',
      'tls': server.security == 'tls' ? 'tls' : '',
      'sni': server.sni ?? '',
      'fp': server.fingerprint ?? '',
    };

    final jsonStr = jsonEncode(json);
    final base64Str = base64Encode(utf8.encode(jsonStr));
    return 'vmess://$base64Str';
  }

  /// Generates a Trojan share link.
  ///
  /// Format: `trojan://password@address:port?params#name`
  static String _generateTrojanLink(ServerConfig server) {
    final params = <String, String>{};
    params['type'] = server.network;
    params['security'] = server.security;

    _addIfNotEmpty(params, 'sni', server.sni);
    _addIfNotEmpty(params, 'host', server.host);
    _addIfEncoded(params, 'path', server.path);
    _addIfNotEmpty(params, 'fp', server.fingerprint);
    _addIfNotEmpty(params, 'alpn', server.alpn);

    if (server.network == 'grpc') {
      _addIfNotEmpty(params, 'serviceName', server.serviceName);
    }
    if (server.network == 'xhttp' && server.xhttpMode != 'auto') {
      params['mode'] = server.xhttpMode;
    }

    final query = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final fragment = Uri.encodeComponent(server.name);
    final password = Uri.encodeComponent(server.password ?? '');

    return 'trojan://$password@${server.address}:${server.port}'
        '?$query#$fragment';
  }

  /// Generates a Shadowsocks SIP002 share link.
  ///
  /// Format: `ss://base64(method:password)@address:port#name`
  static String _generateSsLink(ServerConfig server) {
    final method = server.method ?? 'aes-256-gcm';
    final password = server.password ?? '';
    final userInfo = base64Encode(utf8.encode('$method:$password'));
    final fragment = Uri.encodeComponent(server.name);

    return 'ss://$userInfo@${server.address}:${server.port}#$fragment';
  }

  /// Generates a Hysteria2 share link.
  ///
  /// Format: `hysteria2://password@address:port?params#name`
  static String _generateHy2Link(ServerConfig server) {
    final params = <String, String>{};

    _addIfNotEmpty(params, 'sni', server.sni);
    _addIfNotEmpty(params, 'obfs', server.obfs);
    _addIfNotEmpty(params, 'obfs-password', server.obfsPassword);

    final query = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final fragment = Uri.encodeComponent(server.name);
    final password = Uri.encodeComponent(server.password ?? '');

    final queryPart = query.isNotEmpty ? '?$query' : '';
    return 'hysteria2://$password@${server.address}:${server.port}'
        '$queryPart#$fragment';
  }

  /// Adds a key-value pair to [params] if [value] is non-null and non-empty.
  static void _addIfNotEmpty(
    Map<String, String> params,
    String key,
    String? value,
  ) {
    if (value != null && value.isNotEmpty) {
      params[key] = value;
    }
  }

  /// Adds a URI-encoded key-value pair to [params] if [value] is non-null
  /// and non-empty.
  static void _addIfEncoded(
    Map<String, String> params,
    String key,
    String? value,
  ) {
    if (value != null && value.isNotEmpty) {
      params[key] = Uri.encodeComponent(value);
    }
  }
}
