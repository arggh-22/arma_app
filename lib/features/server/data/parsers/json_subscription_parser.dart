import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses the ARMA JSON subscription format
/// (docs/arma_mobile_json_subscription_spec_en.md).
///
/// The body is a JSON array where each element is a complete, ready-to-run
/// Xray config object with:
/// - `remarks` — user-facing profile title.
/// - `meta.serverDescription` — subtitle / badge.
/// - `dns` / `inbounds` / `outbounds` / `routing` / `burstObservatory` — the
///   full Xray config for that profile (may include multi-server balancers).
///
/// Each entry becomes a [ServerConfig] whose display fields are extracted from
/// the primary `proxy` outbound (for the list UI, filtering, latency, dedup),
/// while the entire original object is preserved verbatim in
/// [ServerConfig.rawConfig] so the connection can hand it to the core intact.
class JsonSubscriptionParser {
  JsonSubscriptionParser._();

  static const _uuid = Uuid();

  /// Returns `true` if [body] looks like an ARMA JSON subscription: a JSON
  /// array whose first object carries `outbounds` (distinguishes it from the
  /// SIP008 Shadowsocks format, whose entries use `server`/`server_port`).
  static bool looksLikeJsonSubscription(String body) {
    final trimmed = body.trimLeft();
    if (!trimmed.startsWith('[')) return false;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List) return false;
      final first = decoded.firstWhere(
        (e) => e is Map<String, dynamic>,
        orElse: () => null,
      );
      return first is Map<String, dynamic> && first.containsKey('outbounds');
    } catch (_) {
      return false;
    }
  }

  /// Parses a JSON-subscription body into [ServerConfig]s.
  ///
  /// Returns `null` if the body is not a JSON-subscription array, or an empty
  /// list if it is but no entry yielded a usable proxy config.
  static List<ServerConfig>? tryParse(String body) {
    if (!looksLikeJsonSubscription(body)) return null;

    final decoded = jsonDecode(body) as List<dynamic>;
    final results = <ServerConfig>[];
    for (var i = 0; i < decoded.length; i++) {
      final entry = decoded[i];
      if (entry is! Map<String, dynamic>) continue;
      final config = _parseEntry(entry, index: i);
      if (config != null) results.add(config);
    }
    return results;
  }

  static ServerConfig? _parseEntry(Map<String, dynamic> entry, {required int index}) {
    final outbound = _primaryOutbound(entry);
    if (outbound == null) return null;

    final protocolName = _strAt(outbound, 'protocol') ?? '';
    final protocol = ProtocolType.fromScheme(protocolName.toLowerCase());
    if (protocol == null) return null;

    final endpoint = _endpoint(outbound, protocol);
    if (endpoint == null) return null;
    final address = endpoint.key;
    final port = endpoint.value;

    final stream = _asMap(outbound['streamSettings']);
    final network = _strAt(stream, 'network') ?? 'tcp';
    final security = _strAt(stream, 'security') ?? 'none';
    final user = _firstUser(outbound, protocol) ?? const <String, dynamic>{};
    final reality = _mapAt(stream, 'realitySettings');
    final tls = _mapAt(stream, 'tlsSettings');

    final isVlessVmess =
        protocol == ProtocolType.vless || protocol == ProtocolType.vmess;
    final isTrojanSs = protocol == ProtocolType.trojan ||
        protocol == ProtocolType.shadowsocks;

    final remarks = _strAt(entry, 'remarks')?.trim();
    final name = (remarks != null && remarks.isNotEmpty)
        ? remarks
        : '$address:$port';
    final description = _strAt(_asMap(entry['meta']), 'serverDescription')?.trim();

    return ServerConfig(
      id: _uuid.v4(),
      name: name,
      protocol: protocol,
      address: address,
      port: port,
      uuid: isVlessVmess ? _strAt(user, 'id') : null,
      password: isTrojanSs ? _strAt(user, 'password') : null,
      encryption: _strAt(user, 'encryption') ?? 'none',
      network: network,
      security: security,
      flow: _strAt(user, 'flow'),
      sni: _strAt(reality, 'serverName') ?? _strAt(tls, 'serverName'),
      host: _host(stream, network),
      path: _path(stream, network),
      xhttpMode: _strAt(_mapAt(stream, 'xhttpSettings'), 'mode') ?? 'auto',
      publicKey: _strAt(reality, 'publicKey'),
      shortId: _strAt(reality, 'shortId'),
      fingerprint: _strAt(reality, 'fingerprint') ?? _strAt(tls, 'fingerprint'),
      method: protocol == ProtocolType.shadowsocks
          ? _strAt(user, 'method')
          : null,
      serverDescription: (description != null && description.isNotEmpty)
          ? description
          : null,
      rawConfig: jsonEncode(entry),
      addedAt: DateTime.now(),
    );
  }

  /// The outbound that carries the user connection. Prefers the `proxy` tag
  /// (auto-balancing profiles list `proxy`, `proxy-2`, … all selected by a
  /// balancer), otherwise the first non-`direct`/`block` outbound.
  static Map<String, dynamic>? _primaryOutbound(Map<String, dynamic> entry) {
    final outbounds = entry['outbounds'];
    if (outbounds is! List) return null;
    Map<String, dynamic>? fallback;
    for (final o in outbounds) {
      if (o is! Map<String, dynamic>) continue;
      final tag = o['tag'] as String?;
      final proto = o['protocol'] as String?;
      if (proto == 'freedom' || proto == 'blackhole') continue;
      fallback ??= o;
      if (tag == 'proxy') return o;
    }
    return fallback;
  }

  /// Returns the endpoint as address → port, or `null` if absent.
  static MapEntry<String, int>? _endpoint(
    Map<String, dynamic> outbound,
    ProtocolType protocol,
  ) {
    final settings = _asMap(outbound['settings']);
    if (settings == null) return null;

    // VLESS / VMess use `vnext`; Trojan / Shadowsocks use `servers`.
    final list = settings['vnext'] ?? settings['servers'];
    if (list is! List || list.isEmpty) return null;
    final first = _asMap(list.first);
    if (first == null) return null;

    final address = first['address'] as String?;
    final port = _asInt(first['port']);
    if (address == null || address.isEmpty || port == null) return null;
    return MapEntry(address, port);
  }

  static Map<String, dynamic>? _firstUser(
    Map<String, dynamic> outbound,
    ProtocolType protocol,
  ) {
    final settings = _asMap(outbound['settings']);
    if (settings == null) return null;

    // VLESS/VMess: settings.vnext[0].users[0]
    final vnext = settings['vnext'];
    if (vnext is List && vnext.isNotEmpty) {
      final firstVnext = _asMap(vnext.first);
      final users = firstVnext == null ? null : firstVnext['users'];
      if (users is List && users.isNotEmpty) return _asMap(users.first);
    }
    // Trojan/Shadowsocks: settings.servers[0]
    final servers = settings['servers'];
    if (servers is List && servers.isNotEmpty) return _asMap(servers.first);
    return null;
  }

  static String? _host(Map<String, dynamic>? stream, String network) {
    if (stream == null) return null;
    if (network == 'ws') {
      final headers = _mapAt(_mapAt(stream, 'wsSettings'), 'headers');
      return _strAt(headers, 'Host');
    }
    if (network == 'xhttp') {
      return _strAt(_mapAt(stream, 'xhttpSettings'), 'host');
    }
    return null;
  }

  static String? _path(Map<String, dynamic>? stream, String network) {
    if (stream == null) return null;
    if (network == 'ws') return _strAt(_mapAt(stream, 'wsSettings'), 'path');
    if (network == 'xhttp') {
      return _strAt(_mapAt(stream, 'xhttpSettings'), 'path');
    }
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : null;

  /// Null-safe map lookup returning a nested map (avoids `?[]`, which the
  /// codegen front-end can't parse).
  static Map<String, dynamic>? _mapAt(Map<String, dynamic>? map, String key) =>
      map == null ? null : _asMap(map[key]);

  /// Null-safe map lookup returning a String value.
  static String? _strAt(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final value = map[key];
    return value is String ? value : null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
