import 'dart:convert';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';
import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/settings/domain/entities/vpn_settings.dart';

/// Builds a complete Xray-core JSON configuration from a [ServerConfig].
///
/// Per D-02: ALL config logic lives in Dart. The native Kotlin side is a dumb
/// executor — it receives the complete JSON string and passes it to
/// `StartLoop(json, tunFd)`.
///
/// Handles 4 protocols (VLESS, VMess, Trojan, Shadowsocks) × 5 transports
/// (TCP, WS, gRPC, H2, XHTTP) × 3 TLS modes (none, tls, reality).
class XrayConfigBuilder {
  XrayConfigBuilder._();

  /// Builds a complete Xray JSON config string from [server].
  ///
  /// When [settings] is provided, the config respects user-configurable DNS,
  /// routing rules, mux, sniffing, fragment, and region presets. When omitted,
  /// sensible defaults are used (backward compatible).
  ///
  /// The returned string can be passed directly to the native AAR's
  /// `StartLoop(json, tunFd)`.
  static String build(ServerConfig server, {VpnSettings? settings}) {
    final s = settings ?? const VpnSettings();
    final config = <String, dynamic>{
      'log': _buildLog(),
      'stats': <String, dynamic>{},
      'policy': _buildPolicy(),
      'dns': _buildDns(remoteDns: s.remoteDns, directDns: s.directDns),
      'inbounds': [_buildTunInbound(sniffingEnabled: s.sniffingEnabled)],
      'outbounds': [
        _buildProxyOutbound(
          server,
          muxEnabled: s.muxEnabled,
          muxConcurrency: s.muxConcurrency,
          fragmentEnabled: s.fragmentEnabled,
          fragmentMin: s.fragmentMin,
          fragmentMax: s.fragmentMax,
          sleepMin: s.sleepMin,
          sleepMax: s.sleepMax,
        ),
        _buildDirectOutbound(),
        _buildBlockOutbound(),
      ],
      'routing': _buildRouting(
        serverAddress: server.address,
        bypassLan: s.bypassLan,
        enabledRegions: s.enabledRegions,
        customRules: s.customRules,
      ),
    };
    return jsonEncode(config);
  }

  /// Builds a minimal Xray config for latency testing via MeasureDelay.
  ///
  /// Unlike [build], this config:
  /// - Has NO inbounds (MeasureDelay creates its own internal connection)
  /// - Has NO routing rules referencing geoip/geosite (the static Go call
  ///   doesn't run initCoreEnv, so geo data files are unavailable)
  /// - Uses only the proxy outbound (all traffic goes through the proxy)
  static String buildForLatencyTest(ServerConfig server) {
    final config = <String, dynamic>{
      'log': {'loglevel': 'warning'},
      'outbounds': [
        _buildProxyOutbound(server),
        _buildDirectOutbound(),
      ],
    };
    return jsonEncode(config);
  }

