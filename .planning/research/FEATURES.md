# Feature Landscape: Xray-core → sing-box Migration

**Domain:** sing-box engine migration for Flutter VPN client (censorship circumvention)
**Researched:** 2025-07-15
**sing-box version analyzed:** v1.13.6 (released 2026-04-06)
**Reference:** Hiddify sing-box fork v1.13.0.h5, standard sing-box docs
**Confidence:** HIGH — based on official sing-box v1.13.6 source code, Hiddify fork analysis, and current codebase `XrayConfigBuilder` review

---

## Migration Context

This document maps every feature in Arma's current `XrayConfigBuilder` (542 lines, `/lib/xray/xray_config_builder.dart`) and `VpnSettings` entity to sing-box equivalents. The current config builder handles 5 protocols × 4 transports × 3 TLS modes, plus anti-censorship features, routing, DNS, mux, sniffing, and per-app proxy.

**Key structural difference:** Xray-core uses a flat JSON with `inbounds[].protocol`, `outbounds[].protocol`, `outbounds[].streamSettings.network/security`. sing-box uses `inbounds[].type`, `outbounds[].type` with nested `tls`, `transport`, `multiplex` objects. The entire config builder must be rewritten — there is no field-level translation.

---

## Feature Parity Matrix: Xray-core → sing-box

### Protocols

| # | Feature | Xray-core Config | sing-box Config | Parity | Migration Notes |
|---|---------|-----------------|-----------------|--------|-----------------|
| P1 | **VLESS** | `protocol: "vless"`, `vnext[].users[].id` | `type: "vless"`, `uuid` | ✅ FULL | Direct mapping. `uuid` replaces `vnext[0].users[0].id`. |
| P2 | **VLESS + Reality** | `streamSettings.realitySettings: {publicKey, shortId, spiderX}` | `tls: {reality: {enabled: true, public_key, short_id}}` | ✅ FULL | Nested under `tls.reality` instead of top-level `realitySettings`. `spiderX` is NOT in sing-box outbound Reality config — it's a server-side crawling feature, not needed client-side. |
| P3 | **VLESS + XTLS-Vision** | `vnext[].users[].flow: "xtls-rprx-vision"` | `flow: "xtls-rprx-vision"` | ✅ FULL | Same flow value. Same constraint: only valid for VLESS + TCP + TLS/Reality. |
| P4 | **VMess** | `protocol: "vmess"`, `vnext[].users[].{id, alterId, security}` | `type: "vmess"`, `{uuid, alter_id, security}` | ✅ FULL | Field rename: `alterId` → `alter_id`. Added: `global_padding`, `authenticated_length` (both VMess AEAD features). `packet_encoding: "xudp"` default. |
| P5 | **Trojan** | `protocol: "trojan"`, `servers[].password` | `type: "trojan"`, `password` | ✅ FULL | Direct mapping. |
| P6 | **Shadowsocks** | `protocol: "shadowsocks"`, `servers[].{method, password}` | `type: "shadowsocks"`, `{method, password}` | ✅ ENHANCED | Same fields + bonus: 2022-blake3-\* ciphers, SIP003 plugins (obfs-local, v2ray-plugin), `udp_over_tcp`. |
| P7 | **Hysteria2** | `protocol: "hysteria2"`, custom streamSettings | `type: "hysteria2"`, `{password, up_mbps, down_mbps, obfs}` | ✅ ENHANCED | **New capabilities:** `server_ports` (port ranges for port hopping, since 1.11.0), `hop_interval`/`hop_interval_max` (randomized hopping), `bbr_profile` (conservative/standard/aggressive, since 1.14.0). |

### Transports

