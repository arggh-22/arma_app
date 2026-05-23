# Arma Proxy & VPN Client

## What This Is

A privacy-first proxy and VPN client app for Android that lets users connect to their own proxy servers with a single tap. Built on sing-box, it supports VLESS (including Reality/XTLS), VMess, Trojan, Shadowsocks, Socks/HTTP, and Hysteria2 protocols. Designed for users in censored regions who need reliable, easy access to the open internet.

## Core Value

Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.

## Requirements

### Validated

- [x] One-tap VPN/proxy connection via Android VpnService (Phase 2)
- [x] Support for VLESS, VMess, Trojan, Shadowsocks, Socks/HTTP protocols (Phase 1-2)
- [x] Parse and import server configs via share links (Phase 1)
- [x] Import configs from QR code scan, clipboard, manual JSON entry, and subscription URLs (Phase 1, 3)
- [x] Subscription management with base64-encoded config support (Phase 3)
- [x] Server list with protocol badges, latency display, and active node selection (Phase 1, 3)
- [x] Bulk selection and deletion of configurations (Phase 3)
- [x] Real-time latency testing for individual nodes and bulk testing (Phase 3)
- [x] Live traffic monitoring (upload/download speeds) on dashboard (Phase 2)
- [x] Flexible traffic routing rules (bypass LAN, proxy/direct/block per domain) (Phase 4)
- [x] Custom DNS configuration (DoH/DoT/Plain) (Phase 4)
- [x] Light and dark theme with clean, minimalist design (Phase 1)
- [x] Settings for engine features (sniffing, mux, fragment) (Phase 4)
- [x] Anti-censorship profiles (fragment, padding, mixed SNI) (Phase 4)
- [x] Per-app proxy / split tunneling (Phase 4)
- [x] Region presets for routing (Iran, China, Russia) (Phase 4)
- [x] Export app logs for debugging (Phase 3)

### Active

- [ ] Replace Xray-core engine with sing-box for cross-platform support
- [ ] Maintain all v1.0 protocol support under sing-box (VLESS, VMess, Trojan, SS, Hysteria2)
- [ ] sing-box config generation replacing Xray JSON format
- [ ] Verify anti-censorship features work under sing-box (fragment, Reality, etc.)

### Out of Scope

- Web site / documentation hub — deferred to future milestone
- iOS / macOS / Windows / Linux builds — deferred to future milestones (Android-first)
- Bundled free/trial servers — the app is strictly a client for v1; free servers may come in v2+
- User accounts / authentication — no backend; all config is local
- In-app purchases / monetization — not in v1 scope
- TV platform support — deferred

## Current Milestone: v1.2 Default VPN Servers Integration

**Goal:** Integrate your VPN server API to fetch and display authenticated user's default VPN servers in the home screen, improving user experience with one-tap access to pre-configured servers.

**Target features:**
- Device authentication with VPN API (`/auth/device/`)
- Fetch user's VPN keys/subscriptions from API (`/keys/`)
- Display default servers in home screen bottom half (below connection stats)
- Fetch on app first launch + manual refresh button
- Periodic auto-update with user-configurable intervals
- Connect to default servers like any other server
- Handle API errors gracefully with fallback UI

## Context

- **Existing codebase:** Fully functional v1.0 Android VPN client with 4 phases complete. Architecture: Flutter + Clean Architecture + MVVM, Riverpod state management, Hive local storage. Currently uses Xray-core via libv2ray.aar (Go-Mobile compiled AAR from 2dust/AndroidLibXrayLite).
- **Target users:** People in censored regions (e.g., Iran, China, Russia) who use proxy tools like V2rayNG, Nekobox, Hiddify, and Happ to access the internet. They already have server configs from providers or self-hosted servers.
- **Competitive landscape:** V2rayNG (Android-native, Xray-core), Hiddify (Flutter, sing-box), Happ (clean UI, closed source), Nekobox (power-user, sing-box). Arma aims for clean UX + reliability.
- **Engine migration:** Moving from Xray-core to sing-box for broader protocol support, better mobile performance, unified config format, and native cross-platform libraries (iOS, macOS, Windows, Linux).
- **Reference spec:** `happ_clone_specs.md` in the repo root contains the full UI/UX spec.

## Constraints

- **Tech stack**: Flutter (Dart) with Clean Architecture + MVVM, Riverpod for state management, Hive for local storage, go_router for navigation
- **Platform**: Android-only for v1 (API 21+ / Android 5.0+)
- **Engine**: sing-box (migrating from Xray-core), integrated through Kotlin platform channels and Android VpnService. Future: native libraries for iOS/macOS/Windows/Linux.
- **No backend**: All data stored locally on device; no server-side components
- **Privacy**: No analytics, no tracking, no data collection — privacy-first by design

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over native Android | Cross-platform future (iOS/desktop) with single codebase | — Pending |
| Xray-core via Go-Mobile AAR | Direct control over engine, supports all required protocols | Validated in v1.0, migrating to sing-box in v1.1 |
| sing-box over Xray-core | Cross-platform libraries, better mobile perf, unified config, broader protocols | v1.1 migration |
| Clean Architecture + MVVM | Spec requirement, good separation for testability and scaling | — Pending |
| Riverpod over BLoC | Spec preference, better testability and simpler boilerplate | — Pending |
| Hive over SQLite | Lightweight NoSQL, good for config/subscription storage, spec recommendation | — Pending |
| Android-first | Primary user base is Android-heavy in target regions | — Pending |
| No bundled servers for v1 | Reduces legal risk, app is strictly a client tool | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-24 — v1.2 milestone started (Default VPN Servers Integration)*
