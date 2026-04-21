# Arma Proxy & VPN Client — Feature Roadmap

> What we have, what's been built, and what's planned.

## Product Vision

A **privacy-first proxy/VPN client for Android** that lets users in censored regions (Iran, China, Russia) connect to their own proxy servers with a single tap. Built on sing-box engine with Flutter. Competes with V2rayNG, Hiddify, Happ, and Nekobox by offering **clean UX + reliability**.

**Core value:** *"Import a server config and connect in one tap — it just works, every time, even in hostile network environments."*

---

## Completed Features

### v1.0 MVP (Shipped 2026-04-06 — Phases 1–4)

| Phase | Features |
|---|---|
| **Phase 1: Foundation** | Project architecture (Clean Architecture + MVVM), Material 3 theming (light/dark), localization (EN/FA/RU/ZH + RTL), share link parsing (VLESS/VMess/Trojan/SS/Hysteria2), Hive local persistence |
| **Phase 2: VPN Engine** | Xray-core AAR integration, Android VpnService (TUN mode), all core protocols + transports (TCP/WS/gRPC/H2), connect/disconnect flow, traffic monitoring, foreground notification with speed display, auto-reconnect on network change |
| **Phase 3: Server Management** | Subscription management (base64/SIP008/Clash YAML), QR code scanning + display, latency testing (individual + bulk), auto-select fastest server, multi-select bulk deletion, server sorting/filtering, log viewer + export |
| **Phase 4: Advanced Features** | Per-domain routing rules, region bypass presets (Iran/China/Russia), per-app split tunneling, custom DNS (DoH/DoT/Plain), Hysteria2 protocol, TLS tricks (fragment/padding/mixed SNI), mux/sniffing toggles |

### v1.1 sing-box Migration (Shipped 2026-04-09 — Phases 5–7)

| Phase | Features |
|---|---|
| **Phase 5: sing-box Integration** | sing-box library integration, config builder rewrite for all protocols/transports/TLS/ECH, geo assets in `.srs` format |
| **Phase 6: Platform Interface** | CommandServer/PlatformInterface implementation, inverted TUN control, real-time stats via CommandClient, per-outbound traffic stats, latency testing via URLTest |
| **Phase 7: Feature Parity** | Full feature parity under sing-box, FakeIP DNS mode, rule-set auto-update, TLS fragment/mux with padding, per-app via TUN filtering, dual-engine rollback toggle (sing-box ↔ Xray) |

### v1.2 Server List UX (Shipped 2026-04-11 — Phases 8–10)

| Phase | Features |
|---|---|
| **Phase 8: Data Foundation** | Entity extensions (description, supportUrl), description parser from subscription body, flag emoji extraction, empty-state clipboard import (auto-detects share links/subscription URLs/base64) |
| **Phase 9: Subscription Groups** | Collapsible subscription group headers with persistent state, 3-dot menu (refresh/delete all/copy URL), data usage progress bar, expiry countdown (red when <3 days), tappable support-url icon, announcement banners |
| **Phase 10: Server Cards** | Compact Happ-style server cards with flag emoji icons, description subtitles, protocol badge pills, swipe-to-delete with undo snackbar |

---

## Current Functionality Summary

### Protocols Supported

| Protocol | Transports | TLS | Notes |
|---|---|---|---|
| VLESS | TCP, WS, gRPC, H2 | TLS, Reality, XTLS | Flow: `xtls-rprx-vision` auto-default |
| VMess | TCP, WS, gRPC, H2 | TLS | Legacy base64-JSON + standard URI |
| Trojan | TCP, WS, gRPC | TLS | Password-based auth |
| Shadowsocks | TCP | — | SIP002 format, multiple ciphers |
| Hysteria2 | QUIC | TLS | Bandwidth control, obfuscation |
| SOCKS5 / HTTP | TCP | Optional | Basic proxy protocols |

### Import Methods

| Method | Description |
|---|---|
| **Share Link** | Paste `vless://`, `vmess://`, `trojan://`, `ss://`, `hy2://` URIs |
| **QR Code** | Scan via camera (auto-detects share links and subscription URLs) |
| **Subscription URL** | Add URL → auto-detects format (SIP008/Clash YAML/base64/plain text) |
| **Clipboard** | Auto-detect clipboard content: share links, subscription URLs, base64 |
| **Paste Config** | Full-screen multiline text field for bulk import |

### VPN Features

| Feature | Description |
|---|---|
| **One-tap connect** | Select server → tap power button → connected |
| **Auto-reconnect** | Re-establishes on network change (WiFi ↔ mobile) |
| **Auto-fallback** | On error, tries next-best server (up to 3 attempts) |
| **Traffic stats** | Real-time ↓/↑ speed + cumulative totals + connection counts |
| **Per-outbound stats** | See traffic broken down by proxy/direct/block |
| **Foreground notification** | Persistent notification with speed display |
| **State timeout** | 30s connecting, 10s disconnecting — auto-recovers |