| # | Feature | Xray-core Config | sing-box Config | Parity | Migration Notes |
|---|---------|-----------------|-----------------|--------|-----------------|
| T1 | **TCP** | `streamSettings.network: "tcp"`, `tcpSettings: {header: {type: "none"}}` | No `transport` section (TCP is default) | ✅ FULL | Simpler — just omit the `transport` field entirely. No `header.type` equivalent; TCP header obfuscation is not supported (rarely used). |
| T2 | **WebSocket** | `wsSettings: {path, headers.Host}` | `transport: {type: "ws", path, headers: {Host: "..."}}` | ✅ FULL | Direct mapping. Bonus: `max_early_data` and `early_data_header_name: "Sec-WebSocket-Protocol"` for Xray compatibility. |
| T3 | **gRPC** | `grpcSettings: {serviceName, authority, multiMode}` | `transport: {type: "grpc", service_name}` | ✅ FULL | Field rename: `serviceName` → `service_name`. No `multiMode` equivalent — sing-box gRPC handles multiplexing differently. `authority` not directly available — use TLS `server_name`. |
| T4 | **HTTP/2** | `httpSettings: {host, path}` | `transport: {type: "http", host, path}` | ✅ FULL | Same semantics. sing-box does NOT enforce TLS for HTTP transport (Xray does for H2). If TLS needed, configure `tls` object explicitly. |
| T5 | **HTTPUpgrade** | ❌ Not available | `transport: {type: "httpupgrade", host, path}` | 🆕 NEW | New transport for CDN-based proxies. Not in Xray-core. Useful addition for future. |
| T6 | **QUIC transport** | ❌ Not available (separate from Hysteria2) | `transport: {type: "quic"}` | 🆕 NEW | V2Ray QUIC transport without additional encryption. |

### TLS / Security

| # | Feature | Xray-core Config | sing-box Config | Parity | Migration Notes |
|---|---------|-----------------|-----------------|--------|-----------------|
| S1 | **Standard TLS** | `streamSettings.security: "tls"`, `tlsSettings: {serverName, alpn, fingerprint, allowInsecure}` | `tls: {enabled: true, server_name, alpn, insecure}` | ✅ FULL | Field renames: `serverName` → `server_name`, `allowInsecure` → `insecure`. |
| S2 | **Reality** | `streamSettings.security: "reality"`, `realitySettings: {publicKey, shortId, fingerprint, spiderX}` | `tls: {enabled: true, reality: {enabled: true, public_key, short_id}}` | ✅ FULL | `fingerprint` for Reality goes in `tls.utls.fingerprint`. `spiderX` is server-side only — omit. |
| S3 | **uTLS Fingerprinting** | `fingerprint: "chrome"` in tlsSettings | `tls: {utls: {enabled: true, fingerprint: "chrome"}}` | ⚠️ AVAILABLE BUT DISCOURAGED | sing-box docs explicitly say uTLS is "Not Recommended" — fingerprinting vulnerabilities, poor code quality, lacks active maintenance. Values: chrome, firefox, edge, safari, 360, qq, ios, android, random, randomized. Still works; just less trusted. |
| S4 | **ECH (Encrypted Client Hello)** | ❌ Not in Xray-core | `tls: {ech: {enabled: true, config: [...]}}` | 🆕 NEW | Major anti-censorship feature. Encrypts the ClientHello entirely (including SNI). Much stronger than uTLS fingerprinting or fragment tricks. Requires server support + DNS HTTPS records. |
| S5 | **ALPN** | `tlsSettings.alpn: ["h2", "http/1.1"]` | `tls: {alpn: ["h2", "http/1.1"]}` | ✅ FULL | Direct mapping. |
| S6 | **Certificate pinning** | Not available | `tls: {certificate_public_key_sha256: [...]}` | 🆕 NEW | Pin server certificates by public key hash. Security improvement. |

### Anti-Censorship Features (CRITICAL SECTION)

| # | Feature | Xray-core Config | sing-box Config | Parity | Migration Notes |
|---|---------|-----------------|-----------------|--------|-----------------|
| AC1 | **TLS Fragment (basic)** | `sockopt.fragment: {packets: "tlshello", length: "10-100", interval: "0-10"}` | `tls: {fragment: true, fragment_fallback_delay: "500ms"}` | ⚠️ REDUCED CONTROL | Standard sing-box 1.12+ has fragment as **boolean only** — no size/sleep range parameters. It auto-detects timing on Linux/Apple/Windows. Falls back to `fragment_fallback_delay`. Less granular but potentially smarter. |
| AC2 | **TLS Record Fragment** | Not available | `tls: {record_fragment: true}` | 🆕 NEW | Fragments TLS handshake into multiple TLS records (vs TCP segments). Different technique, same goal. Can be more effective for some firewalls. |
| AC3 | **Fragment with size/sleep ranges** | `sockopt.fragment.length: "10-100"`, `sockopt.fragment.interval: "0-10"` | ❌ NOT IN STANDARD sing-box | ❌ GAP | **Hiddify fork** adds `TLSFragmentOptions{Enabled, Size, Sleep}` on dialer level. Standard sing-box has no equivalent. Options: (a) accept boolean-only fragment, (b) use Hiddify fork, (c) implement custom Go patch. |
| AC4 | **Mixed SNI Case** | Custom implementation (e.g., `GoOgLe.CoM`) | ❌ NOT IN STANDARD sing-box | ❌ GAP | **Hiddify fork** adds `TLSTricksOptions.MixedCaseSNI`. Standard sing-box has no equivalent. This is specifically important for Iran's DPI. |
| AC5 | **TLS Padding** | Custom implementation (add noise to TLS records) | ❌ NOT IN STANDARD sing-box | ❌ GAP | **Hiddify fork** adds `TLSTricksOptions.PaddingMode/PaddingSize` + forces uTLS with custom fingerprint. Standard sing-box's `multiplex.padding` is different (mux-level padding, not TLS-level). |

