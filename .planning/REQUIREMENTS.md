# Requirements: Arma Proxy & VPN Client

**Defined:** 2026-04-08
**Core Value:** Privacy-first VPN client that just works — one tap to connect, zero technical knowledge required

## v1.0 Requirements (Validated)

All v1.0 requirements completed and shipped. See MILESTONES.md for details.

## v1.1 Requirements

Requirements for sing-box engine migration. Each maps to roadmap phases.

### Engine Core

- [ ] **ENGINE-01**: App integrates sing-box library (libbox.aar) replacing Xray-core as VPN engine
- [ ] **ENGINE-02**: App starts and stops VPN through sing-box CommandServer lifecycle
- [ ] **ENGINE-03**: VPN service implements sing-box PlatformInterface with inverted TUN control
- [ ] **ENGINE-04**: User can toggle between sing-box and Xray-core engines via Settings (dual-engine rollback)
- [ ] **ENGINE-05**: App validates generated config via `checkConfig()` before connecting

### Config Builder

- [ ] **CONFIG-01**: App generates valid sing-box JSON for VLESS (including Reality + XTLS Vision)
- [ ] **CONFIG-02**: App generates valid sing-box JSON for VMess
- [ ] **CONFIG-03**: App generates valid sing-box JSON for Trojan
- [ ] **CONFIG-04**: App generates valid sing-box JSON for Shadowsocks
- [ ] **CONFIG-05**: App generates valid sing-box JSON for Hysteria2
- [ ] **CONFIG-06**: App generates valid sing-box config for TCP, WebSocket, gRPC, HTTP/2 transports
- [ ] **CONFIG-07**: App generates valid sing-box config for ECH (Encrypted Client Hello)
- [ ] **CONFIG-08**: App generates valid sing-box config for HTTPUpgrade transport

### Traffic & Monitoring

- [ ] **MONITOR-01**: App displays real-time upload/download speed via CommandClient subscription
- [ ] **MONITOR-02**: App displays connection status via CommandClient status streaming
- [ ] **MONITOR-03**: App displays active connection count
- [ ] **MONITOR-04**: App displays per-outbound traffic statistics
- [ ] **MONITOR-05**: User can test server latency using sing-box-compatible approach

### Routing & DNS

- [ ] **ROUTE-01**: App uses sing-box rule-set format (.srs) for geo-based routing
- [ ] **ROUTE-02**: Region presets (Iran, China, Russia) work with sing-box rule-sets
- [ ] **ROUTE-03**: LAN bypass works via `ip_is_private` route rule
- [ ] **ROUTE-04**: DNS configuration uses sing-box typed server format (DoH/DoT/Plain)
- [ ] **ROUTE-05**: FakeIP DNS mode is available as user option
- [ ] **ROUTE-06**: Protocol sniffing works via sing-box route rules
- [ ] **ROUTE-07**: Rule-sets auto-update from remote sources with cache

### Anti-Censorship

- [ ] **CENSOR-01**: TLS fragment (boolean) is configurable in Settings
- [ ] **CENSOR-02**: TLS record_fragment is configurable in Settings
- [ ] **CENSOR-03**: Mux with padding (h2mux/yamux) is configurable in Settings

### Per-App Proxy

- [ ] **PERAPP-01**: Per-app proxy uses sing-box TUN-level `include_package`/`exclude_package`

## Future Requirements

Deferred to v1.2+. Tracked but not in current roadmap.

### Anti-Censorship (Hiddify Fork)

- **CENSOR-F01**: Granular TLS fragment with configurable min/max length and sleep intervals
- **CENSOR-F02**: Mixed SNI case randomization for DPI evasion
- **CENSOR-F03**: TLS padding with configurable size

### New Protocols

- **PROTO-F01**: User can connect via WireGuard protocol
- **PROTO-F02**: User can connect via TUIC protocol
- **PROTO-F03**: User can connect via NaiveProxy protocol

### Cross-Platform

- **PLAT-F01**: iOS build using sing-box iOS library
- **PLAT-F02**: macOS build using sing-box desktop library
- **PLAT-F03**: Windows build using sing-box desktop library

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Hiddify fork of sing-box | Standard sing-box boolean fragment ships first; evaluate if sufficient in field testing |
| iOS/macOS/Windows builds | sing-box enables this but deferred to v1.2+ after Android engine proven stable |
| New protocols (WireGuard, TUIC, Naive) | sing-box supports them but not needed for migration milestone |
| sing-box mux interop with Xray servers | sing-box mux not interoperable with Xray-core servers; mux only when both sides run sing-box |
| Standard gRPC transport replacement | sing-box uses lightweight gRPC; full gRPC increases binary size, defer unless needed |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENGINE-01 | Phase 5 | Pending |
| ENGINE-02 | Phase 6 | Pending |
| ENGINE-03 | Phase 6 | Pending |
| ENGINE-04 | Phase 7 | Pending |
| ENGINE-05 | Phase 5 | Pending |
| CONFIG-01 | Phase 5 | Pending |
| CONFIG-02 | Phase 5 | Pending |
| CONFIG-03 | Phase 5 | Pending |
| CONFIG-04 | Phase 5 | Pending |
| CONFIG-05 | Phase 5 | Pending |
| CONFIG-06 | Phase 5 | Pending |
| CONFIG-07 | Phase 5 | Pending |
| CONFIG-08 | Phase 5 | Pending |
| MONITOR-01 | Phase 6 | Pending |
| MONITOR-02 | Phase 6 | Pending |
| MONITOR-03 | Phase 6 | Pending |
| MONITOR-04 | Phase 6 | Pending |
| MONITOR-05 | Phase 6 | Pending |
| ROUTE-01 | Phase 7 | Pending |
| ROUTE-02 | Phase 7 | Pending |
| ROUTE-03 | Phase 7 | Pending |
| ROUTE-04 | Phase 7 | Pending |
| ROUTE-05 | Phase 7 | Pending |
| ROUTE-06 | Phase 7 | Pending |
| ROUTE-07 | Phase 7 | Pending |
| CENSOR-01 | Phase 7 | Pending |
| CENSOR-02 | Phase 7 | Pending |
| CENSOR-03 | Phase 7 | Pending |
| PERAPP-01 | Phase 7 | Pending |

**Coverage:**
- v1.1 requirements: 29 total
- Mapped to phases: 29 ✓
- Unmapped: 0

**Phase distribution:**
- Phase 5 (Engine Foundation & Config Builder): 10 requirements
- Phase 6 (VPN Service & Connection Monitoring): 7 requirements
- Phase 7 (Feature Parity & Dual-Engine Safety): 12 requirements

---
*Requirements defined: 2026-04-08*
*Last updated: 2026-04-08 after roadmap creation*