### Server Management

| Feature | Description |
|---|---|
| **Subscription groups** | Collapsible headers with data usage, expiry, announcements |
| **Auto-refresh subscriptions** | Background refresh on app launch |
| **Latency testing** | Individual tap or bulk "Test All" |
| **Best server selection** | Auto-selects lowest-latency server |
| **Sorting** | By name, latency, or protocol |
| **Filtering** | All / Working / Failed |
| **Multi-select** | Long-press → select multiple → bulk delete |
| **Swipe-to-delete** | Swipe left with undo snackbar |
| **Duplicate detection** | Prevents importing identical servers |
| **Share** | Generate share link / QR code per server |

### Routing

| Feature | Description |
|---|---|
| **Region bypass** | Iran/China/Russia — bundled `.srs` geo rule-sets |
| **LAN bypass** | Private IP ranges bypass VPN |
| **Custom domain rules** | Per-domain: proxy / direct / block |
| **Per-app proxy** | Whitelist or blacklist mode (from installed app list) |

### DNS

| Feature | Description |
|---|---|
| **Protocol** | DoH (HTTPS) / DoT / Plain UDP |
| **Server presets** | Cloudflare, Google, Quad9, AdGuard, Electro, Custom |
| **Split DNS** | Remote DNS through proxy, local DNS for direct |
| **FakeIP** | Optional FakeIP DNS mode with configurable CIDR |
| **DNS sniffing** | Inspect traffic to determine domain for routing |

### Anti-Censorship

| Feature | Description |
|---|---|
| **Profiles** | None / Light / Moderate / Aggressive (presets) |
| **TLS Fragment** | Split TLS ClientHello (configurable size + sleep ranges) |
| **TLS Padding** | Add padding to TLS records |
| **Mixed SNI** | Randomize SNI in handshake |
| **Mux** | Multiplex connections (1-8 concurrency) |

### Settings

| Feature | Description |
|---|---|
| **Theme** | System / Light / Dark |
| **Language** | English / Farsi (RTL) / Russian / Chinese |
| **Engine toggle** | sing-box ↔ Xray-core fallback |
| **Log viewer** | Real-time, filterable, searchable, exportable |
| **Clear data** | Clear cached data with confirmation |

---

## Planned / Future Features

> No active milestone defined. The following features are explicitly deferred.

### Platform Expansion

| Feature | Priority | Notes |
|---|---|---|
| **iOS build** | High | Flutter cross-platform ready; needs Network Extension + NEPacketTunnelProvider |
| **macOS build** | Medium | Desktop VPN service integration |
| **Windows build** | Medium | WinTun driver integration |
| **Linux build** | Low | TUN device management |
| **Android TV** | Low | D-pad navigation, leanback UI |

### Product Features

| Feature | Priority | Notes |
|---|---|---|
| **Bundled free/trial servers** | Medium | First-time UX improvement; needs backend |
| **User accounts / authentication** | Medium | Currently all config is local |
| **In-app purchases / monetization** | Low | Not in v1 |
| **Server speed test (download)** | Medium | Beyond latency — actual throughput test |
| **WireGuard protocol** | Medium | Popular protocol, sing-box supports it |
| **TUIC protocol** | Low | Newer QUIC-based protocol |
| **Config editing UI** | Medium | Currently import-only; full server config editor |
| **Drag-to-reorder servers** | Deferred | Conflicts with swipe-to-delete gesture |
| **Country flag images** | Deferred | Using emoji instead (lighter, no asset loading) |
| **Animated progress transitions** | Deferred | Jank risk on lower-end devices |
| **Subscription URL editing** | Deferred | Dangerous; copy URL only |

### Web Platform (from happ_clone_specs.md)

| Feature | Description |
|---|---|
| **Documentation site** | GitBook-style with sidebar navigation |
| **Download grid** | iOS, Android (Play Store + APK), Windows, macOS, Linux, TV |
| **Donation page** | Crypto + card payment badges |
| **Multi-language** | EN / RU site variants |
| **Legal pages** | Privacy Policy, Terms of Service, FAQ |
| **Developer docs** | API documentation, contribution guide |

---

## Project Stats

| Metric | Value |
|---|---|
| **Total Dart LOC** | ~18,400 |
| **Completed phases** | 10 (across 3 milestones) |
| **Test files** | 21 |
| **Passing tests** | 241+ |
| **Protocols** | 6 (VLESS, VMess, Trojan, SS, Hysteria2, SOCKS/HTTP) |
| **Subscription formats** | 4 (SIP008, Clash YAML, base64, plain text) |
| **Languages** | 4 (EN, FA, RU, ZH) |
| **Hive models** | 3 (ServerConfig, Subscription, DomainRule) |
| **Riverpod providers** | 20+ |
| **Platform channels** | 2 (MethodChannel + EventChannel) |
| **Native Kotlin files** | 10 |