**Anti-censorship gap analysis:**

The current `AntiCensorshipSettings` has 4 levels: none, light, moderate, aggressive. These map to combinations of fragment (size/sleep ranges), padding, and mixed SNI. Standard sing-box only supports fragment as a boolean. **Three of four anti-censorship features have no standard sing-box equivalent.**

**Recommended approach:** Use standard sing-box `tls.fragment: true` + `tls.record_fragment: true` as the initial migration. This provides automatic TLS fragmentation that is likely sufficient for most censorship scenarios. The boolean fragment in sing-box auto-detects optimal fragmentation timing, which may actually be MORE effective than manually specified ranges for most users. Reserve the granular controls (size/sleep ranges, mixed SNI, padding) for a future phase if testing reveals standard fragment is insufficient. Hiddify's fork is available as a fallback option.

### Routing

| # | Feature | Xray-core Config | sing-box Config | Parity | Migration Notes |
|---|---------|-----------------|-----------------|--------|-----------------|
| R1 | **LAN Bypass** | `geoip:private` + `geosite:private` rules | `ip_is_private: true` rule OR `rule_set: "geosite-private"` | ✅ FULL | sing-box 1.8+ has built-in `ip_is_private` matcher — simpler than geoip:private. No DAT file needed for private IPs. |
| R2 | **Region: Iran** | `geosite:category-ir` + `geoip:ir` | `rule_set: ["geosite-category-ir", "geoip-ir"]` | ✅ FULL | Rule-sets available at `https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ir.srs` and `https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ir.srs`. Must declare in `route.rule_set[]` and enable `experimental.cache_file`. |
| R3 | **Region: China** | `geosite:cn` + `geoip:cn` | `rule_set: ["geosite-cn", "geoip-cn"]` | ✅ FULL | Available as `.srs` binary rule-sets. Same URLs pattern as Iran. |
| R4 | **Region: Russia** | `geosite:category-ru` + `geoip:ru` | `rule_set: ["geosite-category-ru", "geoip-ru"]` | ✅ FULL | Available as `.srs` binary rule-sets. |
| R5 | **Custom domain rules (proxy/direct/block)** | `routing.rules[].domain: ["domain:example.com"]` with `outboundTag` | `route.rules[].domain: ["example.com"]` with `action: "route"` + `outbound` | ✅ FULL | Syntax change: no `domain:` prefix needed. Use `domain`, `domain_suffix`, `domain_keyword`, `domain_regex` fields. `outboundTag` → `outbound`. |
| R6 | **Server address bypass** | IP rule or domain rule for server address | Same approach: `ip_cidr` or `domain` rule for server | ✅ FULL | Must still be first rule. sing-box also has `auto_detect_interface: true` which handles routing loop prevention automatically on Linux/Windows/macOS — but on Android, manual server bypass is still needed. |
| R7 | **Domain strategy** | `routing.domainStrategy: "IPIfNonMatch"` | `route.default_domain_resolver` + DNS rules | ⚠️ DIFFERENT | sing-box 1.12+ moved domain resolution to `domain_resolver` in dial fields. The `domainStrategy` concept is replaced by explicit DNS rule routing. Must configure DNS rules to resolve domains before routing. |
| R8 | **geoip/geosite (legacy)** | DAT files loaded at startup | `geoip`/`geosite` fields in rules (deprecated since 1.8) | ⚠️ DEPRECATED | Still works in 1.13.x but will be removed. **Must use `rule_set` approach** for future-proofing. Rule-sets are remote (auto-downloaded + cached) or local (bundled `.srs` files). |
| R9 | **Per-app proxy** | VpnService level (addAllowedApplication) | TUN `include_package`/`exclude_package` + route `package_name` rules | ✅ ENHANCED | sing-box handles per-app at TUN level AND route rule level. Can do `include_package: ["com.android.chrome"]` in TUN config. This is cleaner than VpnService-only approach. |
| R10 | **Catch-all rule** | `{type: "field", outboundTag: "proxy", port: "0-65535"}` | `route.final: "proxy"` | ✅ SIMPLER | No need for catch-all rule. `route.final` specifies default outbound. |

