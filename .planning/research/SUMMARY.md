# Research Summary: Arma v1.1 — sing-box Engine Migration

**Project:** Arma Proxy & VPN Client v1.1
**Domain:** Xray-core → sing-box engine migration in Flutter VPN client (Android, censorship circumvention)
**Researched:** 2026-04-07
**Overall Confidence:** HIGH — all findings verified against sing-box v1.13.6 source code, SFA/Hiddify reference apps, and line-by-line Arma v1.0 codebase analysis

## Executive Summary

The v1.1 migration from Xray-core to sing-box is an **engine swap, not an architecture rewrite**. The entire Flutter/Dart layer — UI screens, Riverpod providers, share link parsers, entities, Hive storage, platform channel interfaces — remains untouched. What changes is confined to: (1) a **complete rewrite** of the Dart config builder (543 lines of Xray JSON → new sing-box JSON schema), (2) **three Kotlin files** rewritten to use sing-box's CommandServer/CommandClient architecture instead of libv2ray's CoreController pattern, and (3) **binary asset swaps** (libv2ray.aar → libbox.aar, v2fly geo files → sing-geoip/sing-geosite files). All 5 existing protocols (VLESS, VMess, Trojan, Shadowsocks, Hysteria2) and all 4 transports (TCP, WS, gRPC, H2) have full parity in sing-box, with bonus capabilities like ECH, FakeIP DNS, HTTPUpgrade transport, and Hysteria2 port hopping.

The single highest-risk architectural change is **inverted TUN control**: Xray-core receives a TUN file descriptor from Android (`startLoop(config, tunFd)`), while sing-box *requests* one via a `PlatformInterface.openTun(TunOptions)` callback — meaning the VPN service must implement a 15+ method platform contract where sing-box drives TUN creation, socket protection, and network monitoring. This inverts the control flow of `ArmaVpnService` and is the change most likely to cause integration bugs.

The most dangerous **user-facing risk** is anti-censorship feature regression. Xray-core allows fine-tuned TLS fragment parameters (`length: "10-100"`, `interval: "0-5"`) that Iranian users depend on. Standard sing-box reduces this to a boolean (`tls.fragment: true`) with auto-detected timing. Three of four anti-censorship features (granular fragment, mixed SNI, TLS padding) have **no standard sing-box equivalent** — they exist only in Hiddify's fork. The recommended approach is to ship with standard sing-box's boolean fragment (which auto-detects optimal timing and may actually work better for most users), test in target regions, and maintain a dual-engine rollback capability until sing-box proves stable in censored environments.

## Key Findings

### Stack Changes (from STACK.md)

The existing Flutter/Dart/Riverpod/Hive/go_router stack is **completely unchanged**. Only the engine integration layer changes:

- **libbox.aar (v1.13.6):** Replaces libv2ray.aar. Built via Go-Mobile (`gomobile bind`) from `experimental/libbox/`. Arma's `minSdk=24` works with the standard variant (API 23+). Build from source with tags `with_gvisor,with_quic,with_utls` for minimum viable feature set.
- **CommandServer/CommandClient architecture:** Replaces CoreController. gRPC-based IPC over Unix domain socket. VPN service hosts CommandServer; Flutter process uses CommandClient for stats/status streaming.
- **sing-box JSON config format:** Every key is different from Xray JSON. `protocol` → `type`, `vnext[].address` → flat `server`, `streamSettings.tlsSettings` → nested `tls {}`, `routing` → `route`, `freedom` → `direct`, `blackhole` → `block`. Zero field-level reuse — complete config builder rewrite required.
- **Geo assets:** sing-box uses its **own** geo format (sing-geoip/sing-geosite), NOT v2fly format. Existing `.dat` files are incompatible. Preferred approach: remote rule-sets (`.srs` binary format) with `experimental.cache_file` caching. Bundle fallback `.srs` files in APK for offline-first (users may not have internet without VPN on first launch).

### Feature Parity (from FEATURES.md)

**Full parity (table stakes — must work on day 1):**
- All 5 protocols: VLESS (+ Reality + XTLS Vision), VMess, Trojan, Shadowsocks, Hysteria2
- All 4 transports: TCP, WebSocket, gRPC, HTTP/2
- TLS + Reality + uTLS fingerprinting
- Split DNS (DoH/DoT/Plain), LAN bypass, region presets (Iran/China/Russia)
- Per-app proxy (cleaner in sing-box: TUN-level `include_package`/`exclude_package`)
- Traffic monitoring (richer: StatusMessage gives bytes/sec + totals + connection counts)

