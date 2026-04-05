# Phase 2: VPN Engine & Core Connection - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Users can connect to their proxy servers with a single tap and monitor the live connection. This phase builds the entire native bridge: Xray-core AAR integration, Android VpnService with TUN mode, platform channel communication, connection state management, real-time traffic monitoring, foreground notification, network resilience (auto-reconnect, split DNS), and LAN bypass.

</domain>

<decisions>
## Implementation Decisions

### Xray-core Integration
- **D-01:** Use pre-built AAR from AndroidLibXrayLite (2dust's official releases). Do NOT build from source with gomobile — avoids Go/gomobile/NDK version lock-step fragility (Pitfall #2).
- **D-02:** Xray JSON config is built entirely in Dart. The native Kotlin side is a dumb executor — it receives the complete JSON string and passes it to `StartLoop(json, tunFd)`. No config construction logic in Kotlin.

### Connection State UX
- **D-03:** Connect button transitions: Grey (disconnected) → Pulsing teal ring animation (connecting) → Solid teal glow (connected). Happ-style power button animation on the existing circular button from Phase 1 (D-03).
- **D-04:** Connection duration timer displayed as a separate text widget below the connect button, showing `00:00:00` elapsed time.
- **D-05:** Real-time traffic stats shown as two side-by-side cards below the timer — ↑ upload speed and ↓ download speed, updated in real-time.

### VpnService Lifecycle
- **D-06:** VpnService runs in a separate Android process (`:vpn_process`). Go panics in xray-core cannot crash the Flutter UI. This follows V2rayNG's `:RunSoLibV2RayDaemon` pattern.
- **D-07:** Foreground notification shows: connection status, server name, upload/download speeds. Tapping the notification opens the app. Standard persistent notification (not minimal, not rich-with-controls).
- **D-08:** Flutter ↔ VpnService communication via MethodChannel (commands: connect, disconnect, getStatus) + EventChannel (streaming: connection state changes, real-time traffic stats). This crosses the process boundary.
- **D-09:** VPN shutdown order follows Pitfall #1: stop tun2socks → stopSelf() → close TUN fd. Never close TUN fd before stopSelf().

### Network Resilience
- **D-10:** Automatic silent reconnect on network changes (WiFi ↔ cellular). ConnectivityManager detects changes, xray-core loop restarts automatically. No user action needed.
- **D-11:** Split DNS from day one — remote DNS for proxied domains, direct DNS for local/LAN domains. Prevents DNS leaks per research recommendations.
- **D-12:** LAN bypass enabled by default (already toggled in Phase 1 Routing screen). VpnService route configuration excludes private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16).

### Agent's Discretion
- Exact Xray JSON config structure and field mapping from ServerConfig
- MethodChannel/EventChannel method names and payload formats
- Foreground notification channel configuration details
- TUN interface parameters (MTU, IP range)
- ConnectivityManager callback implementation details
- Error handling and retry strategies for connection failures

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture & Platform Bridge
- `.planning/research/ARCHITECTURE.md` — Three-layer bridge pattern (Flutter → Kotlin → Go AAR), platform channel contract, VpnService integration points
- `.planning/research/PITFALLS.md` §Pitfall 1 — VPN shutdown order: stopSelf() MUST precede mInterface.close()
- `.planning/research/PITFALLS.md` §Pitfall 2 — Go-Mobile AAR build fragility, version lock-step
- `.planning/research/STACK.md` — AndroidLibXrayLite AAR API surface: InitCoreEnv, NewCoreController, StartLoop, StopLoop, QueryStats, MeasureDelay

### Feature & Protocol Support
- `.planning/research/FEATURES.md` — Transport support matrix (TCP, WS, gRPC, HTTP/2), connection monitoring features
- `.planning/REQUIREMENTS.md` — ENG-01 through ENG-05, PROTO-01 through PROTO-06, UI-02, MON-01 through MON-04, ROUTE-01, ROUTE-06

### Specification
- `happ_clone_specs.md` §2 — Technical Capabilities: VPN engine, connection management, network handling
- `happ_clone_specs.md` §3 — UI/UX: Dashboard connection state, traffic stats display

### Prior Phase Artifacts
- `.planning/phases/01-foundation-config-import/01-CONTEXT.md` — D-03 circular connect button, D-01 teal color, established patterns
- `lib/features/server/domain/entities/server_config.dart` — ServerConfig entity (source of truth for config fields)
- `lib/features/dashboard/presentation/widgets/connect_button.dart` — Existing connect button widget to extend
- `lib/core/constants/protocol_constants.dart` — ProtocolType enum and protocol constants

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ConnectButton` widget (120dp circle, power icon, currently disabled) — extend with state-based animations
- `ActiveServerCard` widget — already shows selected server info on dashboard
- `TrafficStatsPlaceholder` widget — replace with real-time stats cards
- `ServerConfig` freezed entity — provides all fields needed for Xray JSON config generation
- `ProtocolType` enum — used for protocol-specific config building

### Established Patterns
- Riverpod for state management — connection state should use a `@riverpod` notifier
- go_router for navigation — no changes needed for Phase 2
- Feature-first directory layout — new `connection` feature directory

### Integration Points
- `lib/features/dashboard/` — Connect button, active server card, traffic stats
- `android/app/src/main/kotlin/com/arma/vpn/` — MainActivity, new VpnService class
- `lib/features/server/presentation/providers/active_server_provider.dart` — Active server for connect action

</code_context>

<specifics>
## Specific Ideas

- Connect button animation should match Happ's satisfying power-button press feel
- Traffic stats cards should show formatted speeds (KB/s, MB/s) with ↑↓ arrows
- Notification should update speeds at ~1 second intervals
- The app must request VPN permission from Android on first connect attempt

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-vpn-engine-core-connection*
*Context gathered: 2026-04-05*