### DNS

| # | Feature | Xray-core Config | sing-box Config | Parity | Migration Notes |
|---|---------|-----------------|-----------------|--------|-----------------|
| D1 | **Split DNS (remote + direct)** | `dns.servers: [{address: "https://1.1.1.1/dns-query"}, "localhost"]` | `dns.servers: [{type: "https", tag: "remote", server: "1.1.1.1"}, {type: "local", tag: "local"}]` | ✅ FULL | More explicit. New typed DNS servers (since 1.12.0). Must add DNS rules to route queries to correct server. |
| D2 | **DoH (DNS over HTTPS)** | `dns.servers[].address: "https://1.1.1.1/dns-query"` | `dns.servers[]: {type: "https", server: "1.1.1.1", path: "/dns-query"}` | ✅ FULL | Split into `server` + `path` fields. |
| D3 | **DoT (DNS over TLS)** | `dns.servers[].address: "tls://1.1.1.1"` | `dns.servers[]: {type: "tls", server: "1.1.1.1"}` | ✅ FULL | Explicit type. Default port 853. |
| D4 | **Plain DNS** | `dns.servers[].address: "1.1.1.1"` | `dns.servers[]: {type: "udp", server: "1.1.1.1"}` | ✅ FULL | Explicit `udp` type. |
| D5 | **FakeIP** | ❌ Not in Xray-core | `dns.servers[]: {type: "fakeip"}` + `dns.fakeip` config | 🆕 NEW | Eliminates DNS query latency by returning fake IPs and resolving at proxy. Hiddify uses this. Major performance improvement. |
| D6 | **DNS over QUIC** | ❌ Not in Xray-core | `dns.servers[]: {type: "quic", server: "dns.adguard.com"}` | 🆕 NEW | Fastest encrypted DNS option. |
| D7 | **DNS over HTTP/3** | ❌ Not in Xray-core | `dns.servers[]: {type: "h3", server: "8.8.8.8"}` | 🆕 NEW | |

### Engine Features

| # | Feature | Xray-core Config | sing-box Config | Parity | Migration Notes |
|---|---------|-----------------|-----------------|--------|-----------------|
| E1 | **Sniffing** | `inbound.sniffing: {enabled, destOverride: ["http","tls","quic"]}` | Route rules with `protocol: ["tls","http","quic"]` matcher | ⚠️ ARCHITECTURE CHANGE | Sniffing in sing-box 1.11+ is NOT an inbound toggle. Protocol detection happens automatically; routing decisions use `protocol` field in route rules. Legacy `sniff: true` still works in 1.13 but deprecated. For the user-facing "sniffing toggle", the migration must change approach: when sniffing is "enabled", add protocol-based route rules; when "disabled", omit them. Alternatively, use `sniff_override_destination: true` (deprecated but functional in 1.13). |
| E2 | **Mux (Multiplexing)** | `outbound.mux: {enabled: true, concurrency: 4}` | `outbound.multiplex: {enabled: true, protocol: "h2mux", max_streams: 4, padding: false}` | ✅ ENHANCED | Protocol choices: `smux`, `yamux`, `h2mux` (default). `padding` adds padding to mux frames (anti-detection). `brutal` for TCP Brutal bandwidth optimization. `concurrency` → `max_connections` or `max_streams`. |
| E3 | **TUN Inbound** | `protocol: "tun"`, `settings: {name: "tun0", MTU: 9000}` | `type: "tun"`, `interface_name: "tun0"`, `mtu: 9000`, `auto_route: true`, `stack: "mixed"` | ✅ ENHANCED | sing-box TUN has `stack` option: `system` (OS network stack), `gVisor` (user-space), `mixed` (TCP=system, UDP=gVisor). `auto_route: true` handles routing table automatically. `strict_route: true` for leak prevention. |
| E4 | **Traffic Stats** | `stats: {}` + `policy.system.statsOutbound*` → gRPC QueryStats | V2Ray API: `experimental.v2ray_api.stats: {enabled, outbounds: ["proxy","direct"]}` | ✅ FULL | V2Ray API must be built with v2ray tag. Alternative: Clash API (`experimental.clash_api`) provides traffic info + mode switching. |
| E5 | **Log level** | `log.loglevel: "debug"` | `log: {level: "debug", output: "box.log"}` | ✅ FULL | Same levels: trace, debug, info, warn, error, fatal, panic. |
| E6 | **Direct outbound** | `protocol: "freedom"` | `type: "direct"` | ✅ FULL | Rename only. |
| E7 | **Block outbound** | `protocol: "blackhole"`, `settings.response.type: "http"` | `type: "block"` | ✅ SIMPLER | No response type needed. Just blocks. |

