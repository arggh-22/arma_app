# Phase 3: Subscriptions & Server Intelligence - Context

**Gathered:** 2026-04-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can manage proxy subscriptions, scan QR codes, test server latency, auto-select best servers, view/export logs, and share configs. This phase adds the intelligence layer on top of the working VPN engine from Phase 2: subscription lifecycle, server quality metrics, bulk operations, and diagnostic tools.

</domain>

<decisions>
## Implementation Decisions

### Subscription Fetch & Formats
- **D-01:** Auto-detect subscription body format: try base64 decode first, fall back to plain text (one share link per line). Both formats are common across V2Ray providers.
- **D-02:** Support three subscription formats: (1) standard base64/plain text share links, (2) SIP008 JSON array (Shadowsocks), (3) Clash YAML format. Auto-detect by content inspection.
- **D-03:** Parse `subscription-userinfo` HTTP response header when present (`upload`, `download`, `total`, `expire` fields). Display data usage and expiry in the subscription group header UI. No strict enforcement — informational only.
- **D-04:** Auto-refresh subscriptions on app launch (configurable toggle in settings, default ON). Manual pull-to-refresh available on the server list. No background periodic refresh in this phase.
- **D-05:** Custom User-Agent configurable per subscription (CONF-08). Default to a standard browser UA to avoid provider fingerprinting.

### QR Code Scanner
- **D-06:** Use `mobile_scanner` package (Google ML Kit, actively maintained) for QR code scanning.
- **D-07:** Auto-detect QR content type: if scanned text is a share link (`vless://`, `vmess://`, etc.), import as single server. If it's an HTTP(S) URL, treat as subscription URL and prompt to add subscription.

### Latency Testing
- **D-08:** Use Xray-core's built-in `MeasureDelay` for latency testing — real HTTP ping through the proxy chain. Most accurate representation of actual connection quality.
- **D-09:** Bulk latency testing runs with parallel concurrency limit of 3-5 simultaneous tests. Results update in the server list as they arrive (progressive UI update).

### Log Viewer
- **D-10:** Dual log architecture: (1) stream logs in real-time from `:vpn_process` via existing MSG_DEBUG_LOG → EventChannel pipeline for live viewing, (2) buffer logs to a file for export functionality (MON-06).
- **D-11:** Ring buffer strategy: keep last ~5000 lines, auto-discard oldest. Prevents unbounded log growth at debug verbosity.

### Subscription UI/UX
- **D-12:** Subscriptions are inline in the server list as collapsible group headers. Each header shows: subscription name, server count, data usage/expiry (if available from subscription-userinfo), and a refresh button. No separate subscription management screen.
- **D-13:** Subscription update replaces ALL servers from that subscription with fresh data. No merge logic — clean slate on each refresh.
- **D-14:** If the active/connected server belongs to an updated subscription, auto-select the first server from the new list. If connected, disconnect first, update, then reconnect to new selection.
- **D-15:** "Add subscription" integrated into the existing expandable FAB on the server list screen.

### Auto-Select Best Server
- **D-16:** Weighted algorithm combining latency (primary) and last-used success rate (secondary). Servers that recently failed get penalized. Requires latency data — prompts user to run latency test if no data available.
- **D-17:** Dual trigger: (1) manual "Best Server" button in the UI, (2) automatic fallback when the selected server fails to connect — silently try the next best server.

### Export/Share Configs
- **D-18:** Export format: share link text (standard URI format for the protocol) + QR code image. User can copy to clipboard, use system share sheet, or display QR for scanning.
- **D-19:** Use `qr_flutter` package for QR code generation (lightweight, pure Dart widget rendering).

### Agent's Discretion
- Subscription entity/model design (fields, Hive typeId, relationships)
- HTTP client choice (http vs dio) for subscription fetching
- Exact concurrency limit for bulk latency testing (3 vs 5)
- Ring buffer implementation details (in-memory list vs file-based)
- Server success rate tracking persistence strategy
- QR code display dialog/screen design
- Clash YAML parsing library choice
- SIP008 JSON schema handling
- Sort/filter UI controls placement and interaction
- Multi-select mode gestures and visual feedback
- Log viewer screen layout and filtering controls
- Error handling for failed subscription fetches (retry, timeout, offline)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing Architecture (from Phase 2)
- `.planning/phases/02-vpn-engine-core-connection/02-CONTEXT.md` — Platform bridge decisions, VpnService lifecycle, Xray config generation in Dart
- `.planning/research/ARCHITECTURE.md` — Three-layer bridge pattern (Flutter → Kotlin → Go AAR)
- `.planning/research/STACK.md` — AndroidLibXrayLite AAR API: `QueryStats`, `MeasureDelay`, `CheckVersionX`

### Reusable Code Assets
- `lib/features/server/data/parsers/share_link_parser.dart` — Complete parser dispatcher for all 5 protocols. Subscription parser wraps this per-line.
- `lib/features/server/domain/entities/server_config.dart` — Already has `subscriptionId` (String?) and `groupName` fields.
- `lib/features/server/data/models/server_config_model.dart` — Hive model with intentional field gaps for extension. `typeId: 0`.
- `lib/features/server/presentation/widgets/server_card.dart` — Server list item widget with protocol badge.
- `lib/features/server/presentation/widgets/server_group_header.dart` — Group header widget (extend for subscription metadata).
- `lib/features/server/presentation/widgets/import_fab.dart` — Expandable FAB with QR scan stub (line 161-170, shows "coming soon").
- `lib/features/server/data/datasources/server_local_datasource.dart` — Hive CRUD pattern to follow for SubscriptionLocalDatasource.
- `lib/features/connection/data/datasources/vpn_platform_service.dart` — Platform channel pattern, EventChannel broadcast stream.

### Requirements Coverage
- CONF-02: QR code import (D-06, D-07)
- CONF-04: Subscription URLs (D-01, D-02, D-12)
- CONF-07: Auto-update on launch (D-04)
- CONF-08: Custom User-Agent (D-05)
- CONF-09: Encrypted/hidden formats (D-02 — SIP008, Clash)
- CONF-10: Share/export as link + QR (D-18, D-19)
- SERV-03: Individual latency test (D-08)
- SERV-04: Bulk latency test (D-09)
- SERV-05: Multi-select bulk deletion (Agent's discretion — UX)
- SERV-06: Sort by latency/name/protocol (Agent's discretion — UX)
- SERV-07: Filter by working/failed (Agent's discretion — UX)
- SERV-08: Subscription info display (D-03, D-12)
- SERV-09: Auto-select best server (D-16, D-17)
- MON-05: Log viewer (D-10, D-11)
- MON-06: Log export (D-10)

</canonical_refs>

<deferred_ideas>
## Deferred Ideas

- Background periodic subscription refresh (every X hours) — consider for Phase 5 polish
- Subscription URL encryption/obfuscation for censorship evasion — future phase
- Server speed test (not just latency — actual throughput measurement) — future phase
- Subscription grouping/tagging by user-defined categories — future phase
- Import from file (not just QR/clipboard/URL) — consider for Phase 5
</deferred_ideas>
