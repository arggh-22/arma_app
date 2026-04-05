import 'dart:convert';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';

/// Builds a complete Xray-core JSON configuration from a [ServerConfig].
///
/// Per D-02: ALL config logic lives in Dart. The native Kotlin side is a dumb
/// executor — it receives the complete JSON string and passes it to
/// `StartLoop(json, tunFd)`.
///
/// Handles 4 protocols (VLESS, VMess, Trojan, Shadowsocks) × 4 transports
/// (TCP, WS, gRPC, H2) × 3 TLS modes (none, tls, reality).
class XrayConfigBuilder {
  XrayConfigBuilder._();

  /// Builds a complete Xray JSON config string from [server].
  ///
  /// The returned string can be passed directly to the native AAR's
  /// `StartLoop(json, tunFd)`.
  static String build(ServerConfig server) {
    final config = <String, dynamic>{
      'log': _buildLog(),
      'stats': <String, dynamic>{},
      'policy': _buildPolicy(),
      'dns': _buildDns(),
      'inbounds': [_buildSocksInbound()],
      'outbounds': [
        _buildProxyOutbound(server),
        _buildDirectOutbound(),
        _buildBlockOutbound(),
      ],
      'routing': _buildRouting(serverAddress: server.address),
    };
    return jsonEncode(config);
  }

  static Map<String, dynamic> _buildLog() {
    return {'loglevel': 'warning'};
  }

  /// Enables traffic stats collection — CRITICAL for QueryStats() to work.
  static Map<String, dynamic> _buildPolicy() {
    return {
      'levels': {
        '0': {
          'statsUserUplink': true,
          'statsUserDownlink': true,
        },
      },
      'system': {
        'statsOutboundUplink': true,
        'statsOutboundDownlink': true,
      },
    };
  }

  /// Split DNS per D-11: remote DNS for proxied domains, localhost for local.
  static Map<String, dynamic> _buildDns() {
    return {
      'servers': [
        {
          'address': '1.1.1.1',
          'domains': <String>[],
          'port': 53,
        },
        'localhost',
      ],
    };
  }

  /// SOCKS5 inbound on 127.0.0.1:10808 for TUN traffic.
  static Map<String, dynamic> _buildSocksInbound() {
    return {
      'tag': 'socks-in',
      'protocol': 'socks',
      'listen': '127.0.0.1',
      'port': 10808,
      'settings': {
        'auth': 'noauth',
        'udp': true,
        'userLevel': 0,
      },
      'sniffing': {
        'enabled': true,
        'destOverride': ['http', 'tls', 'quic'],
        'metadataOnly': false,
        'routeOnly': false,
      },
    };
  }

  /// Builds the proxy outbound with protocol-specific settings.
  static Map<String, dynamic> _buildProxyOutbound(ServerConfig server) {
    // Map ProtocolType.shadowsocks scheme 'ss' to Xray protocol 'shadowsocks'
    final protocol = server.protocol == ProtocolType.shadowsocks
        ? 'shadowsocks'
        : server.protocol.scheme;

    return {
      'tag': 'proxy',
      'protocol': protocol,
      'settings': _buildProtocolSettings(server),
      'streamSettings': _buildStreamSettings(server),
    };
  }

  /// Protocol-specific outbound settings.
  ///
  /// VLESS/VMess use `vnext[]`, Trojan/Shadowsocks use `servers[]`.
  static Map<String, dynamic> _buildProtocolSettings(ServerConfig server) {
    return switch (server.protocol) {
      ProtocolType.vless => {
        'vnext': [
          {
            'address': server.address,
            'port': server.port,
            'users': [
              {
                'id': server.uuid ?? '',
                'encryption': 'none',
                'flow': _resolveFlow(server),
              },
            ],
          },
        ],
      },
      ProtocolType.vmess => {
        'vnext': [
          {
            'address': server.address,
            'port': server.port,
            'users': [
              {
                'id': server.uuid ?? '',
                'alterId': server.alterId,
                'security':
                    server.encryption == 'none' ? 'auto' : server.encryption,
              },
            ],
          },
        ],
      },
      ProtocolType.trojan => {
        'servers': [
          {
            'address': server.address,
            'port': server.port,
            'password': server.password ?? '',
          },
        ],
      },
      ProtocolType.shadowsocks => {
        'servers': [
          {
            'address': server.address,
            'port': server.port,
            'method': server.method ?? '',
            'password': server.password ?? '',
          },
        ],
      },
      ProtocolType.hysteria2 => {
        'servers': [
          {
            'address': server.address,
            'port': server.port,
            'password': server.password ?? '',
          },
        ],
      },
    };
  }