---

## Features That GAIN Capabilities in sing-box

| # | Feature | What's New | Impact |
|---|---------|-----------|--------|
| G1 | **Hysteria2 port hopping** | `server_ports: ["2080:3000"]` + `hop_interval` | Better anti-blocking: hop across port ranges to evade port-based blocking. |
| G2 | **ECH (Encrypted Client Hello)** | Full ClientHello encryption | Strongest anti-censorship TLS feature. Hides SNI entirely. Much better than mixed case SNI tricks. |
| G3 | **FakeIP DNS** | Fake IP responses + proxy-side resolution | Eliminates DNS latency for proxied domains. Significant speed improvement. |
| G4 | **TLS record_fragment** | Fragment at TLS record level | Additional fragmentation technique alongside TCP-level fragment. |
| G5 | **Mux protocol choice** | h2mux/yamux/smux + padding + TCP Brutal | More sophisticated multiplexing with anti-detection padding. |
| G6 | **Per-app proxy at TUN level** | `include_package`/`exclude_package` in TUN config | Cleaner per-app proxy than VpnService-only approach. Can also use route rules with `package_name`. |
| G7 | **Rule-set with auto-update** | Remote `.srs` files with `update_interval` + caching | No need to bundle large DAT files. Auto-updates geo rules from GitHub. |
| G8 | **Network strategy** | `network_strategy`, `network_type`, `fallback_network_type` | Automatic WiFi/cellular fallback behavior in dialer. |
| G9 | **TUN stack options** | `system`, `gVisor`, `mixed` | Performance tuning: `mixed` uses OS TCP stack (faster) + gVisor UDP (reliable). |
| G10 | **HTTPUpgrade transport** | New transport type for CDN proxies | Can pass through CDNs more reliably than WebSocket in some scenarios. |

---

## Features That Work DIFFERENTLY

| # | Feature | Current (Xray) Behavior | sing-box Behavior | Action Required |
|---|---------|------------------------|-------------------|-----------------|
| W1 | **Config JSON structure** | Flat: `{inbounds, outbounds, routing, dns, stats, policy}` | Structured: `{inbounds, outbounds, route, dns, experimental, log}` | Complete `SingboxConfigBuilder` rewrite. Every JSON key is different. |
| W2 | **Transport config** | `streamSettings.network` + `wsSettings/grpcSettings/httpSettings` | `transport: {type: "ws"/"grpc"/"http", ...}` | Unified transport object replaces per-transport top-level fields. |
| W3 | **TLS/Reality config** | `streamSettings.security` + `tlsSettings/realitySettings` | `tls: {enabled, server_name, utls, reality, fragment, ech, ...}` | Single `tls` object with nested sub-configs. No separate `realitySettings` top level. |
| W4 | **Sniffing** | Per-inbound toggle: `sniffing.enabled` | Route rules with `protocol` matcher (1.11+) | Architecture change. The "sniffing enabled" toggle must translate to adding/removing protocol-based route rules, not an inbound field. |
| W5 | **Geo routing** | Inline `geoip:cn` / `geosite:cn` in rules | `rule_set` references + `route.rule_set[]` declarations | Must declare rule-sets (remote or local) and reference by tag in rules. Requires `experimental.cache_file.enabled: true` for caching. |
| W6 | **DNS config** | `dns.servers: [{address: "https://...", domains: [...]}]` | `dns.servers: [{type: "https", tag: "...", server: "..."}]` + `dns.rules` | Split: server definitions are separate from routing. DNS rules route queries to servers by domain/geosite. |
| W7 | **Catch-all routing** | `{type: "field", outboundTag: "proxy", port: "0-65535"}` | `route.final: "proxy"` | Simpler. Single field instead of a catch-all rule. |
| W8 | **Latency testing** | Custom config for `MeasureDelay()` | sing-box `URLTest` group outbound OR custom URL fetch | May need to change latency testing approach. sing-box's `urltest` outbound type handles this natively. |
| W9 | **Outbound user stats** | `policy.levels.0.statsUser*` + user `email` field | `experimental.v2ray_api.stats.outbounds: ["proxy"]` | Stats are tracked per-outbound tag, not per-user email. Simpler to configure. |

