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

## v1.2 Requirements

Requirements for integrating your VPN server API to display default servers in home screen.

### API Integration

- [x] **API-01**: Device authentication with VPN server API (`POST /auth/device/`)
  - Generate and persist device HWID (UUID) on app install
  - Maintain HWID across app updates and reinstalls
  - Send device_id, os_type, app_version to API
  - Store and refresh authentication token securely

- [x] **API-02**: Fetch user's VPN keys from API (`GET /keys/`)
  - Use stored token from device auth
  - Parse response: id, name, key_body, subscription_url, expire_date, status, used_traffic, data_limit
  - Handle 401 Unauthorized by requesting new device auth
  - Handle network errors gracefully

- [x] **API-03**: Error handling for API calls
  - Gracefully handle offline state (show cached servers or placeholder)
  - Handle timeout errors (5-second timeout, show retry button)
  - Handle 4xx/5xx errors with user-friendly messages
  - Never crash or hang the app on API failures

### Home Screen Display

- [ ] **UI-01**: Default servers section in home screen
  - Show in bottom half of home screen (below connection stats)
  - Display server list with: name, status badge (active/expired/limited), traffic info
  - Allow users to tap a server to connect (use existing connection logic)
  - Show loading state while fetching from API

- [ ] **UI-02**: Manual refresh button
  - Add refresh button in default servers section
  - Trigger re-fetch from API
  - Show loading spinner during fetch
  - Update list with latest servers from API

### Data Management

- [ ] **DATA-01**: Fetch on first launch
  - Trigger device auth on first app open
  - Fetch default servers immediately after auth
  - Cache servers locally in Hive
  - Display cached servers immediately

- [ ] **DATA-02**: Auto-update functionality
  - Support user-configurable update intervals (Disabled, 12h, 24h, 7 days)
  - Implement background task to refresh servers at configured interval
  - Update cached servers without requiring manual refresh
  - Respect user's update preference from settings

- [ ] **DATA-03**: Server storage
  - Store default servers separately from user-added servers in Hive
  - Include metadata: fetch_timestamp, expires_at, api_source
  - Clear expired servers (compare with expire_date from API)

### Integration with Existing Features

- [ ] **COMPAT-01**: Connection compatibility
  - Default servers must work with existing VPN connection logic
  - Use key_body string as server config (same as user-added servers)
  - Support all existing protocols (VLESS, VMess, Trojan, SS, Hysteria2)

- [ ] **COMPAT-02**: Settings integration
  - Add "Default Servers Auto-Update" setting to settings screen
  - Options: Disabled, Every 12 Hours, Every 24 Hours, Every 7 Days
  - Persist setting in Hive

### Security & Reliability

- [x] **SEC-01**: Credentials storage
  - Store device HWID securely in Hive (encrypted)
  - Store API token securely (encrypted in Hive)
  - Never log tokens or HWID in plain text

- [x] **REL-01**: Offline support
  - Display cached default servers even when offline
  - Queue refresh requests when network is unavailable
  - Auto-retry failed fetches with exponential backoff

---
**Coverage (v1.2):**
- v1.2 requirements: 14 total
- Mapped to phases: (pending roadmap)

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 before roadmap creation (v1.2)*