  /// Resolves the VLESS flow field.
  ///
  /// Flow MUST only be set for VLESS + TCP + (TLS or Reality).
  /// Setting flow on WS/gRPC/H2 causes connection failure (Pitfall from research).
  static String _resolveFlow(ServerConfig server) {
    if (server.protocol != ProtocolType.vless) return '';
    if (server.network != 'tcp') return '';
    if (server.security != 'tls' && server.security != 'reality') return '';
    return server.flow ?? '';
  }

  /// Builds stream settings: transport + TLS/Reality configuration.
  static Map<String, dynamic> _buildStreamSettings(ServerConfig server) {
    // H2 always forces TLS
    final effectiveSecurity =
        server.network == 'h2' ? 'tls' : server.security;

    final settings = <String, dynamic>{
      'network': server.network,
      'security': effectiveSecurity,
    };

    // TLS settings
    if (effectiveSecurity == 'tls') {
      settings['tlsSettings'] = {
        'serverName': server.sni ?? server.address,
        'allowInsecure': false,
        'alpn': server.alpn?.split(',') ?? <String>[],
        'fingerprint': server.fingerprint ?? 'chrome',
      };
    }

    // Reality settings (NOT tlsSettings)
    if (effectiveSecurity == 'reality') {
      settings['realitySettings'] = {
        'serverName': server.sni ?? server.address,
        'fingerprint': server.fingerprint ?? 'chrome',
        'publicKey': server.publicKey ?? '',
        'shortId': server.shortId ?? '',
        'spiderX': server.spiderX ?? '',
      };
    }

    // Transport-specific settings
    switch (server.network) {
      case 'tcp':
        settings['tcpSettings'] = {
          'header': {'type': 'none'},
        };
      case 'ws':
        settings['wsSettings'] = {
          'path': server.path ?? '/',
          'headers': {
            'Host': server.host ?? server.address,
          },
        };
      case 'grpc':
        settings['grpcSettings'] = {
          'serviceName': server.serviceName ?? '',
          'authority': server.authority ?? '',
          'multiMode': false,
        };
      case 'h2':
        settings['httpSettings'] = {
          'host': [server.host ?? server.address],
          'path': server.path ?? '/',
        };
    }

    return settings;
  }

  /// Direct outbound for LAN/bypass traffic.
  static Map<String, dynamic> _buildDirectOutbound() {
    return {
      'tag': 'direct',
      'protocol': 'freedom',
      'settings': <String, dynamic>{},
    };
  }

  /// Block outbound for blocked traffic.
  static Map<String, dynamic> _buildBlockOutbound() {
    return {
      'tag': 'block',
      'protocol': 'blackhole',
      'settings': {
        'response': {'type': 'http'},
      },
    };
  }

  /// Routing rules with LAN bypass per D-12 and proxy server direct rule.
  ///
  /// The proxy server's own address MUST route direct to prevent circular
  /// dependency: TUN captures all traffic → Xray routes to proxy → proxy needs
  /// to connect to server → needs DNS → goes through TUN → deadlock.
  static Map<String, dynamic> _buildRouting({required String serverAddress}) {
    // Rule to bypass the proxy server itself — MUST be first
    final serverBypassRule = _isIpAddress(serverAddress)
        ? {
            'type': 'field',
            'outboundTag': 'direct',
            'ip': [serverAddress],
          }
        : {
            'type': 'field',
            'outboundTag': 'direct',
            'domain': ['full:$serverAddress'],
          };

    return {
      'domainStrategy': 'IPIfNonMatch',
      'rules': [
        serverBypassRule,
        {
          'type': 'field',
          'outboundTag': 'direct',
          'ip': ['geoip:private'],
        },
        {
          'type': 'field',
          'outboundTag': 'direct',
          'domain': ['geosite:private'],
        },
        {
          'type': 'field',
          'outboundTag': 'proxy',
          'port': '0-65535',
        },
      ],
    };
  }

  /// Check if an address is an IP (v4) rather than a hostname.
  static bool _isIpAddress(String address) {
    return RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(address);
  }
}