**Reduced capability (critical gap):**
- **TLS Fragment:** Boolean only — no min/max length or interval ranges. sing-box auto-detects timing. Expose `fragment_fallback_delay` as the tuning knob. May be sufficient for most users but needs real-world testing.
- **Mixed SNI case randomization:** Not in standard sing-box. Hiddify fork only.
- **TLS Padding:** Not in standard sing-box. Hiddify fork only.

**New capabilities (gained for free):**
- ECH (Encrypted Client Hello) — strongest anti-censorship TLS feature, hides SNI entirely
- FakeIP DNS — eliminates DNS latency for proxied domains
- TLS record_fragment — alternative fragmentation technique at TLS record level
- HTTPUpgrade transport — better CDN traversal than WebSocket
- Hysteria2 port hopping — evades port-based blocking
- Mux protocol choice (h2mux/yamux/smux) with anti-detection padding

**Behavior differences requiring careful handling:**
- **Sniffing:** No longer an inbound toggle. Protocol detection is automatic; the "sniffing" user setting maps to adding/removing `protocol`-based route rules.
- **Mux:** sing-box mux is **not interoperable** with Xray-core servers. Must default to disabled since most user servers run Xray-core.
- **Geo routing:** Deprecated `geoip:`/`geosite:` syntax → `rule_set` references with declared remote/local sources.
- **DNS:** Completely restructured with typed servers (`{type: "https", tag, server}`) and separate `dns.rules` for routing.

### Architecture (from ARCHITECTURE.md)

This is an **engine swap** with a clear boundary. The migration touches 5 files (2 rewrites + 3 modifications) out of ~50+ in the project.

**What changes (complete list):**
1. `lib/xray/xray_config_builder.dart` → new `lib/singbox/singbox_config_builder.dart` (complete rewrite, ~500 lines)
2. `android/.../core/XrayCoreManager.kt` → new `SingBoxCoreManager.kt` (complete rewrite)
3. `android/.../service/ArmaVpnService.kt` — heavy modification (implements PlatformInterface + CommandServerHandler)
4. `android/.../monitor/TrafficMonitor.kt` — rewrite (CommandClient subscription replaces QueryStats polling)
5. `android/.../MainActivity.kt` — minor (measureDelay implementation change, import changes)
6. `android/app/libs/libv2ray.aar` → `libbox.aar` (binary swap)
7. `android/app/src/main/assets/geo*.dat` → geo `.srs` files (format swap)

**What stays (everything else):**
All Flutter UI, all Riverpod providers, `ServerConfig` entity, `VpnSettings` entity, all share link parsers, subscription parser, `VpnPlatformService` (MethodChannel/EventChannel wrapper), `ConnectionNotifier` (1-line change: builder call), Hive storage, theme, navigation, localization, Messenger IPC, notification manager, AndroidManifest.

**Critical architecture inversion:**
- **Before:** Android creates TUN → passes fd TO engine → engine uses it
- **After:** Android starts CommandServer → engine calls BACK via `PlatformInterface.openTun(TunOptions)` → Android creates TUN from engine-provided options → returns fd

### Top Pitfalls (from PITFALLS.md — 17 identified, 5 critical)

