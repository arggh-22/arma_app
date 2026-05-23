# Roadmap: Arma Proxy & VPN Client

## Milestones

- ✅ **v1.0 MVP** — Phases 1–4 (shipped 2026-04-06)
- 🚧 **v1.1 sing-box Engine Migration** — Phases 5–7 (in progress)
- 📋 **v1.2 Default VPN Servers Integration** — Phases 8–10 (planning)

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3…): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

<details>
<summary>✅ v1.0 MVP (Phases 1–4) — SHIPPED 2026-04-06</summary>

- [x] **Phase 1: Foundation & Config Import** — Project architecture, UI shells, theming, localization, share link parsing, and local config persistence
- [x] **Phase 2: VPN Engine & Core Connection** — Xray-core AAR integration, VpnService, all core protocols, connect/disconnect, traffic monitoring, basic routing & DNS
- [x] **Phase 3: Subscriptions & Server Intelligence** — Subscription management, QR scanning, latency testing, bulk operations, server sorting/filtering, log viewer
- [x] **Phase 4: Routing, DNS & Advanced Settings** — Per-domain/per-app routing, custom DNS, region presets, Hysteria2, TLS tricks, Xray engine toggles

### Phase 1: Foundation & Config Import
**Goal**: Users can import server configurations via share links, clipboard, or JSON paste and manage them in a polished, themed, localized UI
**Depends on**: Nothing (first phase)
**Requirements**: STOR-01, STOR-02, UI-01, UI-03, UI-07, CONF-01, CONF-03, CONF-05, CONF-06, SERV-01, SERV-02
**Success Criteria** (what must be TRUE):
  1. User can open the app and navigate between Dashboard, Server List, and Settings screens with a clean Material 3 design
  2. User can paste a share link (vless://, vmess://, trojan://, ss://, hysteria2://) or raw JSON config and see the parsed server appear in the server list with correct protocol badge
  3. User can import a config from clipboard with one tap via the expandable FAB on the config screen
  4. User can select a server as active, switch between light/dark themes, and change language — all preferences and configs persist across app restarts
  5. App displays correctly in RTL layout when Persian language is selected
**Plans:** 5 plans

Plans:
- [x] 01-01-PLAN.md — Project foundation: dependencies, theme, router, navigation shell
- [x] 01-02-PLAN.md — Domain models, data layer, localization (4 languages + RTL)
- [x] 01-03-PLAN.md — Share link parsers (TDD): all 5 protocols with unit tests
- [x] 01-04-PLAN.md — Dashboard, settings, and routing screens
- [x] 01-05-PLAN.md — Server list UI and import flow (FAB, clipboard, paste dialog)

### Phase 2: VPN Engine & Core Connection
**Goal**: Users can connect to their proxy servers with a single tap and monitor the live connection
**Depends on**: Phase 1
**Requirements**: ENG-01, ENG-02, ENG-03, ENG-04, ENG-05, PROTO-01, PROTO-02, PROTO-03, PROTO-04, PROTO-06, UI-02, MON-01, MON-02, MON-03, MON-04, ROUTE-01, ROUTE-06
**Success Criteria** (what must be TRUE):
  1. User can tap the connect button on the dashboard and establish a VPN connection through their selected server via Android VpnService (TUN mode)
  2. User sees clear connection state transitions (Disconnected → Connecting → Connected with color coding) and a live connection duration timer
  3. User can connect using VLESS (including Reality/XTLS-Vision), VMess, Trojan, or Shadowsocks over TCP, WebSocket, gRPC, or HTTP/2 transports
  4. Dashboard shows real-time upload/download speeds, and the persistent foreground notification displays connection status and current traffic speeds
  5. VPN auto-reconnects on network changes (WiFi ↔ cellular), bypasses LAN traffic by default, and uses split DNS (remote for proxied domains, direct for local) to prevent leaks
**Plans:** 5 plans

Plans:
- [x] 02-01-PLAN.md — Native setup: AAR integration, Gradle config, AndroidManifest permissions, geo assets
- [x] 02-02-PLAN.md — Xray JSON config builder (TDD): all 4 protocols × 4 transports + split DNS + LAN bypass
- [x] 02-03-PLAN.md — VPN Service implementation: XrayCoreManager, notification, traffic monitor, ArmaVpnService
- [x] 02-04-PLAN.md — IPC bridge + connection layer: ServiceConnection, MainActivity channels, Dart providers
- [x] 02-05-PLAN.md — Dashboard UI: animated connect button, connection timer, traffic stats cards

### Phase 3: Subscriptions & Server Intelligence
**Goal**: Users can manage subscriptions, scan QR codes, test server quality, and efficiently organize large server collections
**Depends on**: Phase 2
**Requirements**: CONF-02, CONF-04, CONF-07, CONF-08, CONF-09, CONF-10, SERV-03, SERV-04, SERV-05, SERV-06, SERV-07, SERV-08, SERV-09, MON-05, MON-06
**Success Criteria** (what must be TRUE):
  1. User can add subscription URLs (including encrypted formats) with configurable auto-update, custom User-Agent, and see subscription info (data used, remaining, expiry date)
  2. User can scan a QR code to import a config and can export/share any config as a share link or QR code
  3. User can test latency for individual or all servers in bulk, see results inline, and enable auto-select to connect to the fastest server
  4. User can long-press to multi-select servers for bulk deletion, sort servers by latency/name/protocol, and filter by working/failed status
  5. User can view Xray-core logs in a scrollable viewer and export them as a text file for debugging
**Plans:** 6 plans

Plans:
- [x] 03-01-PLAN.md — Subscription data model, dependencies, l10n keys (all 4 locales)
- [x] 03-02-PLAN.md — Subscription parsers (base64/SIP008/Clash) + share link generator (TDD)
- [x] 03-03-PLAN.md — Latency testing: native MeasureDelay bridge + Dart providers + auto-fallback
- [x] 03-04-PLAN.md — Log viewer + export (ring buffer, monospace viewer, share)
- [x] 03-05-PLAN.md — Subscription service + QR scanner + config export + auto-refresh
- [x] 03-06-PLAN.md — Server list UI: sort, filter, multi-select, subscription headers, full wiring

### Phase 4: Routing, DNS & Advanced Settings
**Goal**: Users can fine-tune routing, DNS, and anti-censorship settings for hostile network environments
**Depends on**: Phase 3
**Requirements**: PROTO-05, ROUTE-02, ROUTE-03, ROUTE-04, ROUTE-05, UI-04, UI-05, UI-06
**Success Criteria** (what must be TRUE):
  1. User can configure per-domain routing rules (Proxy, Direct, or Block) and select region-specific bypass presets (Iran, China, Russia domestic traffic)
  2. User can enable per-app proxy (split tunneling) to choose which installed apps route through the VPN
  3. User can configure custom DNS servers (DoH/DoT) and connect via Hysteria2 protocol (UDP/QUIC)
  4. User can toggle Xray engine settings (sniffing, mux, fragment), configure TLS tricks (fragment size/sleep range, padding, mixed SNI case), and clear cached data from settings
**Plans:** 5 plans

Plans:
- [x] 04-01-PLAN.md — Data foundation: settings persistence, models, Hysteria2 fields, l10n keys
- [x] 04-02-PLAN.md — Xray config builder extension + connection wiring (DNS, routing, mux, fragment, Hysteria2)
- [x] 04-03-PLAN.md — Native Kotlin per-app proxy (MethodChannel + VPN service split tunneling)
- [x] 04-04-PLAN.md — Settings screen UI: DNS, Engine Settings, Anti-Censorship, Data sections
- [x] 04-05-PLAN.md — Routing screen UI: region presets, domain rules, per-app proxy

</details>

### 🚧 v1.1 sing-box Engine Migration (In Progress)

**Milestone Goal:** Replace Xray-core with sing-box as the proxy engine, maintaining all v1.0 functionality with a dual-engine rollback safety net. Enables future cross-platform support (iOS, macOS, Windows, Linux).

- [ ] **Phase 5: Engine Foundation & Config Builder** — sing-box library integration, geo asset swap, and complete config builder rewrite for all protocols/transports/TLS modes
- [ ] **Phase 6: VPN Service & Connection Monitoring** — CommandServer/PlatformInterface integration with inverted TUN control, real-time stats via CommandClient, and latency testing
- [ ] **Phase 7: Feature Parity & Dual-Engine Safety** — Routing/DNS/anti-censorship/per-app features verified under sing-box, plus dual-engine rollback toggle

## Phase Details

### Phase 5: Engine Foundation & Config Builder
**Goal**: App integrates sing-box library and can generate validated configs for all protocols, transports, and TLS modes
**Depends on**: Phase 4 (v1.0 complete — existing Xray engine as baseline)
**Requirements**: ENGINE-01, ENGINE-05, CONFIG-01, CONFIG-02, CONFIG-03, CONFIG-04, CONFIG-05, CONFIG-06, CONFIG-07, CONFIG-08
**Success Criteria** (what must be TRUE):
  1. App builds and launches with sing-box library (libbox.aar replacing libv2ray.aar), and sing-box version string is retrievable from native layer
  2. App generates sing-box JSON configs that pass `checkConfig()` validation for all 5 protocols: VLESS (including Reality + XTLS Vision), VMess, Trojan, Shadowsocks, and Hysteria2
  3. Generated configs correctly handle all transport types (TCP, WebSocket, gRPC, HTTP/2, HTTPUpgrade) and TLS modes including ECH (Encrypted Client Hello)
  4. Geo assets use sing-box rule-set format (.srs files) replacing v2fly .dat files, with bundled fallbacks for offline-first launch
**Plans**: 3 plans

Plans:
- [x] 08-01-PLAN.md — Define API/auth contracts and centralized config constants
- [x] 08-02-PLAN.md — Implement encrypted auth storage and persistent device ID service
- [x] 08-03-PLAN.md — Implement API client, auth repository lifecycle, and Riverpod provider wiring

### Phase 6: VPN Service & Connection Monitoring
**Goal**: Users can connect and disconnect through sing-box engine and see real-time connection stats, traffic speeds, and server latency
**Depends on**: Phase 5
**Requirements**: ENGINE-02, ENGINE-03, MONITOR-01, MONITOR-02, MONITOR-03, MONITOR-04, MONITOR-05
**Success Criteria** (what must be TRUE):
  1. User taps Connect and traffic flows through the sing-box proxy server, then taps Disconnect and the VPN service stops cleanly — no leaked connections or zombie processes
  2. Dashboard displays real-time upload/download speeds and connection status (Disconnected/Connecting/Connected) streamed via CommandClient subscription
  3. Dashboard displays active connection count and per-outbound traffic statistics while connected
  4. User can test individual server latency and run bulk latency tests from the server list with results displayed inline
**Plans**: TBD
**UI hint**: yes

### Phase 7: Feature Parity & Dual-Engine Safety
**Goal**: All v1.0 routing, DNS, anti-censorship, and per-app features work under sing-box, with a dual-engine rollback option for safe migration
**Depends on**: Phase 6
**Requirements**: ROUTE-01, ROUTE-02, ROUTE-03, ROUTE-04, ROUTE-05, ROUTE-06, ROUTE-07, CENSOR-01, CENSOR-02, CENSOR-03, PERAPP-01, ENGINE-04
**Success Criteria** (what must be TRUE):
  1. Region presets (Iran, China, Russia) route domestic traffic directly using sing-box rule-sets, LAN traffic is bypassed via `ip_is_private`, and rule-sets auto-update from remote sources with local cache
  2. DNS configuration uses sing-box typed servers (DoH/DoT/Plain), FakeIP mode is available as a user option, and protocol sniffing works via sing-box route rules
  3. Anti-censorship settings (TLS fragment, TLS record_fragment, mux with padding) are configurable in Settings and correctly applied to outbound connections
  4. Per-app proxy (split tunneling) works via sing-box TUN-level `include_package`/`exclude_package` filtering
  5. User can toggle between sing-box and Xray-core engines in Settings, enabling safe rollback if sing-box has issues in their network environment

**Plans**: TBD

## Progress

**Execution Order:**
v1.0: 1 → 2 → 3 → 4
v1.1: 5 → 6 → 7

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation & Config Import | v1.0 | 5/5 | ✅ Complete | 2026-04-04 |
| 2. VPN Engine & Core Connection | v1.0 | 5/5 | ✅ Complete | 2026-04-05 |
| 3. Subscriptions & Server Intelligence | v1.0 | 6/6 | ✅ Complete | 2026-04-05 |
| 4. Routing, DNS & Advanced Settings | v1.0 | 5/5 | ✅ Complete | 2026-04-06 |
| 5. Engine Foundation & Config Builder | v1.1 | 0/? | Not started | — |
| 6. VPN Service & Connection Monitoring | v1.1 | 0/? | Not started | — |
| 7. Feature Parity & Dual-Engine Safety | v1.1 | 0/? | Not started | — |
| 8. API Client & Device Authentication | v1.2 | 0/? | Not started | — |
| 9. Default Servers Home Screen Display | v1.2 | 0/? | Not started | — |
| 10. Settings & Auto-Update Configuration | v1.2 | 0/? | Not started | — |

---

## v1.2 Phases (Planning)

### Phase 8: API Client & Device Authentication
**Goal**: Build the API client library and implement device authentication flow.
**Depends on**: v1.1 completed
**Requirements**: API-01, SEC-01 (partial)
**Success Criteria** (what must be TRUE):
  1. User can authenticate their device with your VPN API on first app launch using HWID + device info
  2. API token is stored securely in Hive (encrypted) and automatically refreshed on expiry
  3. APIClient class provides methods for device auth and token management
  4. Auth errors are handled gracefully with retry logic
  5. Device HWID persists across app updates and reinstalls

**Plans**: TBD

### Phase 9: Default Servers Home Screen Display
**Goal**: Display default servers in home screen bottom half with UI controls.
**Depends on**: Phase 8
**Requirements**: API-02, API-03, UI-01, UI-02, REL-01
**Success Criteria** (what must be TRUE):
  1. Default servers from API appear in home screen bottom half (below connection stats)
  2. Manual refresh button fetches latest servers from API with loading state
  3. Servers are parsed correctly (name, status, traffic info) and displayed in a list
  4. Tapping a default server connects via existing VPN service (same as user-added servers)
  5. Cached servers display when offline or API is unreachable
  6. Network errors and timeouts show user-friendly error messages

**Plans**: TBD

### Phase 10: Settings & Auto-Update Configuration
**Goal**: Add user settings for auto-update and implement periodic refresh background task.
**Depends on**: Phase 9
**Requirements**: DATA-01, DATA-02, DATA-03, COMPAT-01, COMPAT-02
**Success Criteria** (what must be TRUE):
  1. "Default Servers Auto-Update" setting appears in Settings screen with options: Disabled, Every 12 Hours, Every 24 Hours, Every 7 Days
  2. Background task refreshes servers at the configured interval
  3. Failed fetches are retried with exponential backoff
  4. Default servers work seamlessly with existing VPN connection logic
  5. Expired servers (compare expire_date from API) are automatically removed from cache
  6. User preference persists across app sessions

**Plans**: TBD