---

## Anti-Features (Do NOT Build)

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Use Hiddify's fork directly as a dependency | Creates coupling to Hiddify's release cycle. Fork may diverge from upstream. Hiddify's fork has features Arma doesn't need (WARP, ad blocking). | Use standard sing-box library. If granular fragment/padding/mixed-SNI needed later, apply minimal Go patches or evaluate if standard fragment is sufficient. |
| Bundle geoip.dat / geosite.dat files | Large files (10-30MB) increase APK size. sing-box deprecated DAT format. | Use remote `rule_set` with `.srs` binary format. Auto-download + cache with `experimental.cache_file`. |
| Implement sniffing as inbound toggle | Deprecated in sing-box 1.11+, will be removed in 1.13+. | Use route rules with `protocol` matcher. The UI toggle controls whether protocol-based rules exist in config. |
| Support mKCP or DomainSocket transports | Not available in sing-box. Very rarely used. | Don't add to transport options. TCP, WS, gRPC, HTTP cover 99.9% of use cases. |

---

## Feature Dependencies for Migration

```
Config Builder Rewrite (W1)
├── Protocol mapping (P1-P7) — depends on config structure
├── Transport mapping (T1-T4) — depends on config structure
├── TLS mapping (S1-S3) — depends on config structure
├── Anti-censorship (AC1-AC2) — depends on TLS mapping
├── DNS rewrite (D1-D4) — depends on config structure
├── Routing rewrite (R1-R10) — depends on route + rule_set structure
├── Sniffing migration (E1) — depends on routing rewrite
├── Mux migration (E2) — depends on protocol mapping
└── Stats/API migration (E4) — depends on experimental config

Rule-set Infrastructure (R8)
├── Region presets (R2-R4) — need rule_set declarations
├── LAN bypass (R1) — can use ip_is_private (no rule-set needed)
└── Cache file config — required for remote rule-sets

Native Integration (E3)
├── TUN inbound config — new fields (stack, auto_route, strict_route)
├── Per-app proxy (R9) — TUN include_package/exclude_package
└── Traffic stats (E4) — V2Ray API or Clash API setup
```

---

## MVP Migration Recommendation

**Phase 1: Core Config Builder** — Prioritize protocols (P1-P7) + transports (T1-T4) + TLS (S1-S3) + basic routing (R1, R5, R6, R10). This gets connections working.

**Phase 2: Advanced Features** — Anti-censorship (AC1-AC2), mux (E2), sniffing (E1), DNS rewrite (D1-D4).

**Phase 3: Routing & Rule-sets** — Region presets (R2-R4) via rule_set infrastructure (R8), per-app proxy (R9).

**Defer:** Fragment size/sleep ranges (AC3), mixed SNI (AC4), padding (AC5) — evaluate if standard `tls.fragment: true` is sufficient first. These can be added later if testing reveals they're needed.

**Add opportunistically:** FakeIP (D5), ECH (S4), Hysteria2 port hopping (G1) — new capabilities that come free with sing-box.

---

## Config Example: Xray → sing-box Translation

