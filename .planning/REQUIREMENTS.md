# Requirements: Arma Proxy & VPN Client

**Defined:** 2026-04-04
**Core Value:** Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.

## v1 Requirements

### VPN Engine

- [x] **ENG-01**: App integrates Xray-core via Go-Mobile AAR with Android VpnService to capture all device traffic in TUN mode
- [x] **ENG-02**: App generates valid Xray-core JSON config from user-facing settings (inbounds, outbounds, routing, dns sections)
- [ ] **ENG-03**: User can connect/disconnect with a single tap from the dashboard
- [ ] **ENG-04**: Connection state is clearly displayed: Disconnected → Connecting → Connected (with color coding)
- [x] **ENG-05**: VPN runs as foreground service with persistent notification showing connection status

### Protocols

- [x] **PROTO-01**: User can connect via VLESS protocol including Reality and XTLS-Vision support
- [x] **PROTO-02**: User can connect via VMess protocol (AES-128-GCM/ChaCha20)
- [x] **PROTO-03**: User can connect via Trojan protocol
- [x] **PROTO-04**: User can connect via Shadowsocks protocol
- [ ] **PROTO-05**: User can connect via Hysteria2 protocol (UDP/QUIC)
- [x] **PROTO-06**: All protocols support common transport types: TCP, WebSocket, gRPC, HTTP/2

### Config Import