1. **Config JSON completely incompatible (#1, CRITICAL):** Zero reuse of XrayConfigBuilder. Every key, every nesting level is different. Build `SingboxConfigBuilder` from scratch. Keep old builder for rollback. Use `Libbox.checkConfig()` and `Libbox.formatConfig()` for validation during development.

2. **libbox API fundamentally different (#2, CRITICAL):** No `startLoop(config, fd)`. No `queryStats()`. No `measureOutboundDelay()`. The entire Kotlin native layer needs rewriting around CommandServer/CommandClient + PlatformInterface. Study SFA (sing-box for Android) source as canonical reference.

3. **Geo data format incompatible (#3, CRITICAL):** sing-box 1.12+ removed `geoip:`/`geosite:` syntax. Must use `rule_set` with `.srs` binary files (remote with caching, or bundled). LAN bypass simplifies to `ip_is_private: true`.

4. **TLS Fragment reduced control (#4, CRITICAL):** Boolean-only fragment in standard sing-box. No length/interval ranges. Three of four anti-censorship features (granular fragment, mixed SNI, padding) are Hiddify-fork-only. Test in Iran/China before committing. Keep Xray fallback.

5. **No rollback plan is catastrophic (#15, HIGH):** Users in censored regions lose internet access if sing-box fails. Ship with dual-engine feature flag (both AARs in APK, engine selector in Settings). Accept ~25MB APK size increase. Remove Xray engine only after 2-3 stable releases.

## Implications for Roadmap

Based on the dependency analysis across all 4 research documents, the migration decomposes into **5 phases** with a clear critical path:

### Phase 1: Library Swap + Core Manager (Foundation)
**Rationale:** Everything depends on the AAR loading and initializing. This is the blocking prerequisite — no other phase can be verified without it.
**Delivers:** sing-box AAR integrated, `SingBoxCoreManager.setup()` working, `Libbox.version()` returning valid string, geo assets replaced.
**Addresses:** Build configuration (STACK §1-2), geo asset replacement (PITFALLS #3), initialization pattern (STACK §8).
**Avoids:** Pitfall #12 (build tags) — select minimal tag set (`with_gvisor,with_quic,with_utls`).
**Estimated scope:** Replace AAR binary, replace geo assets with bundled `.srs` fallbacks, create `SingBoxCoreManager.kt` with `setup()` + `version()`, update `build.gradle.kts`.
**Verification:** App builds, service initializes without crash, version string logged.

### Phase 2: Config Builder (Dart — parallelizable with Phase 1)
**Rationale:** Pure Dart with zero native dependency. Can proceed simultaneously with Phase 1. The config builder is the largest single rewrite (~500 lines) and benefits from early start.
**Delivers:** `SingboxConfigBuilder.build(server, settings)` producing valid sing-box JSON for all protocol × transport × TLS combinations.
**Addresses:** All protocol mappings (FEATURES P1-P7), transport mappings (T1-T4), TLS/Reality/uTLS (S1-S3), DNS rewrite (D1-D4), routing rules (R1-R10), sniffing architecture change (E1), mux migration (E2), TUN inbound format (E3).
**Avoids:** Pitfall #1 (config incompatibility) — build from scratch, don't modify XrayConfigBuilder. Pitfall #7 (transport differences) — handle each transport individually, add `early_data_header_name` for WS Xray compat. Pitfall #9 (mux) — default disabled since not interoperable with Xray servers.
**Estimated scope:** New `singbox_config_builder.dart` with builders for: outbound (5 protocols), transport (4 types), TLS/Reality/uTLS, DNS (typed servers + rules), routing (rule-sets + ip_is_private + region presets), TUN inbound, multiplex, per-app proxy (include/exclude_package), experimental section.
**Verification:** Unit tests — feed generated JSON to `Libbox.checkConfig()`. Compare against known-good sing-box configs from SFA reference. Test every protocol × transport × TLS combination.

### Phase 3: VPN Service Integration (Highest Risk)
**Rationale:** Depends on Phase 1 (AAR present) + Phase 2 (valid configs). This is the highest-risk phase — inverted TUN control, PlatformInterface with 15+ methods, CommandServer lifecycle. Everything after this depends on a working connection.
**Delivers:** Basic connect/disconnect working through sing-box engine. User taps Connect, traffic flows through proxy, taps Disconnect, service stops cleanly.
**Addresses:** CommandServer lifecycle (STACK §9), PlatformInterface contract (STACK §3), inverted TUN creation (ARCHITECTURE §Critical Difference), socket protection change (PITFALLS #6).
**Avoids:** Pitfall #2 (API completely different) — implement full PlatformInterface using Hiddify's wrapper pattern as baseline. Pitfall #6 (socket protection) — `autoDetectInterfaceControl(fd)` + `auto_detect_interface: true` in route config.
**Estimated scope:** Implement `PlatformInterfaceWrapper` (copy Hiddify pattern), modify `ArmaVpnService` to implement both `CommandServerHandler` and `PlatformInterface`, implement `openTun(TunOptions)`, implement `autoDetectInterfaceControl(fd)`, replace startLoop/stopLoop with CommandServer start/close, update shutdown order.
**Verification:** Manual connect → browse internet → disconnect. Test with VLESS+Reality+TCP first (most common in censored regions).

### Phase 4: Traffic Monitoring + Latency Testing
**Rationale:** Depends on Phase 3 (running CommandServer to subscribe to). Restores dashboard functionality and server list latency display.
**Delivers:** Real-time upload/download speed on dashboard, latency testing for individual nodes and bulk testing.
**Addresses:** Traffic stats mechanism (PITFALLS #5), latency testing architecture (PITFALLS #11), CommandClient usage (STACK §6).
**Avoids:** Pitfall #5 (QueryStats doesn't exist) — use CommandClient status stream subscription. Pitfall #11 (no measureDelay) — start temp instance with SOCKS inbound, HTTP probe from Dart.
**Estimated scope:** Rewrite `TrafficMonitor` as CommandClient subscriber, wire StatusMessage → EventChannel, implement new latency test (temporary SOCKS instance + HTTP measurement), update `ConnectionNotifier` to call `SingBoxConfigBuilder`.
**Verification:** Dashboard shows live speed, latency test returns valid ms values, bulk test completes for server list.

### Phase 5: Anti-Censorship Verification + Rollback + Cleanup
**Rationale:** All core functionality must work before testing anti-censorship features in hostile network environments. This phase validates the migration against real-world censorship and establishes the safety net.
**Delivers:** Verified anti-censorship features, dual-engine rollback capability, full v1.0 feature parity confirmed, old Xray code either retained (for dual-engine) or removed.
**Addresses:** Fragment behavior (PITFALLS #4), Reality/XTLS flow, mux, per-app proxy via TunOptions, region presets via rule-sets, custom domain rules, rollback strategy (PITFALLS #15).
**Avoids:** Pitfall #4 (fragment regression) — test in Iran/China/Russia before removing Xray fallback. Pitfall #15 (no rollback) — implement dual-engine feature flag. Pitfall #16 (insufficient testing) — full protocol × transport × TLS matrix against Xray-core servers.
**Estimated scope:** Verify `tls.fragment: true` + `tls.record_fragment: true` in target regions, verify per-app proxy via TunOptions, verify region presets via rule-sets, implement dual-engine toggle (Settings → Engine selector), full regression test of all v1.0 features, decision on Xray removal timing.
**Verification:** All protocol × transport × TLS combinations work against Xray-core servers. Anti-censorship features tested in target regions. Dual-engine toggle works.

### Phase Dependency Graph

```
Phase 1 (AAR + Core Manager) ──┐
                                ├──→ Phase 3 (VPN Integration) ──→ Phase 4 (Stats + Latency) ──→ Phase 5 (Verify + Ship)
Phase 2 (Config Builder) ─────┘
```

- **Phases 1 and 2 are parallelizable** — config builder is pure Dart, AAR integration is pure Kotlin/Gradle
- **Phase 3 is the critical path** — everything after it requires a working VPN connection
- **Phase 4 before Phase 5** — need working monitoring before testing anti-censorship in the field
- **Phase 5 is the gate to release** — no ship without region testing and rollback capability

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 3 (VPN Integration):** Highest-risk phase. The PlatformInterface contract (15+ methods), CommandServer lifecycle, and inverted TUN control are complex. Study SFA and Hiddify source in detail before writing code. May need `/gsd-research-phase` for exact PlatformInterface implementation details.
- **Phase 5 (Anti-Censorship):** Whether standard sing-box boolean fragment is sufficient for Iran/China DPI is unknown until real-world testing. The decision to use Hiddify's fork vs standard sing-box may need to be made here. May need `/gsd-research-phase` for Hiddify fork integration specifics if standard fragment proves insufficient.

**Phases with standard/well-documented patterns (skip research):**
- **Phase 1 (Library Swap):** Straightforward binary swap + init code. SFA reference provides exact pattern.
- **Phase 2 (Config Builder):** sing-box config format is exhaustively documented. FEATURES.md has complete field-by-field mapping for every protocol, transport, TLS mode, DNS type, and routing rule.
- **Phase 4 (Traffic + Latency):** CommandClient subscription is well-documented in SFA. Latency via SOCKS proxy is a standard pattern.

## Open Decisions

These decisions should be resolved during phase planning or early implementation:

| Decision | Options | Recommendation | Resolve By |
|----------|---------|----------------|------------|
| **Standard sing-box vs Hiddify fork** | (a) Standard sing-box with boolean fragment, (b) Hiddify fork with granular fragment/padding/mixed-SNI | Start with standard sing-box. Only switch to Hiddify fork if field testing in Phase 5 proves boolean fragment insufficient. | Phase 5 |
| **Dual-engine rollback** | (a) Feature flag both engines in APK, (b) Version-gated beta, (c) Clean break | Feature flag (Strategy A). Keep both AARs, add engine selector in Settings. Accept ~25MB size increase. | Phase 5 |
| **Latency testing approach** | (a) URLTest outbound group, (b) SOCKS + Dart HTTP, (c) Custom Go wrapper | Option B (SOCKS + Dart HTTP) for disconnected testing. Option A for connected state if needed. | Phase 4 |
| **Geo data delivery** | (a) Bundle `.srs` files in APK, (b) Remote rule-sets with caching, (c) Both (bundled fallback + remote update) | Option C — bundle `.srs` fallbacks for offline-first, enable remote `rule_set` with `cache_file` for auto-updates. | Phase 2 |
| **Mux default** | (a) Enabled by default, (b) Disabled by default with warning | Disabled by default. sing-box mux is not interoperable with Xray-core servers (most user servers). Show warning in Settings. | Phase 2 |

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All API surfaces verified against sing-box v1.13.6 source code. Build process verified from Makefile + build_libbox. Every libbox method signature confirmed. |
| Features | HIGH | Complete field-by-field mapping for all 7 protocols, 4 transports, 3 TLS modes, DNS types, routing rules. Verified against official docs + Go source structs. Anti-censorship gaps confirmed via `OutboundTLSOptions` struct inspection. |
| Architecture | HIGH | Component-by-component analysis of what changes/stays. Data flow diagrams verified against SFA and Hiddify reference implementations. PlatformInterface contract confirmed from source. |
| Pitfalls | HIGH | 17 pitfalls identified with severity/likelihood/confidence ratings. All derived from source code analysis, not documentation alone. Phase-specific warning matrix provided. |

**Overall confidence: HIGH** — All findings cross-verified against sing-box v1.13.6 source code, SFA reference app source, Hiddify reference app source, and existing Arma v1.0 codebase. No reliance on training data or documentation alone.

### Gaps to Address

- **TLS fragment effectiveness in Iran/China:** Unknown whether sing-box's auto-detected boolean fragment performs as well as Xray's manually-tuned length/interval ranges in real censored networks. Must be validated with field testing in Phase 5 before removing Xray fallback.
- **Hiddify fork stability and maintenance:** If standard fragment proves insufficient, Hiddify's fork is the fallback. But coupling to their release cycle is a risk. Need to evaluate fork divergence from upstream before committing.
- **Latency testing performance at scale:** The SOCKS-proxy-per-server approach for bulk latency testing may be slow (starting/stopping temp instances). May need optimization (connection pooling, URLTest group) if server lists are large (50+ nodes).
- **IPC simplification opportunity:** CommandClient/CommandServer may partially replace the existing Messenger IPC for status and stats. The exact boundary (what stays as Messenger vs what moves to CommandClient) needs to be determined during Phase 3 implementation.
- **sing-box version pinning:** v1.13.6 is current stable. The `testing` branch has further breaking changes (DNS format in 1.14.0). Must pin to 1.13.x and not accidentally pull breaking changes.

## Sources

### Primary (HIGH confidence)
- **sing-box v1.13.6 source code** — `github.com/SagerNet/sing-box` (testing branch, default): `experimental/libbox/` (service.go, setup.go, platform.go, config.go, command_server.go, command_client.go, tun.go), `option/` (all config option structs including `OutboundTLSOptions`), `cmd/internal/build_libbox/main.go`
- **SFA reference app** — `github.com/SagerNet/sing-box-for-android` (dev branch): BoxService.kt, VPNService.kt, PlatformInterfaceWrapper.kt — canonical PlatformInterface implementation
- **Hiddify reference app** — `github.com/hiddify/hiddify-app` (main branch): MethodHandler.kt (Flutter ↔ sing-box bridge), build.gradle, SingboxTlsTricks Dart model
- **Hiddify sing-box fork** — `github.com/hiddify/hiddify-sing-box` v1.13.0.h5: `TLSTricksOptions`, `TLSFragmentOptions` — confirms fork-only features (granular fragment, mixed SNI, padding)
- **sing-box official docs** — `sing-box.sagernet.org/configuration/` and `docs/migration.md`: Config schema, breaking changes log 1.8→1.14

### Secondary (MEDIUM confidence)
- **Hiddify-core** — `github.com/hiddify/hiddify-core/v2/config/`: Go-side config builder with `patchOutboundTLSTricks()`, `patchOutboundFragment()` — confirms fork implementation details
- **SagerNet/sing-geoip and sing-geosite** — rule-set branch: Available `.srs` files for IR, CN, RU, private

### Existing Codebase (HIGH confidence)
- **Arma v1.0** — Direct code analysis of all affected files: `XrayConfigBuilder.dart` (543 lines), `XrayCoreManager.kt` (99 lines), `ArmaVpnService.kt` (~500 lines), `TrafficMonitor.kt` (55 lines), `VpnServiceConnection.kt` (105 lines), `VpnPlatformService.dart` (128 lines), `VpnSettings.dart`, `AntiCensorshipProvider.dart`

---
*Research completed: 2026-04-07*
*Ready for roadmap: yes*
