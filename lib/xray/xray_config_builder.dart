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
  static String build(
    ServerConfig server, {
    VpnSettings? settings,
    List<Map<String, dynamic>>? inboundsOverride,
  }) {
    final s = settings ?? const VpnSettings();

    // JSON-subscription profiles ship a complete, ready-to-run Xray config
    // (multi-server balancers, burstObservatory, xhttp, PQ encryption). Use it
    // verbatim, swapping only the local inbound for the app's inbound.
    final raw = server.rawConfig;
    if (raw != null && raw.trim().isNotEmpty) {
      final merged = _mergeRawConfig(raw, s, server, inboundsOverride);
      if (merged != null) return merged;
    }

    // Desktop proxy mode passes socks/http inbounds; Android passes none and
    // gets the TUN inbound (the AAR injects the TUN fd via startLoop).
    final inbounds =
        inboundsOverride ??
        [_buildTunInbound(sniffingEnabled: s.sniffingEnabled)];

    final config = <String, dynamic>{
      'log': _buildLog(),
      'stats': <String, dynamic>{},
      'policy': _buildPolicy(),
      'dns': _buildDns(remoteDns: s.remoteDns, directDns: s.directDns),
      'inbounds': inbounds,
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
    final raw = server.rawConfig;
    if (raw != null && raw.trim().isNotEmpty) {
      final latency = _latencyFromRawConfig(raw);
      if (latency != null) return latency;
    }

    final config = <String, dynamic>{
      'log': {'loglevel': 'warning'},
      'outbounds': [_buildProxyOutbound(server), _buildDirectOutbound()],
    };
    return jsonEncode(config);
  }

  /// Builds a config for desktop **proxy mode**: identical routing/DNS/outbound
  /// behavior to [build], but with local SOCKS5 + HTTP inbounds instead of the
  /// Android TUN inbound. The desktop app runs the bundled `xray` binary with
  /// this config and points the OS system proxy at [socksPort]/[httpPort].
  static String buildForProxy(
    ServerConfig server, {
    VpnSettings? settings,
    int socksPort = 10808,
    int httpPort = 10809,
  }) {
    return build(
      server,
      settings: settings,
      inboundsOverride: [
        _buildSocksInbound(socksPort, sniffingEnabled: settings?.sniffingEnabled ?? true),
        _buildHttpInbound(httpPort),
      ],
    );
  }

  /// Local SOCKS5 inbound bound to loopback (desktop proxy mode).
  static Map<String, dynamic> _buildSocksInbound(
    int port, {
    bool sniffingEnabled = true,
  }) {
    return {
      'tag': 'socks-in',
      'protocol': 'socks',
      'listen': '127.0.0.1',
      'port': port,
      'settings': {'udp': true, 'auth': 'noauth'},
      if (sniffingEnabled)
        'sniffing': {
          'enabled': true,
          'destOverride': ['http', 'tls', 'quic'],
          'routeOnly': false,
        },
    };
  }

  /// Local HTTP proxy inbound bound to loopback (desktop proxy mode).
  static Map<String, dynamic> _buildHttpInbound(int port) {
    return {
      'tag': 'http-in',
      'protocol': 'http',
      'listen': '127.0.0.1',
      'port': port,
      'settings': <String, dynamic>{},
    };
  }

  /// Merges a raw JSON-subscription config for VPN use: keeps the server's
  /// outbounds/routing/dns/balancer/burstObservatory, replaces the local
  /// socks/http inbounds with the app's TUN inbound, and ensures stats+policy
  /// are present so traffic stats (QueryStats) keep working.
  ///
  /// Returns `null` if [raw] is not a usable JSON object.
  static String? _mergeRawConfig(
    String raw,
    VpnSettings s,
    ServerConfig server,
    List<Map<String, dynamic>>? inboundsOverride,
  ) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final outbounds = decoded['outbounds'];
      if (outbounds is! List || outbounds.isEmpty) return null;

      final config = Map<String, dynamic>.from(decoded);
      config['log'] = _buildLog();
      config['stats'] = <String, dynamic>{};
      config['policy'] = _buildPolicy();
      config['inbounds'] =
          inboundsOverride ??
          [_buildTunInbound(sniffingEnabled: s.sniffingEnabled)];

      // Honor the user's DNS choice (prevents a DNS leak through the
      // subscription's embedded resolver).
      config['dns'] = _buildDns(remoteDns: s.remoteDns, directDns: s.directDns);

      // The servers' own addresses MUST route direct as the FIRST rules (the
      // TUN-deadlock invariant _buildRouting enforces for built configs):
      // otherwise Xray's dial to its own server re-enters the TUN. A balancer
      // profile dials many endpoints, so collect them all from the outbounds.
      final bypassAddresses = _rawProxyAddresses(outbounds);
      if (server.address.trim().isNotEmpty) {
        bypassAddresses.add(server.address.trim());
      }
      final directTag = _ensureDirectOutbound(config, outbounds);
      final bypassIps = bypassAddresses
          .where(_isIpAddress)
          .toList(growable: false);
      final bypassDomains = bypassAddresses
          .where((a) => !_isIpAddress(a))
          .map((a) => 'full:$a')
          .toList(growable: false);
      final serverBypassRules = <Map<String, dynamic>>[
        if (bypassIps.isNotEmpty)
          {'type': 'field', 'outboundTag': directTag, 'ip': bypassIps},
        if (bypassDomains.isNotEmpty)
          {'type': 'field', 'outboundTag': directTag, 'domain': bypassDomains},
      ];

      // Prepend the user's routing choices (LAN bypass, region split-tunnel,
      // custom domain rules) ahead of the server's own rules — top-down
      // evaluation means the user's rules win while the server's balancer /
      // catch-all still handles everything else.
      final userRules = _userRoutingRules(
        bypassLan: s.bypassLan,
        enabledRegions: s.enabledRegions,
        customRules: s.customRules,
      );
      if (serverBypassRules.isNotEmpty || userRules.isNotEmpty) {
        final routing = _asMap(config['routing']) ?? <String, dynamic>{};
        final existingRules = (routing['rules'] as List?) ?? const [];
        routing['rules'] = [
          ...serverBypassRules,
          ...userRules,
          ...existingRules,
        ];
        config['routing'] = routing;
      }

      // NOTE: mux and fragment are per-outbound transport settings the
      // subscription defines itself; they are intentionally left as-is for
      // raw JSON-subscription configs.
      return jsonEncode(config);
    } catch (_) {
      return null;
    }
  }

  /// Every dial address of the raw config's proxy outbounds
  /// (`settings.vnext[].address` for VLESS/VMess, `settings.servers[].address`
  /// for Trojan/Shadowsocks). Non-proxy outbounds (freedom/blackhole/dns) are
  /// skipped.
  static Set<String> _rawProxyAddresses(List outbounds) {
    final addresses = <String>{};
    for (final o in outbounds) {
      if (o is! Map) continue;
      final proto = o['protocol'];
      if (proto == 'freedom' || proto == 'blackhole' || proto == 'dns') {
        continue;
      }
      final settings = o['settings'];
      if (settings is! Map) continue;
      for (final listKey in const ['vnext', 'servers']) {
        final entries = settings[listKey];
        if (entries is! List) continue;
        for (final entry in entries) {
          if (entry is! Map) continue;
          final address = entry['address'];
          if (address is String && address.trim().isNotEmpty) {
            addresses.add(address.trim());
          }
        }
      }
    }
    return addresses;
  }

  /// Returns the tag of the raw config's freedom (direct) outbound, appending
  /// the app's own one when the subscription didn't ship any — a routing rule
  /// pointing at a nonexistent outbound tag would break the config.
  static String _ensureDirectOutbound(
    Map<String, dynamic> config,
    List outbounds,
  ) {
    for (final o in outbounds) {
      if (o is! Map || o['protocol'] != 'freedom') continue;
      final tag = o['tag'];
      if (tag is String && tag.isNotEmpty) return tag;
    }
    final direct = _buildDirectOutbound();
    config['outbounds'] = [...outbounds, direct];
    return direct['tag'] as String;
  }

  /// Builds a latency-test config from a raw JSON-subscription config: takes
  /// the primary proxy outbound (preserving xhttp/PQ settings) plus a direct
  /// outbound, with no inbounds or geo routing (MeasureDelay constraints).
  static String? _latencyFromRawConfig(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final outbounds = decoded['outbounds'];
      if (outbounds is! List) return null;

      Map<String, dynamic>? proxy;
      for (final o in outbounds) {
        if (o is! Map<String, dynamic>) continue;
        final proto = o['protocol'];
        if (proto == 'freedom' || proto == 'blackhole') continue;
        proxy ??= Map<String, dynamic>.from(o);
        if (o['tag'] == 'proxy') {
          proxy = Map<String, dynamic>.from(o);
          break;
        }
      }
      if (proxy == null) return null;

      final config = <String, dynamic>{
        'log': {'loglevel': 'warning'},
        'outbounds': [proxy, _buildDirectOutbound()],
      };
      return jsonEncode(config);
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _buildLog() {
    return {'loglevel': 'debug'};
  }

  /// Enables traffic stats collection — CRITICAL for QueryStats() to work.
  static Map<String, dynamic> _buildPolicy() {
    return {
      'levels': {
        '0': {'statsUserUplink': true, 'statsUserDownlink': true},
      },
      'system': {'statsOutboundUplink': true, 'statsOutboundDownlink': true},
    };
  }

  /// Split DNS per D-11: remote DNS for proxied domains, localhost for local.
  ///
  /// The [remoteDns] value is already in the correct format for the protocol:
  /// - DoH: `https://1.1.1.1/dns-query`
  /// - DoT: `tls://1.1.1.1`
  /// - DoU (plain UDP, the default): `1.1.1.1`
  static Map<String, dynamic> _buildDns({
    String remoteDns = '1.1.1.1',
    String directDns = 'localhost',
  }) {
    return {
      'servers': [
        {'address': remoteDns, 'domains': <String>[], 'port': 53},
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
      'settings': {'name': 'tun0', 'mtu': 9000, 'userLevel': 0},
      'sniffing': {
        'enabled': sniffingEnabled,
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
      outbound['mux'] = {'enabled': true, 'concurrency': muxConcurrency};
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
                'security': server.encryption == 'none'
                    ? 'auto'
                    : server.encryption,
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
    final effectiveSecurity = server.network == 'h2' ? 'tls' : server.security;

    // Normalize xhttp → splithttp: this AAR's Xray-core registers the transport
    // as "splithttp" (pre-rename). Both names refer to the same protocol.
    final effectiveNetwork = server.network == 'xhttp'
        ? 'splithttp'
        : server.network;
    final isXhttp = effectiveNetwork == 'splithttp';

    final settings = <String, dynamic>{
      'network': effectiveNetwork,
      'security': effectiveSecurity,
    };

    // TLS settings
    if (effectiveSecurity == 'tls') {
      // XHTTP/SplitHTTP: mirror the verified-working Happ client exactly.
      // Happ connects to this same origin with an EMPTY uTLS fingerprint
      // (native Go TLS) and an empty ALPN list. Forcing fingerprint:"chrome"
      // — as an earlier version of this builder did — made the origin reject
      // every upload POST with HTTP 400. So for XHTTP we default to no
      // fingerprint and an explicit empty ALPN, matching Happ. Other
      // transports keep the Chrome default. User-set values always win.
      final tlsSettings = <String, dynamic>{
        'serverName': server.sni ?? server.address,
        'allowInsecure': false,
        'fingerprint': server.fingerprint ?? (isXhttp ? '' : 'chrome'),
      };
      final alpnList = server.alpn
          ?.split(',')
          .where((s) => s.isNotEmpty)
          .toList();
      if (alpnList != null && alpnList.isNotEmpty) {
        tlsSettings['alpn'] = alpnList;
      } else if (isXhttp) {
        // Happ sends an explicit empty ALPN array for XHTTP.
        tlsSettings['alpn'] = <String>[];
      }
      settings['tlsSettings'] = tlsSettings;
    }

    // Reality settings (NOT tlsSettings)
    if (effectiveSecurity == 'reality') {
      settings['realitySettings'] = {
        'serverName': server.sni ?? server.address,
        'fingerprint': server.fingerprint ?? 'chrome',
        'publicKey': server.publicKey ?? '',
        'shortId': server.shortId ?? '',
        // Default spiderX to "/" (matching the verified-working Happ config);
        // an empty spiderX is non-standard. allowInsecure/show added for parity.
        'spiderX': (server.spiderX == null || server.spiderX!.isEmpty)
            ? '/'
            : server.spiderX,
        'allowInsecure': false,
        'show': false,
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
          'headers': {'Host': server.host ?? server.address},
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
        // Reproduce the verified-working Happ client config for this origin.
        // The decisive fix for the uniform HTTP 400 was xPaddingBytes:"10-100"
        // — the origin XHTTP inbound validates the X-Padding length, and Xray's
        // default range (100-1000) is rejected. The sc* limits, mode "auto",
        // and extra.noGRPCHeader also match Happ. `mode` honors an explicit
        // link/user value, otherwise "auto" (same as Happ).
        settings['splithttpSettings'] = <String, dynamic>{
          'path': server.path ?? '/',
          'host': server.host ?? server.address,
          'mode': server.xhttpMode.isNotEmpty ? server.xhttpMode : 'auto',
          'scMaxConcurrentPosts': 10,
          'scMaxEachPostBytes': 1000000,
          'scMinPostsIntervalMs': 30,
          'extra': <String, dynamic>{
            'noGRPCHeader': true,
            'scMaxConcurrentPosts': 100,
            'scMaxEachPostBytes': 100000,
            'scMinPostsIntervalMs': 30,
            'xPaddingBytes': '10-100',
          },
        };
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
      ..._userRoutingRules(
        bypassLan: bypassLan,
        enabledRegions: enabledRegions,
        customRules: customRules,
      ),
    ];

    // Catch-all proxy (must be last)
    rules.add({'type': 'field', 'outboundTag': 'proxy', 'port': '0-65535'});

    return {'domainStrategy': 'IPIfNonMatch', 'rules': rules};
  }

  /// The user-configurable routing rules (LAN bypass, region presets, custom
  /// domain rules) — without the server-bypass or catch-all rules. Shared by
  /// [_buildRouting] and the raw-config merge so JSON-subscription servers also
  /// honor the user's routing choices (prepended before the server's rules).
  static List<Map<String, dynamic>> _userRoutingRules({
    bool bypassLan = true,
    Set<String> enabledRegions = const {},
    List<DomainRule> customRules = const [],
  }) {
    final rules = <Map<String, dynamic>>[];

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

    return rules;
  }

  /// Check if an address is an IP (v4) rather than a hostname.
  static bool _isIpAddress(String address) {
    return RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$').hasMatch(address);
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map<String, dynamic> ? value : null;
}
