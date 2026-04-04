# Arma Proxy & VPN Client

## What This Is

A privacy-first proxy and VPN client app for Android that lets users connect to their own proxy servers with a single tap. Built on Xray-core, it supports VLESS (including Reality/XTLS), VMess, Trojan, Shadowsocks, Socks/HTTP, and Hysteria2 protocols. Designed for users in censored regions who need reliable, easy access to the open internet.

## Core Value

Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] One-tap VPN/proxy connection using Xray-core engine via Android VpnService
- [ ] Support for VLESS, VMess, Trojan, Shadowsocks, Socks/HTTP, and Hysteria2 protocols
- [ ] Parse and import server configs via share links (vless://, vmess://, trojan://, ss://)
- [ ] Import configs from QR code scan, clipboard, manual JSON entry, and subscription URLs
- [ ] Subscription management with base64-encoded and encrypted config support
- [ ] Server list with protocol badges, latency display, and active node selection
- [ ] Bulk selection and deletion of configurations (long-press multi-select)
- [ ] Real-time latency testing (ping/TCPing) for individual nodes and bulk testing
- [ ] Live traffic monitoring (upload/download speeds) on dashboard
- [ ] Flexible traffic routing rules (bypass LAN, proxy/direct/block per domain/IP)
- [ ] Custom DNS configuration and DNS blocking
- [ ] Light and dark theme with clean, minimalist design
- [ ] Settings for Xray features (sniffing, mux, fragment handling)
- [ ] Auto-update subscriptions on app launch (configurable)
- [ ] Export app logs for debugging

### Out of Scope

- Web site / documentation hub — deferred to future milestone
- iOS / macOS / Windows / Linux builds — deferred to future milestones (Android-first)
- Bundled free/trial servers — the app is strictly a client for v1; free servers may come in v2+
- User accounts / authentication — no backend; all config is local
- In-app purchases / monetization — not in v1 scope
- TV platform support — deferred

## Context

- **Existing codebase:** Freshly scaffolded Flutter project (default counter app). No architecture or features implemented yet. A comprehensive spec document (`happ_clone_specs.md`) defines the full target vision.
- **Target users:** People in censored regions (e.g., Iran, China, Russia) who use proxy tools like V2rayNG, Nekobox, Hiddify, and Happ to access the internet. They already have server configs from providers or self-hosted servers.
- **Competitive landscape:** V2rayNG (Android-native, functional but ugly), Hiddify (Flutter, feature-rich), Happ (clean UI, closed source), Nekobox (power-user focused). Arma aims for clean UX + reliability.
- **Xray-core:** The Go-based proxy engine that handles all protocol connections. Must be compiled via Go-Mobile into an AAR and integrated through Kotlin platform channels with Android's VpnService API.
- **Reference spec:** `happ_clone_specs.md` in the repo root contains the full UI/UX spec and phased development plan that this project follows.

## Constraints

- **Tech stack**: Flutter (Dart) with Clean Architecture + MVVM, Riverpod for state management, Hive for local storage, go_router for navigation
- **Platform**: Android-only for v1 (API 21+ / Android 5.0+)
- **Engine**: Xray-core compiled via Go-Mobile, integrated through Kotlin platform channels and Android VpnService
- **No backend**: All data stored locally on device; no server-side components
- **Privacy**: No analytics, no tracking, no data collection — privacy-first by design

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Flutter over native Android | Cross-platform future (iOS/desktop) with single codebase | — Pending |
| Xray-core via Go-Mobile AAR | Direct control over engine, supports all required protocols | — Pending |
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
*Last updated: 2026-04-04 after initialization*