### Xray-core (current)
```json
{
  "log": {"loglevel": "debug"},
  "stats": {},
  "policy": {"levels": {"0": {"statsUserUplink": true, "statsUserDownlink": true}}, "system": {"statsOutboundUplink": true, "statsOutboundDownlink": true}},
  "dns": {"servers": [{"address": "https://1.1.1.1/dns-query", "domains": [], "port": 53}, "localhost"]},
  "inbounds": [{"tag": "tun-in", "protocol": "tun", "settings": {"name": "tun0", "MTU": 9000, "userLevel": 0}, "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"]}}],
  "outbounds": [
    {"tag": "proxy", "protocol": "vless", "settings": {"vnext": [{"address": "server.com", "port": 443, "users": [{"id": "uuid", "encryption": "none", "flow": "xtls-rprx-vision"}]}]}, "streamSettings": {"network": "tcp", "security": "reality", "realitySettings": {"serverName": "www.google.com", "fingerprint": "chrome", "publicKey": "key", "shortId": "id"}}, "mux": {"enabled": true, "concurrency": 4}},
    {"tag": "direct", "protocol": "freedom"},
    {"tag": "block", "protocol": "blackhole"}
  ],
  "routing": {"domainStrategy": "IPIfNonMatch", "rules": [{"type": "field", "outboundTag": "direct", "ip": ["geoip:private"]}, {"type": "field", "outboundTag": "proxy", "port": "0-65535"}]}
}
```

### sing-box (target)
```json
{
  "log": {"level": "debug"},
  "experimental": {
    "v2ray_api": {"listen": "127.0.0.1:10085", "stats": {"enabled": true, "outbounds": ["proxy", "direct"]}},
    "cache_file": {"enabled": true}
  },
  "dns": {
    "servers": [
      {"type": "https", "tag": "remote-dns", "server": "1.1.1.1", "path": "/dns-query", "domain_resolver": "local-dns"},
      {"type": "local", "tag": "local-dns"}
    ],
    "rules": [
      {"rule_set": "geosite-private", "server": "local-dns"}
    ]
  },
  "inbounds": [
    {"type": "tun", "tag": "tun-in", "interface_name": "tun0", "mtu": 9000, "auto_route": true, "strict_route": true, "stack": "mixed", "address": ["172.18.0.1/30", "fdfe:dcba:9876::1/126"], "include_package": [], "exclude_package": []}
  ],
  "outbounds": [
    {"type": "vless", "tag": "proxy", "server": "server.com", "server_port": 443, "uuid": "uuid", "flow": "xtls-rprx-vision", "tls": {"enabled": true, "utls": {"enabled": true, "fingerprint": "chrome"}, "reality": {"enabled": true, "public_key": "key", "short_id": "id"}, "server_name": "www.google.com"}, "multiplex": {"enabled": true, "protocol": "h2mux", "max_streams": 4}},
    {"type": "direct", "tag": "direct"},
    {"type": "block", "tag": "block"}
  ],
  "route": {
    "rules": [
      {"ip_is_private": true, "outbound": "direct"},
      {"protocol": ["dns"], "outbound": "dns-out"}
    ],
    "rule_set": [],
    "final": "proxy",
    "auto_detect_interface": true
  }
}
```

---

## Sources

| Source | Confidence | What it verified |
|--------|-----------|-----------------|
| sing-box v1.13.6 official docs (sing-box.sagernet.org) | HIGH | All protocol/transport/TLS/route/DNS configurations |
| sing-box v1.13.6 Go source (github.com/SagerNet/sing-box/option/tls.go) | HIGH | `OutboundTLSOptions` struct — confirms `Fragment: bool`, `RecordFragment: bool`, no size/sleep ranges |
| Hiddify sing-box fork v1.13.0.h5 source (github.com/hiddify/hiddify-sing-box) | HIGH | `TLSTricksOptions`, `TLSFragmentOptions` — confirms fork-only features |
| Hiddify app source (github.com/hiddify/hiddify-app) | HIGH | `SingboxTlsTricks` Dart model, `SingboxConfigOption`, Go-side config builder |
| Hiddify-core source (github.com/hiddify/hiddify-core/v2/config/) | HIGH | `outbound.go` — `patchOutboundTLSTricks()`, `patchOutboundFragment()` implementation |
| SagerNet/sing-geoip rule-set branch | HIGH | Available `.srs` files for IR, CN, RU, private |
| SagerNet/sing-geosite rule-set branch | HIGH | Available `.srs` files for category-ir, cn, category-ru, private |
| Current codebase `xray_config_builder.dart` | HIGH | All current Xray features mapped |
| Current codebase `vpn_settings.dart` + `anti_censorship_provider.dart` | HIGH | All current UI settings mapped |