- [x] **CONF-01**: User can import configs by pasting share links (vless://, vmess://, trojan://, ss://, hysteria2://)
- [ ] **CONF-02**: User can import configs by scanning QR codes via camera
- [ ] **CONF-03**: User can import configs from clipboard with one tap
- [ ] **CONF-04**: User can add subscription URLs that deliver multiple server configs
- [x] **CONF-05**: App parses both VMess formats: legacy base64-JSON and standard URI
- [ ] **CONF-06**: User can manually enter config via JSON paste
- [ ] **CONF-07**: Subscription auto-updates on app launch (configurable toggle)
- [ ] **CONF-08**: User can set custom User-Agent for subscription fetches
- [ ] **CONF-09**: App supports encrypted/hidden subscription formats
- [ ] **CONF-10**: User can share/export a config as share link or QR code

### Server Management

- [ ] **SERV-01**: User sees a list of all servers grouped by subscription with protocol badges and latency
- [x] **SERV-02**: User can tap a server to select it as the active node
- [ ] **SERV-03**: User can test latency for individual servers (HTTP ping / TCPing)
- [ ] **SERV-04**: User can test latency for all servers in bulk
- [ ] **SERV-05**: User can long-press to enter multi-select mode for bulk deletion
- [ ] **SERV-06**: User can sort servers by latency, name, or protocol
- [ ] **SERV-07**: User can filter servers by working/failed status
- [ ] **SERV-08**: App displays subscription info: data used, data remaining, expiry date (from subscription-userinfo header)
- [ ] **SERV-09**: App can auto-select the best server based on lowest latency

### Connection & Monitoring

- [ ] **MON-01**: Dashboard shows real-time upload and download speeds (updated every 1-2 seconds)
- [ ] **MON-02**: Dashboard shows connection duration timer
- [ ] **MON-03**: Persistent notification displays connection status and current traffic speeds
- [ ] **MON-04**: App auto-reconnects when network changes (WiFi ↔ cellular)
- [ ] **MON-05**: User can view Xray-core logs in a scrollable viewer
- [ ] **MON-06**: User can export logs as a text file for debugging/support

### Routing & DNS

- [x] **ROUTE-01**: App bypasses LAN traffic by default (192.168.x.x, 10.x.x.x)
- [ ] **ROUTE-02**: User can configure custom DNS servers (DoH/DoT supported)
- [ ] **ROUTE-03**: User can set per-domain routing rules: Proxy, Direct, or Block
- [ ] **ROUTE-04**: User can enable per-app proxy (split tunneling) to choose which apps use the proxy
- [ ] **ROUTE-05**: App provides region-specific bypass presets (Iran, China, Russia domestic traffic)
- [x] **ROUTE-06**: DNS is split: remote DNS for proxied domains, direct DNS for local domains (no DNS leaks)

### UI & Settings

- [x] **UI-01**: App has a clean, modern design with Light and Dark theme (Material 3)
- [ ] **UI-02**: Dashboard has a prominent connect/disconnect button with satisfying visual feedback
- [x] **UI-03**: App supports multiple languages: English, Persian (RTL), Russian, Chinese
- [ ] **UI-04**: Settings screen includes Xray toggles: Sniffing, Mux (multiplexing), Fragment handling
- [ ] **UI-05**: Settings screen includes TLS tricks: fragment size/sleep range, padding, mixed SNI case
- [ ] **UI-06**: User can clear cached data and export app logs from settings
- [ ] **UI-07**: FAB on config screen expands with import options: QR, Clipboard, Subscription, Manual

### Storage

- [x] **STOR-01**: All configs and subscriptions persist locally across app restarts (hive_ce)
- [x] **STOR-02**: User preferences (theme, language, routing rules, Xray settings) persist locally

## v2 Requirements

### Cross-Platform

- **XPLAT-01**: App builds and runs on iOS
- **XPLAT-02**: App builds and runs on macOS
- **XPLAT-03**: App builds and runs on Windows
- **XPLAT-04**: App builds and runs on Linux

### Advanced Features

- **ADV-01**: WARP integration (Cloudflare Warp as fallback connection)
- **ADV-02**: Clash/Sing-box config import
- **ADV-03**: Deep link support (arma://import/... or vless://... from other apps)
- **ADV-04**: Auto-start VPN on device boot
- **ADV-05**: Downloadable community geo rule sets
- **ADV-06**: Proxy chain (double proxy for extra anonymity)
- **ADV-07**: Android home screen widget for quick connect
- **ADV-08**: Speed test through proxy (download throughput)

### Web & Distribution

- **WEB-01**: Documentation/download web site (GitBook-style clone of happ.su)
- **WEB-02**: Bundled free/trial servers for first-time users

## Out of Scope

| Feature | Reason |
|---------|--------|
| User accounts / authentication | No backend; all config is local. Privacy-first. |
| Analytics / telemetry | Privacy-first. Any analytics in a circumvention tool destroys trust. |
| In-app ads | Users are bypassing censorship. Ads are tone-deaf. Revenue via donations. |
| Full JSON config editor (visual) | 95% of users never edit raw JSON. Share links and subscriptions cover all cases. |
| Protocol implementation from scratch | Xray-core exists and is battle-tested. Use it as a black box via Go-Mobile AAR. |
| VPN kill switch (v1) | Complex to implement correctly. If done wrong, leaks traffic or bricks internet. Add in v2. |
| Traffic interception / MITM | Security and legal minefield. Proxy traffic, don't inspect it. |
| TV platform (v1) | Tiny user base, different UI paradigm (D-pad navigation). Defer to v2+. |
| TUIC / WireGuard / SSH protocols | Growing but not critical for v1. Xray-core support varies. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENG-01 | Phase 2 | Complete |
| ENG-02 | Phase 2 | Complete |
| ENG-03 | Phase 2 | Pending |
| ENG-04 | Phase 2 | Pending |
| ENG-05 | Phase 2 | Complete |
| PROTO-01 | Phase 2 | Complete |
| PROTO-02 | Phase 2 | Complete |
| PROTO-03 | Phase 2 | Complete |
| PROTO-04 | Phase 2 | Complete |
| PROTO-05 | Phase 4 | Pending |
| PROTO-06 | Phase 2 | Complete |
| CONF-01 | Phase 1 | Complete |
| CONF-02 | Phase 3 | Pending |
| CONF-03 | Phase 1 | Pending |
| CONF-04 | Phase 3 | Pending |
| CONF-05 | Phase 1 | Complete |
| CONF-06 | Phase 1 | Pending |
| CONF-07 | Phase 3 | Pending |
| CONF-08 | Phase 3 | Pending |
| CONF-09 | Phase 3 | Pending |
| CONF-10 | Phase 3 | Pending |
| SERV-01 | Phase 1 | Pending |
| SERV-02 | Phase 1 | Complete |
| SERV-03 | Phase 3 | Pending |
| SERV-04 | Phase 3 | Pending |
| SERV-05 | Phase 3 | Pending |
| SERV-06 | Phase 3 | Pending |
| SERV-07 | Phase 3 | Pending |
| SERV-08 | Phase 3 | Pending |
| SERV-09 | Phase 3 | Pending |
| MON-01 | Phase 2 | Pending |
| MON-02 | Phase 2 | Pending |
| MON-03 | Phase 2 | Pending |
| MON-04 | Phase 2 | Pending |
| MON-05 | Phase 3 | Pending |
| MON-06 | Phase 3 | Pending |
| ROUTE-01 | Phase 2 | Complete |
| ROUTE-02 | Phase 4 | Pending |
| ROUTE-03 | Phase 4 | Pending |
| ROUTE-04 | Phase 4 | Pending |
| ROUTE-05 | Phase 4 | Pending |
| ROUTE-06 | Phase 2 | Complete |
| UI-01 | Phase 1 | Complete |
| UI-02 | Phase 2 | Pending |
| UI-03 | Phase 1 | Complete |
| UI-04 | Phase 4 | Pending |
| UI-05 | Phase 4 | Pending |
| UI-06 | Phase 4 | Pending |
| UI-07 | Phase 1 | Pending |
| STOR-01 | Phase 1 | Complete |
| STOR-02 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 51 total
- Mapped to phases: 51 ✓
- Unmapped: 0

**By Phase:**
- Phase 1 (Foundation & Config Import): 11 requirements
- Phase 2 (VPN Engine & Core Connection): 17 requirements
- Phase 3 (Subscriptions & Server Intelligence): 15 requirements
- Phase 4 (Routing, DNS & Advanced Settings): 8 requirements

---
*Requirements defined: 2026-04-04*
*Last updated: 2026-04-05 after roadmap creation*
