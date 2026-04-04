# Feature Landscape

**Domain:** Xray-based proxy/VPN client for Android (censorship circumvention)
**Researched:** 2025-07-13
**Reference Apps Analyzed:** V2rayNG (53K★), Hiddify (28K★, Flutter), ClashMeta (36K★), Nekobox (19K★), Shadowrocket (iOS), Happ (target clone)
**Confidence:** HIGH — based on direct source code analysis of Hiddify (Flutter) and V2rayNG/Nekobox READMEs

---

## Table Stakes

Features users expect from any Xray/V2ray client. Missing any of these = users go back to V2rayNG immediately. These are non-negotiable because the target audience already uses competing apps daily.

| # | Feature | Why Expected | Complexity | Notes |
|---|---------|--------------|------------|-------|
| T1 | **One-tap connect/disconnect** | Every competitor has this. Users open app, tap button, they're connected. Period. | Medium | Requires full VpnService + Xray-core pipeline working. The button is simple; the plumbing is the hard part. |
| T2 | **VLESS protocol (incl. Reality + XTLS)** | The dominant anti-censorship protocol in 2024-2025. Reality is the gold standard for defeating DPI in Iran/China/Russia. Without it, the app is useless to 60%+ of the target audience. | High | Reality requires proper TLS fingerprint handling. XTLS-Vision flow must work. This is the most critical protocol. |
| T3 | **VMess protocol** | Legacy V2ray protocol still widely used. Many existing configs are VMess. | Medium | Simpler than VLESS but still needs proper AES-128-GCM/ChaCha20 support. |
| T4 | **Trojan protocol** | Third most popular protocol after VLESS and VMess. Many providers offer Trojan configs. | Medium | TLS-based, relatively straightforward via Xray-core. |
| T5 | **Shadowsocks protocol** | Original censorship circumvention protocol. Still used, especially as fallback. | Low | Well-supported in Xray-core. Basic parsing needed. |
| T6 | **Hysteria2 protocol** | UDP-based QUIC protocol for high-speed connections. Increasingly popular because it's faster than TCP-based protocols and harder to throttle. | Medium | Requires Xray-core version with Hysteria2 support or separate binary. |
| T7 | **Share link parsing (vless://, vmess://, trojan://, ss://)** | Users receive configs as share links via Telegram/Signal. If you can't parse `vless://xxx@server:443?...`, the app is useless. This is THE primary config import method. | Medium | Each protocol has its own URI format. VMess uses base64-encoded JSON. VLESS/Trojan use standard URI format with query params. Must handle edge cases (missing fields, non-standard encodings). |
| T8 | **Subscription URL import + parsing** | Users subscribe to VPN providers who deliver configs via base64-encoded URLs. Subscription URLs contain multiple server configs. Auto-update is expected. | Medium | Parse base64 response → split by newline → parse each share link. Must handle HTTP headers (User-Agent, subscription-userinfo). |
| T9 | **QR code scanning** | Second most common config import method. Users share QR codes in person or via screenshots. | Low | Use `mobile_scanner` package. Parse QR content as share link. |
| T10 | **Clipboard import** | Users copy share links from Telegram/browsers. Tap "import from clipboard" is expected. | Low | Read clipboard → detect share link format → parse. |
| T11 | **Server list with latency display** | Users need to see all their servers, which protocol each uses, and how fast each is. | Medium | List UI with protocol badges (VLESS/VMess/Trojan), latency in ms, country flags optional. |
| T12 | **Latency testing (ping/TCPing)** | Users test servers to find which ones work and which are fastest. "Test all" is expected. | Medium | HTTP ping to `gstatic.com/generate_204` or TCPing to server:port. Must run concurrently for bulk testing. Display results inline. |
| T13 | **Real-time traffic stats (upload/download speed)** | Users need to verify the proxy is working and monitor speeds. All competitors show this on the dashboard. | Medium | Read bytes sent/received from Xray-core via platform channel. Calculate speed (bytes/sec). Update UI every 1-2 seconds. |
| T14 | **Light/Dark theme** | Standard UX expectation. Most users in target regions prefer dark mode (AMOLED screens, night usage). | Low | Flutter ThemeData with light/dark variants. Follow Material 3 guidelines. |
| T15 | **Connection state feedback** | Users must see: Disconnected → Connecting... → Connected (with duration timer). Visual clarity on connection status prevents panic-disconnects. | Low | State machine: idle → connecting → connected → disconnecting. Show in UI with colors (red/yellow/green). |
| T16 | **VpnService integration (TUN mode)** | Android requires VpnService to capture all device traffic. Without this, only apps that support SOCKS/HTTP proxy work — which is almost none. | High | Kotlin-side VpnService implementation. tun2socks to route TUN traffic to Xray-core SOCKS inbound. This is the core of the Android integration. |
| T17 | **Xray-core JSON config generation** | Must translate user-facing config (protocol, server, port, UUID, etc.) into valid Xray JSON config with inbounds, outbounds, routing, dns sections. | High | The bridge between UI and engine. Must handle all protocol variants, transport types (ws, grpc, tcp, h2), TLS settings, Reality settings. |
| T18 | **Basic routing: Bypass LAN** | Traffic to local network (192.168.x.x, 10.x.x.x) must NOT go through proxy. Every competitor does this by default. | Low | Add geoip:private to direct outbound in Xray routing config. |
| T19 | **DNS configuration** | Custom DNS (e.g., 8.8.8.8, 1.1.1.1) because local ISP DNS is poisoned in censored regions. Users can't resolve blocked domains without clean DNS. | Medium | Configure Xray DNS module with remote DNS (DoH/DoT) for proxied domains and direct DNS for local domains. |
| T20 | **Config persistence (local storage)** | Configs must survive app restarts. Users add servers once and expect them to be there forever. | Low | Hive/Isar local storage. Store parsed config objects. |

---

## Differentiators

Features that set Arma apart from V2rayNG (ugly but functional) and compete with Hiddify (polished but complex). Not all users expect these, but they create loyalty and word-of-mouth.

| # | Feature | Value Proposition | Complexity | Notes |
|---|---------|-------------------|------------|-------|
| D1 | **Clean, modern UI (Happ-quality design)** | V2rayNG looks like a developer tool from 2018. Hiddify is clean but busy. Arma should look like a premium app that non-technical users feel comfortable using. This is the #1 differentiator in the spec. | Medium | Custom design system, animations on connect/disconnect, thoughtful spacing, satisfying button interactions. Not just Material defaults. |
| D2 | **Subscription info display (data remaining, days left, expiry)** | Hiddify shows this; V2rayNG does not. Users with paid subscriptions need to know how much data they've used and when it expires. This prevents surprise disconnections. | Low | Parse `subscription-userinfo` header from subscription response: `upload=X; download=Y; total=Z; expire=T`. Display as progress bar. |
| D3 | **Per-app proxy (split tunneling)** | Choose which apps go through proxy and which don't. Banking apps should be direct (they flag VPN users). Games may need direct for latency. Telegram needs proxy. | High | Android VpnService `Builder.addAllowedApplication()` or `addDisallowedApplication()`. Need to list all installed apps with icons. |
| D4 | **TLS tricks: Fragment, Padding, Mixed SNI case** | Critical anti-DPI technique for Iran specifically. Fragment splits TLS ClientHello into small packets to bypass DPI. Padding adds noise. Mixed SNI case (e.g., `GoOgLe.CoM`) defeats simple string matching. These can make the difference between "works" and "blocked". | Medium | Xray-core fragment settings in outbound. Hiddify implements this extensively (seen in their `SingboxTlsTricks` model). Config: fragment size range, sleep range, padding size, mixed case toggle. |
| D5 | **Auto-select best server (URL test)** | Automatically pick the fastest/working server from subscription. User doesn't need to manually test and select. Just connect and the app picks the best one. Hiddify and Clash both have this. | Medium | Periodically test all servers, select one with lowest delay. Strategies: round-robin, lowest-latency, consistent-hash. |
| D6 | **Encrypted/hidden subscription format** | Some subscription providers encrypt configs to prevent detection. Support for non-standard formats beyond plain base64. | Medium | Need to handle various encoding schemes. Provider-specific but becoming more common. |
| D7 | **Custom User-Agent for subscription fetch** | Subscription providers sometimes check User-Agent to serve different configs or block non-app requests. Users need to customize this. | Low | Simple text field in subscription settings. Default to app-specific UA. |
| D8 | **Bulk operations (multi-select, bulk delete, bulk test)** | Power users have 50+ servers. Managing them one-by-one is painful. Long-press to multi-select, then delete/test selected. | Low | Standard list multi-select pattern. Already in spec. |
| D9 | **Mux (Multiplexing) support** | Multiplex multiple connections over a single proxy connection. Can improve performance and reduce detection. | Low | Xray-core mux config toggle. Configurable max streams. |
| D10 | **Sniffing toggle** | Traffic sniffing to detect actual destination (override DNS-based routing). Prevents DNS leaks and enables protocol-based routing. | Low | Xray-core sniffing config. Toggle in settings. |
| D11 | **Config sharing/export** | Share a config with friends via share link or QR code. Critical for word-of-mouth growth — users share working configs via Telegram. | Low | Generate share link from stored config → share intent or render QR code. |
| D12 | **Log viewer + export** | When things don't work, users need to see why. Technical users check logs. Support channels ask for logs. | Medium | Capture Xray-core logs via platform channel. Display in scrollable view. Export as text file. |
| D13 | **Connection timer** | Show how long the current session has been active. Simple but gives confidence the connection is alive. | Low | Start timer on connect, show in dashboard. |
| D14 | **Notification with traffic stats** | Persistent Android notification showing connection status and current speed. Users can see proxy status without opening the app. | Low | Required by VpnService anyway (foreground service notification). Enhance with speed stats. |
| D15 | **Server sorting and grouping** | Sort by latency, name, protocol. Group by subscription source. Filter by working/failed. | Low | UI-only feature. Sort/filter functions on server list. |
| D16 | **App language selection** | Target users span Persian, Russian, Chinese, English. Multi-language support is expected in this specific market. | Medium | Flutter intl/l10n. Need at minimum: English, Persian (RTL!), Russian, Chinese simplified. RTL support for Persian is extra complexity. |
| D17 | **Auto-reconnect on network change** | When switching from WiFi to cellular or vice versa, the VPN drops. Auto-reconnect without user intervention. | Medium | Listen for connectivity changes. Re-establish VpnService connection. Handle Android Doze mode. |
| D18 | **Region-specific bypass rules (e.g., bypass Iran/China domestic)** | Don't proxy traffic to local sites. Iranian users don't need to proxy Iranian sites. Chinese users don't need to proxy Chinese sites. Saves bandwidth and improves speed. | Medium | Use geoip/geosite DAT files for country-specific routing. Presets for common regions. Hiddify calls this "region" config. |

---

## Stretch / Future Differentiators

Features that would be exceptional but can wait for v2+.

| # | Feature | Value Proposition | Complexity | Notes |
|---|---------|-------------------|------------|-------|
| S1 | **WARP integration (Cloudflare Warp)** | Free fallback connection method. Hiddify integrates WARP as a WireGuard tunnel that chains with the main proxy. Useful when all other protocols are blocked. | High | Requires WARP account registration API, WireGuard config generation. Hiddify has this (seen in source: `warp_account.dart`, `SingboxWarpOption`). |
| S2 | **Clash/Sing-box config import** | Some users have Clash YAML configs or sing-box JSON configs. Supporting these formats expands the user base. | High | Need YAML parser and config translator. Different config schema from Xray. |
| S3 | **Proxy chain (double proxy)** | Route through two proxies for extra anonymity or to bypass double-layer censorship. | High | Xray-core supports chained outbounds. UI complexity to configure. |
| S4 | **Widget (Android home screen)** | Quick connect/disconnect from home screen without opening app. | Medium | Android AppWidget with connection toggle. |
| S5 | **Speed test (dedicated)** | Test actual download speed through the proxy, not just latency. | Medium | Download a test file through proxy and measure throughput. |
| S6 | **Deep link support** | Handle `arma://import/...` or `vless://...` links from other apps to auto-import configs. | Medium | Android intent-filter for custom URI schemes. Already present in Hiddify (`deep_link` feature module). |
| S7 | **Auto-start on boot** | Start VPN connection automatically when device boots. Critical for always-on privacy users. | Medium | Android BroadcastReceiver for BOOT_COMPLETED. Re-establish last connection. Hiddify has this (`auto_start` feature module). |
| S8 | **iCloud/backup-style config sync** | Sync configs across devices or backup to cloud. | High | Requires backend or cloud storage integration. Goes against "no backend" constraint for v1. |
| S9 | **Geo-aware rule sets (downloadable)** | Download community-maintained rule sets (like Loyalsoldier/v2ray-rules-dat) for smarter routing. | Medium | Download geoip.dat and geosite.dat files. V2rayNG documents this prominently. |

---

## Anti-Features

Features to explicitly NOT build. Each would waste time, add risk, or actively harm the product.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Bundled free/trial servers** | Legal liability. Server maintenance burden. Free servers get abused and blocked quickly, making app look broken. Every free VPN app is suspected of data harvesting. | Strictly a client. Link to documentation on how to get configs from providers or self-host. |
| **Built-in server provisioning** | Scope creep. Turns a client app into a SaaS platform. Competing with Hiddify Manager, Outline, etc. | Stay in the client lane. Let server panels be server panels. |
| **User accounts / authentication** | Requires backend infrastructure. No backend = no data breach risk. Users in censored regions are (rightfully) suspicious of apps that want their identity. | All data local. No sign-up. No tracking. |
| **Analytics / telemetry** | Privacy-first positioning. Any analytics in a circumvention tool destroys trust instantly. One leak = reputational death. | Zero analytics. Not even crash reporting to third parties. Local crash logs only. |
| **In-app ads** | Users are literally trying to bypass censorship. Showing them ads is tone-deaf and insulting. Competitors are all ad-free. | Donations page (crypto + card). Open-source goodwill. |
| **Complex manual config editor (full JSON)** | 95% of users will never edit raw JSON. Building a full JSON editor is huge effort for tiny audience. V2rayNG has this and nobody uses it except developers. | Parse share links and subscription URLs. For edge cases, accept raw JSON paste (not a visual editor). |
| **iOS/Desktop builds in v1** | Android is the overwhelming platform in target regions (Iran ~85% Android, Russia ~75%). Flutter enables cross-platform later, but shipping Android first means faster time-to-users. | Architecture for cross-platform (Clean Arch + platform channels abstraction), but build/test Android only in v1. |
| **TV platform** | Tiny user base. Different UI paradigm (D-pad navigation). Not worth the effort for v1. | Defer to v2+. Android TV uses same APK base if architecture is right. |
| **Protocol implementation from scratch** | Reimplementing VLESS/VMess/Trojan in Dart would be insane. Xray-core exists, is battle-tested, and handles everything. | Compile Xray-core via Go-Mobile. Use it as a black box via platform channels. |
| **VPN kill switch (v1)** | Technically complex to implement correctly on Android. If done wrong, it either leaks traffic or bricks internet access. Better to ship without it than ship it broken. | Add in v2 after core stability is proven. Document the limitation. |
| **Traffic interception / MITM** | Shadowrocket does this for debugging. It's a security and legal minefield. Not appropriate for a privacy-first app. | Proxy traffic, don't inspect it. |

---

## Feature Dependencies

```
T16 (VpnService) ──────────────────┐
T17 (Xray JSON config gen) ────────┤
T2-T6 (Protocol support) ─────────┤
                                   ├──► T1 (One-tap connect) ──► T13 (Connection timer)
T18 (Bypass LAN) ─────────────────┤                          ──► T15 (Connection state)
T19 (DNS config) ─────────────────┘                          ──► D14 (Notification)
                                                              ──► D17 (Auto-reconnect)

T7 (Share link parsing) ──────────► T10 (Clipboard import)
                                  ──► T9 (QR code scan)
                                  ──► T8 (Subscription import) ──► D2 (Sub info display)
                                                                ──► D6 (Encrypted subs)
                                                                ──► D7 (Custom UA)

T20 (Config persistence) ─────────► T11 (Server list) ──► T12 (Latency testing)
                                                        ──► D8 (Bulk operations)
                                                        ──► D15 (Sort/group)
                                                        ──► D5 (Auto-select best)
                                                        ──► D11 (Config sharing)

T14 (Theme) ──────────────────────► D1 (Clean UI)
                                  ──► D16 (Language selection)

T1 (One-tap connect) ─────────────► T13 (Traffic stats)
                                  ──► D12 (Log viewer)

D3 (Per-app proxy) requires T16 (VpnService)
D4 (TLS tricks) requires T17 (Xray JSON config gen)
D18 (Region bypass) requires T18 (Bypass LAN) + geoip/geosite
```

---

## MVP Recommendation

### Phase 1: Core (must ship first — the app is useless without these)

1. **T16** VpnService integration — the foundation
2. **T17** Xray-core JSON config generation — the bridge
3. **T2** VLESS (incl. Reality/XTLS) — the #1 protocol
4. **T3** VMess — legacy support
5. **T4** Trojan — third pillar
6. **T5** Shadowsocks — basic coverage
7. **T7** Share link parsing — primary import method
8. **T1** One-tap connect/disconnect — the UX
9. **T15** Connection state feedback — basic UX
10. **T20** Config persistence — data survives restart
11. **T18** Bypass LAN — basic routing
12. **T19** DNS configuration — essential for censored regions

### Phase 2: Usable (users can live with the app daily)

1. **T8** Subscription URL import
2. **T9** QR code scanning
3. **T10** Clipboard import
4. **T11** Server list with latency display
5. **T12** Latency testing
6. **T13** Real-time traffic stats
7. **T14** Light/Dark theme
8. **D14** Notification with status

### Phase 3: Competitive (catches up to V2rayNG feature parity)

1. **T6** Hysteria2 protocol
2. **D1** Clean, polished UI (Happ-quality)
3. **D4** TLS tricks (fragment, padding, mixed SNI)
4. **D8** Bulk operations
5. **D11** Config sharing/export
6. **D12** Log viewer + export
7. **D2** Subscription info display
8. **D15** Server sorting/grouping

### Phase 4: Differentiation (surpasses V2rayNG, competes with Hiddify)

1. **D3** Per-app proxy
2. **D5** Auto-select best server
3. **D16** Multi-language (EN, FA, RU, ZH)
4. **D17** Auto-reconnect on network change
5. **D18** Region-specific bypass rules
6. **D13** Connection timer

### Defer to v2+

- **S1** WARP integration
- **S2** Clash/Sing-box config import
- **S6** Deep link support
- **S7** Auto-start on boot
- **S9** Downloadable geo rule sets

**Rationale for ordering:**
- Phase 1 is pure engine + minimal config import. Without this, nothing works.
- Phase 2 adds the daily-use features that make it practical (subscriptions, QR, testing).
- Phase 3 adds the polish and advanced anti-censorship features that make it competitive.
- Phase 4 adds the power features that make users switch from V2rayNG permanently.
- TLS tricks (D4) are in Phase 3, not Phase 4, because in Iran specifically they're nearly table-stakes — without fragment/padding, many connections fail.

---

## Competitive Feature Matrix

| Feature | V2rayNG | Hiddify | Nekobox | Arma (planned) |
|---------|---------|---------|---------|----------------|
| VLESS+Reality | ✅ | ✅ | ✅ | ✅ Phase 1 |
| VMess | ✅ | ✅ | ✅ | ✅ Phase 1 |
| Trojan | ✅ | ✅ | ✅ | ✅ Phase 1 |
| Shadowsocks | ✅ | ✅ | ✅ | ✅ Phase 1 |
| Hysteria2 | ✅ | ✅ | ✅ | ✅ Phase 3 |
| TUIC | ❌ | ✅ | ✅ | ❌ (v2+) |
| WireGuard | ❌ | ✅ | ✅ | ❌ (v2+) |
| SSH | ❌ | ✅ | ✅ | ❌ (v2+) |
| Subscription import | ✅ | ✅ | ✅ | ✅ Phase 2 |
| QR scan | ✅ | ✅ | ✅ | ✅ Phase 2 |
| Per-app proxy | ✅ | ✅ | ✅ | ✅ Phase 4 |
| TLS fragment/tricks | ✅ | ✅ | ❌ | ✅ Phase 3 |
| Auto best server | ❌ | ✅ | ✅ | ✅ Phase 4 |
| WARP integration | ❌ | ✅ | ❌ | ❌ (v2+) |
| Clash config import | ❌ | ✅ | ✅ | ❌ (v2+) |
| Clean modern UI | ❌ | ✅ | ❌ | ✅ Phase 3 |
| Multi-platform | Android | All | Android | Android (v1) |
| Open source | ✅ | ✅ | ✅ | TBD |
| Sub info (data/expiry) | ❌ | ✅ | ❌ | ✅ Phase 3 |
| Ad blocking | ❌ | ✅ | ❌ | ❌ (v2+) |
| Region presets | ✅ (geoip) | ✅ | ✅ | ✅ Phase 4 |

---

## Key Insight: What Users in Censored Regions Actually Need

Based on the ecosystem analysis, users in Iran/China/Russia have specific needs that differ from generic VPN users:

1. **Connection reliability over speed.** They don't care if it's 50 Mbps or 100 Mbps. They care that it *connects at all* when the government is actively blocking protocols. This means TLS tricks, Reality support, and protocol diversity matter more than raw performance.

2. **Easy config distribution.** Configs are shared via Telegram groups, not app stores. Share link parsing and QR codes are the lifeline. Subscription URLs from providers are how most users get their servers.

3. **Minimal digital footprint.** No accounts, no analytics, no cloud sync. The app should leave minimal traces. Users in these regions face real consequences if their circumvention tools are discovered.

4. **Domestic traffic bypass.** Users don't want to route local banking, government services, or domestic e-commerce through a proxy. It's slower, triggers security flags, and wastes bandwidth. Region-aware routing is not optional — it's expected.

5. **Resilience to DPI (Deep Packet Inspection).** The cat-and-mouse game between censors and tools is constant. Features like TLS fragment, padding, and Reality exist specifically to defeat DPI. An app without these is blocked within weeks in Iran.

---

## Sources

- Hiddify source code analysis (GitHub: `hiddify/hiddify-app`) — Flutter app, direct code review of models, features, and config options [HIGH confidence]
- V2rayNG repository (GitHub: `2dust/v2rayNG`, 53K★) — README, project structure, geoip/geosite documentation [HIGH confidence]
- Nekobox repository (GitHub: `MatsuriDayo/NekoBoxForAndroid`, 19K★) — README, supported protocols, plugin system [HIGH confidence]
- ClashMeta for Android (GitHub: `MetaCubeX/ClashMetaForAndroid`, 36K★) — project description [MEDIUM confidence]
- Shadowrocket — iOS App Store listing and community knowledge [MEDIUM confidence, no source code access]
- Happ (target clone) — spec document `happ_clone_specs.md` in repository [HIGH confidence]
- Project constraints from `.planning/PROJECT.md` [HIGH confidence]
