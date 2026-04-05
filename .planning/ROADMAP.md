# Roadmap: Arma Proxy & VPN Client

## Overview

Arma delivers a privacy-first Xray-based VPN client for Android. The roadmap follows the natural dependency chain: first build the app shell and config import layer (so users can see and manage servers), then integrate the VPN engine (so users can actually connect), then add subscription management and server intelligence (for daily use), and finally unlock advanced routing and anti-censorship settings (for hostile network environments). Each phase delivers a coherent, verifiable capability that builds on the previous one.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation & Config Import** - Project architecture, UI shells, theming, localization, share link parsing, and local config persistence
- [x] **Phase 2: VPN Engine & Core Connection** - Xray-core AAR integration, VpnService, all core protocols, connect/disconnect, traffic monitoring, basic routing & DNS
- [x] **Phase 3: Subscriptions & Server Intelligence** - Subscription management, QR scanning, latency testing, bulk operations, server sorting/filtering, log viewer
- [ ] **Phase 4: Routing, DNS & Advanced Settings** - Per-domain/per-app routing, custom DNS, region presets, Hysteria2, TLS tricks, Xray engine toggles

## Phase Details

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
- [ ] 01-05-PLAN.md — Server list UI and import flow (FAB, clipboard, paste dialog)

**UI hint**: yes

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

**UI hint**: yes

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

**UI hint**: yes

### Phase 4: Routing, DNS & Advanced Settings
**Goal**: Users can fine-tune routing, DNS, and anti-censorship settings for hostile network environments
**Depends on**: Phase 3
**Requirements**: PROTO-05, ROUTE-02, ROUTE-03, ROUTE-04, ROUTE-05, UI-04, UI-05, UI-06
**Success Criteria** (what must be TRUE):
  1. User can configure per-domain routing rules (Proxy, Direct, or Block) and select region-specific bypass presets (Iran, China, Russia domestic traffic)
  2. User can enable per-app proxy (split tunneling) to choose which installed apps route through the VPN
  3. User can configure custom DNS servers (DoH/DoT) and connect via Hysteria2 protocol (UDP/QUIC)
  4. User can toggle Xray engine settings (sniffing, mux, fragment), configure TLS tricks (fragment size/sleep range, padding, mixed SNI case), and clear cached data from settings
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation & Config Import | 5/5 | ✅ Complete | 2026-04-04 |
| 2. VPN Engine & Core Connection | 5/5 | ✅ Complete | 2026-04-05 |
| 3. Subscriptions & Server Intelligence | 6/6 | ✅ Complete | 2026-04-05 |
| 4. Routing, DNS & Advanced Settings | 0/TBD | Not started | - |