  static Map<String, dynamic> _buildLog() {
    return {'loglevel': 'debug'};
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
  ///
  /// The [remoteDns] value is already in the correct format for the protocol:
  /// - DoH: `https://1.1.1.1/dns-query`
  /// - DoT: `tls://1.1.1.1`
  /// - Plain: `1.1.1.1`
  static Map<String, dynamic> _buildDns({
    String remoteDns = 'https://1.1.1.1/dns-query',
    String directDns = 'localhost',
  }) {
    return {
      'servers': [
        {
          'address': remoteDns,
          'domains': <String>[],
          'port': 53,
        },
        directDns,
      ],
    };
  }

  /// TUN inbound — Xray-core reads directly from Android's TUN fd.
  ///
  /// AndroidLibXrayLite's `startLoop(config, tunFd)` stores the TUN fd as
  /// `os.Setenv("xray.tun.fd", fd)`. Xray-core's built-in TUN handler
  /// (proxy/tun/tun_android.go) reads this fd and creates a gVisor TCP/IP
  /// stack that processes raw IP packets directly.
  ///
  /// No separate tun2socks binary needed — Xray-core handles everything.
  static Map<String, dynamic> _buildTunInbound({bool sniffingEnabled = true}) {
    return {
      'tag': 'tun-in',
      'protocol': 'tun',
      'settings': {
        'name': 'tun0',
        'mtu': 9000,
        'userLevel': 0,
      },
      'sniffing': {
        'enabled': sniffingEnabled,
        'destOverride': ['http', 'tls', 'quic'],
        'metadataOnly': false,
        'routeOnly': false,
      },
    };
  }

  /// SOCKS5 inbound on 127.0.0.1:10808 — kept for future per-app proxy mode.
  @Deprecated('Use _buildTunInbound() for VPN mode')
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
  ///
  /// When [muxEnabled] is true, adds mux configuration (except for Hysteria2
  /// which has its own QUIC multiplexing). Fragment settings are forwarded
  /// to [_buildStreamSettings] for sockopt configuration.
  static Map<String, dynamic> _buildProxyOutbound(
    ServerConfig server, {
    bool muxEnabled = false,
    int muxConcurrency = 4,
    bool fragmentEnabled = false,
    int fragmentMin = 10,
    int fragmentMax = 100,
    int sleepMin = 0,
    int sleepMax = 0,
  }) {
    // Map ProtocolType.shadowsocks scheme 'ss' to Xray protocol 'shadowsocks'
    final protocol = server.protocol == ProtocolType.shadowsocks
        ? 'shadowsocks'
        : server.protocol.scheme;

    final outbound = <String, dynamic>{
      'tag': 'proxy',
      'protocol': protocol,
      'settings': _buildProtocolSettings(server),
      'streamSettings': _buildStreamSettings(
        server,
        fragmentEnabled: fragmentEnabled,
        fragmentMin: fragmentMin,
        fragmentMax: fragmentMax,
        sleepMin: sleepMin,
        sleepMax: sleepMax,
      ),
    };

    // Mux is NOT applied to Hysteria2 — QUIC has its own multiplexing
    if (muxEnabled && server.protocol != ProtocolType.hysteria2) {
      outbound['mux'] = {
        'enabled': true,
        'concurrency': muxConcurrency,
      };
    }

    return outbound;
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
            if (server.upMbps != null) 'up_mbps': server.upMbps,
            if (server.downMbps != null) 'down_mbps': server.downMbps,
          },
        ],
      },
    };
  }

  /// Resolves the VLESS flow field.
  ///
  /// Flow MUST only be set for VLESS + TCP + (TLS or Reality).
  /// Setting flow on WS/gRPC/H2/XHTTP causes connection failure.
  static String _resolveFlow(ServerConfig server) {
    if (server.protocol != ProtocolType.vless) return '';
    if (server.network != 'tcp') return '';
    if (server.security != 'tls' && server.security != 'reality') return '';
    return server.flow ?? '';
  }

  /// Builds stream settings: transport + TLS/Reality configuration.
  ///
  /// For Hysteria2, returns a minimal config with `network: hysteria2`.
  /// For other protocols, includes transport-specific settings and optional
  /// TLS ClientHello fragment via sockopt when [fragmentEnabled] is true.
  static Map<String, dynamic> _buildStreamSettings(
    ServerConfig server, {
    bool fragmentEnabled = false,
    int fragmentMin = 10,
    int fragmentMax = 100,
    int sleepMin = 0,
    int sleepMax = 0,
  }) {
    // Hysteria2 uses its own QUIC-based transport — no standard stream config
    if (server.protocol == ProtocolType.hysteria2) {
      return <String, dynamic>{
        'network': 'hysteria2',
        'security': 'tls',
        'tlsSettings': {
          'serverName': server.sni ?? server.address,
          'allowInsecure': server.insecure,
          'fingerprint': server.fingerprint ?? 'chrome',
        },
      };
    }

    // H2 always forces TLS
    final effectiveSecurity =
        server.network == 'h2' ? 'tls' : server.security;

    // Normalize xhttp → splithttp: this AAR's Xray-core registers the transport
    // as "splithttp" (pre-rename). Both names refer to the same protocol.
    final effectiveNetwork =
        server.network == 'xhttp' ? 'splithttp' : server.network;

    final settings = <String, dynamic>{
      'network': effectiveNetwork,
      'security': effectiveSecurity,
    };

    // TLS settings
    if (effectiveSecurity == 'tls') {
      // SplitHTTP: use standard Go TLS (no fingerprint) so ALPN is respected.
      // utls Chrome hard-wires h2 regardless of ALPN config; with standard
      // Go TLS the ALPN we send is honoured by the TLS layer.
      // User-set fingerprints are always respected.
      final defaultFingerprint =
          effectiveNetwork == 'splithttp' ? '' : 'chrome';
      final tlsSettings = <String, dynamic>{
        'serverName': server.sni ?? server.address,
        'allowInsecure': false,
        'fingerprint': server.fingerprint ?? defaultFingerprint,
      };
      // User-configured ALPN takes precedence.
      // SplitHTTP: CDN gateways (e.g. Cloudflare) often force h2 at TLS level
      // regardless of the client ALPN offer. When Go uses h1.1 transport but
      // TLS negotiated h2 the server sends h2 SETTINGS that h1.1 cannot parse.
      // Omitting the ALPN override lets Xray default to h2 (empty ALPN →
      // decideHTTPVersion → "2"), so both TLS and transport speak h2 and the
      // session is consistent. To force h1.1 (only for servers that reject h2
      // POST), set alpn=http/1.1 explicitly on the server entry.
      final alpnList =
          server.alpn?.split(',').where((s) => s.isNotEmpty).toList();
      if (alpnList != null && alpnList.isNotEmpty) {
        tlsSettings['alpn'] = alpnList;
      }
      // No default ALPN override for SplitHTTP — let Xray use h2 (default).
      settings['tlsSettings'] = tlsSettings;
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
    switch (effectiveNetwork) {
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
      case 'xhttp':
      case 'splithttp':
        final xhttpSettings = <String, dynamic>{
          'path': server.path ?? '/',
          'host': server.host ?? server.address,
        };
        // Respect user-configured mode.
        // Default: stream-up (single long-lived streaming POST per connection).
        // packet-up (Xray default) sends many short POST requests per data chunk;
        // Cloudflare CDN returns 400 Bad Request on those h2 short POSTs because
        // the CDN or origin (older Xray) cannot handle the packet-up seq-numbered
        // URL format over h2. stream-up uses one continuous POST stream per
        // connection, which is simpler and accepted by older Xray servers.
        final mode = (server.xhttpMode.isNotEmpty && server.xhttpMode != 'auto')
            ? server.xhttpMode
            : 'stream-up';
        xhttpSettings['mode'] = mode;
        settings['splithttpSettings'] = xhttpSettings;
    }

    // TLS ClientHello fragmentation via sockopt (anti-censorship D-10)
    if (fragmentEnabled) {
      settings['sockopt'] = {
        'fragment': {
          'packets': 'tlshello',
          'length': '$fragmentMin-$fragmentMax',
          'interval': '$sleepMin-$sleepMax',
        },
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

  /// Routing rules with LAN bypass, region presets, and custom domain rules.
  ///
  /// The proxy server's own address MUST route direct to prevent circular
  /// dependency: TUN captures all traffic → Xray routes to proxy → proxy needs
  /// to connect to server → needs DNS → goes through TUN → deadlock.
  ///
  /// Region presets (D-01, D-02, ROUTE-05) add geo-based direct rules for
  /// domestic traffic. Custom domain rules (D-03, ROUTE-03) let users specify
  /// proxy/direct/block per domain.
  static Map<String, dynamic> _buildRouting({
    required String serverAddress,
    bool bypassLan = true,
    Set<String> enabledRegions = const {},
    List<DomainRule> customRules = const [],
  }) {
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

    final rules = <Map<String, dynamic>>[
      serverBypassRule,
    ];

    // LAN bypass (conditional per user setting)
    if (bypassLan) {
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'ip': ['geoip:private'],
      });
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'domain': ['geosite:private'],
      });
    }

    // Region presets (D-01, D-02, ROUTE-05)
    if (enabledRegions.contains('iran')) {
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'domain': ['geosite:category-ir'],
      });
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'ip': ['geoip:ir'],
      });
    }
    if (enabledRegions.contains('china')) {
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'domain': ['geosite:cn'],
      });
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'ip': ['geoip:cn'],
      });
    }
    if (enabledRegions.contains('russia')) {
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'domain': ['geosite:category-ru'],
      });
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'ip': ['geoip:ru'],
      });
    }

    // Custom domain rules (D-03, ROUTE-03)
    final proxyDomains = customRules
        .where((r) => r.action == 'proxy')
        .map((r) => 'domain:${r.domain}')
        .toList();
    final directDomains = customRules
        .where((r) => r.action == 'direct')
        .map((r) => 'domain:${r.domain}')
        .toList();
    final blockDomains = customRules
        .where((r) => r.action == 'block')
        .map((r) => 'domain:${r.domain}')
        .toList();

    if (directDomains.isNotEmpty) {
      rules.add({
        'type': 'field',
        'outboundTag': 'direct',
        'domain': directDomains,
      });
    }
    if (blockDomains.isNotEmpty) {
      rules.add({
        'type': 'field',
        'outboundTag': 'block',
        'domain': blockDomains,
      });
    }
    if (proxyDomains.isNotEmpty) {
      rules.add({
        'type': 'field',
        'outboundTag': 'proxy',
        'domain': proxyDomains,
      });
    }

    // Catch-all proxy (must be last)
    rules.add({
      'type': 'field',
      'outboundTag': 'proxy',
      'port': '0-65535',
    });

    return {'domainStrategy': 'IPIfNonMatch', 'rules': rules};
  }

  /// Check if an address is an IP (v4) rather than a hostname.
  static bool _isIpAddress(String address) {
    return RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(address);
  }
}
