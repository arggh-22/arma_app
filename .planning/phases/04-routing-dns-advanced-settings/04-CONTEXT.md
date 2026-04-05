# Phase 4: Routing, DNS & Advanced Settings - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers fine-grained routing control, DNS configuration, anti-censorship settings, and Hysteria2 protocol support. Users can customize how traffic is routed (per-domain, per-app), configure DNS providers (DoH/DoT/plain), tune Xray engine settings (sniffing, mux, fragment), apply TLS anti-censorship tricks, and connect via Hysteria2 (UDP/QUIC).

</domain>

<decisions>
## Implementation Decisions

### Per-Domain Routing Rules (ROUTE-03, ROUTE-05)
- **D-01:** Presets + simple custom rules. Region presets (Iran, China, Russia) provide one-tap domestic traffic bypass. Users can also add individual domains with Proxy/Direct/Block action.
- **D-02:** Region presets sourced from BOTH bundled defaults (hardcoded known domestic domains/IPs) AND downloadable community sources (e.g., chocolate4u/Iran-v2ray-rules on GitHub). Bundled works offline; download option keeps rules current.
- **D-03:** Custom domain rules use a simple domain list UI — user types a domain (e.g., `example.com`) and picks Proxy/Direct/Block from a dropdown. No regex, no IP ranges, no port ranges — keep it simple.

### Per-App Proxy / Split Tunneling (ROUTE-04)
- **D-04:** User chooses between blacklist mode (all apps through VPN, exclude selected) and whitelist mode (no apps through VPN, include selected). Toggle to switch modes in settings.
- **D-05:** App picker is a scrollable list of all installed apps with icons, search filter, and checkboxes. Uses Android PackageManager to enumerate installed apps.

### DNS Configuration (ROUTE-02)
- **D-06:** Support three DNS protocols: DNS-over-HTTPS (DoH), DNS-over-TLS (DoT), and plain DNS. All three are configurable.
- **D-07:** DNS UI provides quick-select presets (Cloudflare 1.1.1.1, Google 8.8.8.8, Quad9 9.9.9.9, etc.) plus manual input for custom servers. Presets pre-fill the correct DoH/DoT URLs.

### Xray Engine Settings (UI-04)
- **D-08:** Engine settings organized as a separate "Engine Settings" section in Settings screen. Contains: Sniffing toggle (on/off), Mux toggle (on/off with concurrency setting), and general engine controls.
- **D-09:** Sniffing defaults to ON (current hardcoded behavior). Mux defaults to OFF (most servers don't need it).

### Anti-Censorship / TLS Tricks (UI-05)
- **D-10:** Anti-censorship settings organized as a separate "Anti-Censorship" section in Settings screen, distinct from Engine Settings. Contains: Fragment toggle, TLS fragment size range, TLS sleep range, padding, mixed SNI case.
- **D-11:** Preset profiles available: "Light", "Moderate", "Aggressive" that set all anti-censorship values at once. PLUS full customization — all fields always visible with default values pre-filled. Profiles serve as starting points that users can tweak.

### Hysteria2 Protocol (PROTO-05)
- **D-12:** Bandwidth hints (upMbps/downMbps) are optional with auto-detect. If the share link or subscription provides them, use them. If not, connect without hints. Users can manually set in advanced config.
- **D-13:** Salamander obfuscation supported for Hysteria2. Used by servers in China to disguise QUIC traffic as noise.
- **D-14:** Hysteria2 fields to add to ServerConfig: `upMbps`, `downMbps`, `insecure` (skip cert verify). Existing `obfs` and `obfsPassword` fields already cover salamander.

### Cache & Data Management (UI-06)
- **D-15:** "Clear cached data" option in Settings clears: geo rule cache, subscription cache, log files. Does NOT clear server configs or user preferences.

### Agent's Discretion
- Custom rule UI layout details (spacing, card vs list tile for rules)
- How frequently downloadable rule sets are checked for updates
- Exact TLS trick default values for each preset profile
- Hysteria2 `_buildStreamSettings` implementation details

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Xray-core Configuration
- `lib/xray/xray_config_builder.dart` — Current config builder; all DNS, routing, sniffing, stream settings live here. Phase 4 extends this significantly.
- `lib/features/server/domain/entities/server_config.dart` — Freezed entity; needs new fields for Hysteria2 and settings.

### Native VPN Integration
- `android/app/src/main/kotlin/com/arma/vpn/service/ArmaVpnService.kt` — VPN service with TUN setup; per-app routing modifies `configureTunInterface()`
- `android/app/src/main/kotlin/com/arma/vpn/MainActivity.kt` — Platform channel bridge; may need new method channels for app listing

### Settings & Persistence
- `lib/features/settings/data/datasources/settings_local_datasource.dart` — SharedPreferences store; add new keys for all Phase 4 settings
- `lib/features/settings/presentation/screens/settings_screen.dart` — Settings UI; add Engine Settings and Anti-Censorship sections

### Routing
- `lib/features/routing/presentation/screens/routing_screen.dart` — Currently skeleton; becomes the full routing rules screen

### Prior Context
- `.planning/phases/02-vpn-engine-core-connection/02-CONTEXT.md` — D-02 (config in Dart), D-11 (split DNS), D-12 (LAN bypass)
- `.planning/phases/03-subscriptions-server-intelligence/03-CONTEXT.md` — D-08 (MeasureDelay), share link parsers

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `XrayConfigBuilder` — Pure static Dart methods; extend with new settings parameters
- `SettingsLocalDatasource` — SharedPreferences pattern for persisting settings
- `SegmentedButton` pattern — Used for theme selection; reusable for mode toggles
- `ServerConfig` (Freezed) — Add new Hysteria2 fields, regenerate with build_runner
- `share_link_parser.dart` + `hysteria2_parser.dart` — Already parses `hysteria2://` and `hy2://` links

### Established Patterns
- Riverpod `@Riverpod(keepAlive: true)` for persisted state
- Material 3 `ListTile` + `SwitchListTile` for settings
- `MethodChannel` for Flutter ↔ Kotlin communication
- Config builder uses Dart 3 switch expressions for exhaustive protocol dispatch

### Integration Points
- `XrayConfigBuilder.build(server)` — Needs new `settings` parameter for DNS, sniffing, mux, fragment, routing rules
- `configureTunInterface()` in Kotlin — Needs per-app allow/disallow lists
- Routing screen tab at index 2 — Replace skeleton with full routing UI
- Settings screen — Add two new sections (Engine + Anti-Censorship)

</code_context>

<specifics>
## Specific Ideas

- Anti-censorship profiles: "Light" (minimal fragment), "Moderate" (fragment + padding), "Aggressive" (full fragment + sleep + mixed SNI + padding)
- Region presets should feel like one-tap setup — select "Iran" and all domestic domains bypass proxy automatically
- Per-app picker should show app icons for easy recognition, with search to filter by name
- DNS presets should include: Cloudflare (1.1.1.1), Google (8.8.8.8), Quad9 (9.9.9.9), AdGuard DNS, Electro (for Iran users)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-routing-dns-advanced-settings*
*Context gathered: 2026-04-05*
