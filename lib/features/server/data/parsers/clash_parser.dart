import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Parses Clash YAML proxy configuration into [ServerConfig] list.
///
/// Extracts the `proxies:` list from a Clash config and maps
/// supported proxy types to [ServerConfig]. Unsupported types
/// (e.g., snell, socks5) are silently skipped.
///
/// Wraps `loadYaml` in try-catch per T-03-05 to prevent crashes
/// on malformed YAML.
class ClashParser {
  ClashParser._();

  /// Mapping from Clash type names to [ProtocolType].
  static const _typeMap = <String, ProtocolType>{
    'vmess': ProtocolType.vmess,
    'vless': ProtocolType.vless,
    'trojan': ProtocolType.trojan,
    'ss': ProtocolType.shadowsocks,
    'hysteria2': ProtocolType.hysteria2,
    'hy2': ProtocolType.hysteria2,
  };

  /// Attempts to parse a Clash YAML configuration body.
  ///
  /// Returns a list of [ServerConfig] on success, or `null` if the
  /// YAML is invalid or doesn't contain a `proxies` key.
  static List<ServerConfig>? tryParse(String yamlContent) {
    try {
      final doc = loadYaml(yamlContent);
      if (doc is! YamlMap) return null;

      final proxies = doc['proxies'];
      if (proxies is! YamlList) return null;

      final results = <ServerConfig>[];
      for (final proxy in proxies) {
        if (proxy is! YamlMap) continue;
        final config = _parseProxy(proxy);
        if (config != null) results.add(config);
      }

      return results.isEmpty ? null : results;
    } catch (_) {
      return null;
    }
  }

  /// Parses a single Clash proxy entry.
  ///
  /// Returns `null` for unsupported types or entries with missing
  /// required fields.
  static ServerConfig? _parseProxy(YamlMap proxy) {
    final typeName = proxy['type']?.toString();
    if (typeName == null) return null;

    final protocol = _typeMap[typeName];
    if (protocol == null) return null; // Unsupported type — skip

    final server = proxy['server']?.toString();
    if (server == null || server.isEmpty) return null;

    final port = _parseInt(proxy['port']);
    if (port == null || port <= 0 || port > 65535) return null;

    final name = proxy['name']?.toString() ?? '$server:$port';

    // TLS / security
    final tls = proxy['tls'];
    final security = (tls == true) ? 'tls' : 'none';

    // SNI — Clash uses both 'sni' and 'servername'
    final sni =
        _nonEmpty(proxy['sni']?.toString()) ??
        _nonEmpty(proxy['servername']?.toString());

    // Network / transport
    final network = _nonEmpty(proxy['network']?.toString()) ?? 'tcp';

    // Transport options
    String? path;
    String? host;
    String? serviceName;

    // WebSocket options
    final wsOpts = proxy['ws-opts'];
    if (wsOpts is YamlMap) {
      path = _nonEmpty(wsOpts['path']?.toString());
      final headers = wsOpts['headers'];
      if (headers is YamlMap) {
        host = _nonEmpty(headers['Host']?.toString());
      }
    }

    // gRPC options
    final grpcOpts = proxy['grpc-opts'];
    if (grpcOpts is YamlMap) {
      serviceName = _nonEmpty(grpcOpts['grpc-service-name']?.toString());
    }

    // HTTP/2 options
    final h2Opts = proxy['h2-opts'];
    if (h2Opts is YamlMap) {
      path ??= _nonEmpty(h2Opts['path']?.toString());
      final h2Host = h2Opts['host'];
      if (h2Host is YamlList && h2Host.isNotEmpty) {
        host ??= h2Host.first?.toString();
      } else if (h2Host is String) {
        host ??= _nonEmpty(h2Host);
      }
    }

    // XHTTP options
    String xhttpMode = 'auto';
    final xhttpOpts = proxy['xhttp-opts'];
    if (xhttpOpts is YamlMap) {
      path ??= _nonEmpty(xhttpOpts['path']?.toString());
      host ??= _nonEmpty(xhttpOpts['host']?.toString());
      xhttpMode = _nonEmpty(xhttpOpts['mode']?.toString()) ?? 'auto';
    }

    // Protocol-specific fields
    final uuid = _nonEmpty(proxy['uuid']?.toString());
    final password = _nonEmpty(proxy['password']?.toString());
    final cipher = _nonEmpty(proxy['cipher']?.toString());
    final flow = _nonEmpty(proxy['flow']?.toString());
    final fingerprint = _nonEmpty(proxy['client-fingerprint']?.toString());
    final alpn = _nonEmpty(proxy['alpn']?.toString());

    // Hysteria2 fields
    final obfs = _nonEmpty(proxy['obfs']?.toString());
    final obfsPassword = _nonEmpty(proxy['obfs-password']?.toString());

    return ServerConfig(
      id: const Uuid().v4(),
      name: name,
      protocol: protocol,
      address: server,
      port: port,
      uuid: uuid,
      password: password,
      encryption: protocol == ProtocolType.vmess ? (cipher ?? 'auto') : 'none',
      method: protocol == ProtocolType.shadowsocks ? cipher : null,
      network: network,
      xhttpMode: xhttpMode,
      security: security,
      sni: sni,
      host: host,
      path: path,
      flow: flow,
      fingerprint: fingerprint,
      alpn: alpn,
      serviceName: serviceName,
      obfs: obfs,
      obfsPassword: obfsPassword,
      addedAt: DateTime.now(),
    );
  }

  static String? _nonEmpty(String? value) =>
      (value != null && value.isNotEmpty) ? value : null;

  static int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}
