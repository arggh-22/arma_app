---
phase: 02-vpn-engine-core-connection
verified: 2026-04-05T11:21:25Z
status: human_needed
score: 5/5 must-haves verified
human_verification:
  - test: "Tap the connect button on the dashboard with a server configured and verify VPN connection establishes via Android VpnService"
    expected: "System VPN permission dialog appears on first tap; after granting, button transitions from grey → pulsing teal → solid teal glow; status text changes from 'Not Connected' → 'Connecting...' → 'Connected' with color coding"
    why_human: "Requires a running Android device/emulator with a real proxy server to test actual VPN connectivity through Xray-core AAR"
  - test: "While connected, observe the connection timer and traffic stats cards"
    expected: "Timer counts up in HH:MM:SS format; traffic stats show non-zero ↑ upload and ↓ download speeds updating every ~1 second"
    why_human: "Real-time data flow requires actual network traffic through the VPN tunnel"
  - test: "While connected, switch between WiFi and cellular data (or disconnect/reconnect WiFi)"
    expected: "VPN stays connected through network change without user action; connection resumes after brief network interruption"
    why_human: "Network change resilience requires physical device with WiFi and cellular radios"
  - test: "While connected, pull down notification shade"
    expected: "Persistent foreground notification shows 'Arma VPN — [server name]' with '↓ X.X KB/s  ↑ X.X KB/s' real-time speed display; tapping notification opens app"
    why_human: "Android notification rendering and interaction cannot be verified programmatically"
  - test: "Verify connect button animation feel matches Happ-style satisfying power button (D-03)"
    expected: "Pulsing scale + shimmer animation during connecting state feels smooth and responsive; solid teal glow on connected state has visible box shadow"
    why_human: "Visual animation quality and 'feel' is subjective and requires human judgment"
---

# Phase 2: VPN Engine & Core Connection Verification Report

**Phase Goal:** Users can connect to their proxy servers with a single tap and monitor the live connection
**Verified:** 2026-04-05T11:21:25Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can tap the connect button and establish a VPN connection through their selected server via Android VpnService (TUN mode) | ✓ VERIFIED | ConnectButton watches `connectionProvider` + `activeServerProvider`, calls `connect(activeServer)` on tap. ConnectionNotifier.connect() → requests permission → builds Xray config → calls startVpn via MethodChannel → MainActivity starts ArmaVpnService → VpnService creates TUN interface with IPv4/IPv6 routes + starts Xray-core via `startLoop(config, tunFd)`. Full chain verified in code. |
| 2 | User sees clear connection state transitions (Disconnected → Connecting → Connected with color coding) and a live connection duration timer | ✓ VERIFIED | `ConnectionStatus` sealed class with 4 states. DashboardScreen renders status text with color-coded switch (grey/primary/green). ConnectButton shows grey→pulsing teal→solid teal glow via AnimatedContainer + flutter_animate. ConnectionTimer uses `Timer.periodic` with HH:MM:SS format, drift-free via `DateTime.now().difference(connectedAt)`. |
| 3 | User can connect using VLESS (Reality/XTLS-Vision), VMess, Trojan, or Shadowsocks over TCP, WS, gRPC, or HTTP/2 transports | ✓ VERIFIED | XrayConfigBuilder handles all 4 protocols with correct settings (VLESS/VMess→vnext[], Trojan/SS→servers[]). Reality→realitySettings (not tlsSettings). Flow gating: VLESS+TCP+(TLS\|Reality) only. All 4 transports produce correct streamSettings. H2 forces TLS. 407-line test file covers all combinations. 21 tests pass. |
| 4 | Dashboard shows real-time upload/download speeds, and foreground notification displays connection status and current traffic speeds | ✓ VERIFIED | TrafficStatsCard watches `trafficStatsProvider`, renders ↓/↑ with `formatSpeed()`. TrafficMonitor polls QueryStats every 1000ms, sends bytes via Messenger IPC → EventChannel → TrafficStatsNotifier. VpnNotificationManager.buildNotification() shows "↓ speed  ↑ speed" content text. updateNotification() called from TrafficMonitor callback. |
| 5 | VPN auto-reconnects on network changes (WiFi ↔ cellular), bypasses LAN traffic by default, and uses split DNS (remote for proxied domains, direct for local) to prevent leaks | ✓ VERIFIED | ArmaVpnService registers NetworkCallback with NET_CAPABILITY_NOT_VPN, calls setUnderlyingNetworks() on change. Xray config routing: geoip:private + geosite:private → direct. DNS: 1.1.1.1 for proxied + localhost for local. TUN excludes self via addDisallowedApplication(packageName). |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `android/app/libs/libv2ray.aar` | Xray-core engine AAR | ✓ VERIFIED | 55,689,824 bytes (~53MB), valid binary |
| `android/app/src/main/assets/geoip.dat` | IP routing database | ✓ VERIFIED | 19,765,896 bytes (~18.8MB) |
| `android/app/src/main/assets/geosite.dat` | Domain routing database | ✓ VERIFIED | 10,564,711 bytes (~10MB) |
| `android/app/build.gradle.kts` | AAR dependency + useLegacyPackaging | ✓ VERIFIED | fileTree AAR dep + useLegacyPackaging=true present |
| `android/app/src/main/AndroidManifest.xml` | VpnService + permissions | ✓ VERIFIED | 6 permissions, ArmaVpnService in :vpn_process with BIND_VPN_SERVICE, SUPPORTS_ALWAYS_ON, specialUse, PROPERTY_SPECIAL_USE_FGS_SUBTYPE |
| `android/app/src/main/res/drawable/ic_vpn_key.xml` | Notification icon | ✓ VERIFIED | Material vpn_key vector drawable, 10 lines |
| `lib/xray/xray_config_builder.dart` | Config builder (≥150 lines) | ✓ VERIFIED | 290 lines, handles 4 protocols × 4 transports × 3 TLS modes |
| `lib/xray/formatters/speed_formatter.dart` | Speed formatter | ✓ VERIFIED | 17 lines, B/s → KB/s → MB/s → GB/s formatting |
| `android/app/src/main/kotlin/com/arma/vpn/core/XrayCoreManager.kt` | Go runtime init + controller factory | ✓ VERIFIED | 89 lines, go.Seq.setContext, copyAssetsToInternal, initCoreEnv, createController |
| `android/app/src/main/kotlin/com/arma/vpn/notification/VpnNotificationManager.kt` | Notification channel + builder | ✓ VERIFIED | 84 lines, CHANNEL_ID, createNotificationChannel, buildNotification with status/server/speeds |
| `android/app/src/main/kotlin/com/arma/vpn/monitor/TrafficMonitor.kt` | 1-sec QueryStats polling | ✓ VERIFIED | 55 lines, Timer scheduleAtFixedRate 1000ms, queryStats("proxy","uplink"/"downlink") |
| `android/app/src/main/kotlin/com/arma/vpn/service/ArmaVpnService.kt` | VpnService with TUN + lifecycle | ✓ VERIFIED | 395 lines, TUN IPv4/IPv6, D-09 shutdown, Messenger IPC, NetworkCallback |
| `android/app/src/main/kotlin/com/arma/vpn/ipc/ServiceConnection.kt` | Messenger IPC bridge | ✓ VERIFIED | 95 lines, VpnServiceConnection with sendStart/sendStop/queryIsRunning |
| `android/app/src/main/kotlin/com/arma/vpn/MainActivity.kt` | MethodChannel + EventChannel | ✓ VERIFIED | 158 lines, startVpn/stopVpn/isRunning/requestVpnPermission methods, EventChannel streaming |
| `lib/features/connection/domain/entities/connection_status.dart` | Sealed connection states | ✓ VERIFIED | 32 lines, 4 states: Disconnected, Connecting, Connected, Disconnecting |
| `lib/features/connection/domain/entities/traffic_stats.dart` | Traffic stats data class | ✓ VERIFIED | 15 lines, uplinkBytesPerSecond + downlinkBytesPerSecond |
| `lib/features/connection/data/datasources/vpn_platform_service.dart` | Platform channel wrapper | ✓ VERIFIED | 51 lines, MethodChannel + EventChannel, startVpn/stopVpn/isRunning/requestVpnPermission/vpnEvents |
| `lib/features/connection/presentation/providers/connection_provider.dart` | Connection state machine | ✓ VERIFIED | 127 lines, @Riverpod(keepAlive: true), connect/disconnect/syncWithNative, EventChannel listener |
| `lib/features/connection/presentation/providers/traffic_stats_provider.dart` | Traffic stats streaming | ✓ VERIFIED | 39 lines, @Riverpod(keepAlive: true), EventChannel stats listener |
| `lib/features/dashboard/presentation/widgets/connect_button.dart` | Animated connect button | ✓ VERIFIED | 122 lines, ConsumerWidget, 4-state visual switch, flutter_animate shimmer + scale |
| `lib/features/connection/presentation/widgets/connection_timer.dart` | HH:MM:SS timer | ✓ VERIFIED | 66 lines, ConsumerStatefulWidget, Timer.periodic, drift-free via DateTime.now().difference |
| `lib/features/connection/presentation/widgets/traffic_stats_card.dart` | Upload/download speed cards | ✓ VERIFIED | 76 lines, ↓ green + ↑ blue side-by-side cards with formatSpeed() |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Wired dashboard screen | ✓ VERIFIED | 81 lines, ConnectButton + status text + ConnectionTimer + ActiveServerCard + TrafficStatsCard |
| `test/xray/xray_config_builder_test.dart` | Config builder tests (≥100 lines) | ✓ VERIFIED | 407 lines, comprehensive protocol/transport/TLS test coverage |
| `test/xray/speed_formatter_test.dart` | Speed formatter tests | ✓ VERIFIED | 30 lines |
| `connection_provider.g.dart` | Generated Riverpod code | ✓ VERIFIED | 104 lines, RiverpodGenerator output |
| `traffic_stats_provider.g.dart` | Generated Riverpod code | ✓ VERIFIED | 88 lines, RiverpodGenerator output |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| ConnectButton | connectionProvider | ref.watch(connectionProvider) | ✓ WIRED | 3 references in connect_button.dart |
| ConnectButton | activeServerProvider | ref.watch(activeServerProvider) | ✓ WIRED | 1 import + usage |
| ConnectionTimer | connectionProvider | ref.listen(connectionProvider) | ✓ WIRED | Listens for state changes |
| TrafficStatsCard | trafficStatsProvider | ref.watch(trafficStatsProvider) | ✓ WIRED | 2 references |
| TrafficStatsCard | formatSpeed() | import + call | ✓ WIRED | 3 references |
| DashboardScreen | ConnectButton | import + usage | ✓ WIRED | Directly embedded in Column |
| DashboardScreen | ConnectionTimer | import + usage | ✓ WIRED | Directly embedded in Column |
| DashboardScreen | TrafficStatsCard | import + usage | ✓ WIRED | Directly embedded in Column |
| DashboardScreen | connectionProvider | ref.watch | ✓ WIRED | For status text rendering |
| ConnectionProvider | VpnPlatformService | instantiation + method calls | ✓ WIRED | startVpn, stopVpn, isRunning, requestVpnPermission, vpnEvents |
| ConnectionProvider | XrayConfigBuilder | import + XrayConfigBuilder.build(server) | ✓ WIRED | Config built in connect() before startVpn |
| XrayConfigBuilder | ServerConfig | import + parameter type | ✓ WIRED | build(ServerConfig server) parameter |
| XrayConfigBuilder | ProtocolConstants | import + switch on ProtocolType | ✓ WIRED | Protocol dispatch in _buildProtocolSettings |
| MainActivity | VpnServiceConnection | instantiation + method calls | ✓ WIRED | 3 references, IPC bridge |
| MainActivity | ArmaVpnService | Intent + service binding | ✓ WIRED | 8 references, startForegroundService + bindService |
| ArmaVpnService | XrayCoreManager | initialize() + createController() | ✓ WIRED | 3 references |
| ArmaVpnService | VpnNotificationManager | createNotificationChannel + buildNotification | ✓ WIRED | 6 references |
| ArmaVpnService | TrafficMonitor | construction + start/stop | ✓ WIRED | 3 references |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| ConnectButton | `status` via connectionProvider | EventChannel from ArmaVpnService Messenger IPC | Yes — native VPN state events | ✓ FLOWING (pending runtime confirmation) |
| ConnectionTimer | `_elapsed` via connectionProvider | Connected.connectedAt from EventChannel event | Yes — timestamp captured at connection | ✓ FLOWING |
| TrafficStatsCard | `stats` via trafficStatsProvider | EventChannel from TrafficMonitor → QueryStats | Yes — polls Xray-core every 1s | ✓ FLOWING (pending runtime confirmation) |
| DashboardScreen | `status` via connectionProvider | Same as ConnectButton | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Config builder produces valid JSON for VLESS+TCP+Reality | Tests run by orchestrator | 21/21 tests pass | ✓ PASS |
| Speed formatter handles edge cases | Tests run by orchestrator | All pass | ✓ PASS |
| Phase 1 regression | Tests run by orchestrator | 69/69 pass | ✓ PASS |
| AAR binary exists and is valid size | `ls -la libv2ray.aar` | 55,689,824 bytes (~53MB) | ✓ PASS |
| Geo databases bundled | `ls -la geo*.dat` | geoip: 18.8MB, geosite: 10MB | ✓ PASS |
| All 6 permissions in manifest | grep count checks | All return 1 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| ENG-01 | 02-01, 02-03 | Xray-core via Go-Mobile AAR with VpnService TUN mode | ✓ SATISFIED | AAR integrated, ArmaVpnService with TUN interface |
| ENG-02 | 02-02 | Valid Xray JSON config generation | ✓ SATISFIED | XrayConfigBuilder 290 lines, 21 tests passing |
| ENG-03 | 02-04 | Single-tap connect/disconnect from dashboard | ✓ SATISFIED | ConnectButton → ConnectionNotifier → MethodChannel → Service |
| ENG-04 | 02-04 | Clear connection state display with color coding | ✓ SATISFIED | Sealed class + DashboardScreen color-coded status text |
| ENG-05 | 02-01, 02-03 | Foreground service with persistent notification | ✓ SATISFIED | VpnNotificationManager + startForeground() in ArmaVpnService |
| PROTO-01 | 02-02 | VLESS with Reality and XTLS-Vision | ✓ SATISFIED | vnext[], realitySettings, flow gating for VLESS+TCP+(TLS\|Reality) |
| PROTO-02 | 02-02 | VMess protocol | ✓ SATISFIED | vnext[] with alterId + security auto mapping |
| PROTO-03 | 02-02 | Trojan protocol | ✓ SATISFIED | servers[] with password |
| PROTO-04 | 02-02 | Shadowsocks protocol | ✓ SATISFIED | servers[] with method + password, scheme 'ss' → 'shadowsocks' |
| PROTO-06 | 02-02 | TCP, WS, gRPC, HTTP/2 transports | ✓ SATISFIED | All 4 transport settings generated in _buildStreamSettings |
| UI-02 | 02-05 | Prominent connect button with visual feedback | ✓ SATISFIED | 120dp AnimatedContainer, flutter_animate shimmer+scale, 4 visual states |
| MON-01 | 02-04, 02-05 | Real-time upload/download speeds | ✓ SATISFIED | TrafficStatsCard with formatSpeed(), updated via EventChannel |
| MON-02 | 02-04, 02-05 | Connection duration timer | ✓ SATISFIED | ConnectionTimer HH:MM:SS, Timer.periodic 1s |
| MON-03 | 02-03 | Notification displays status and speeds | ✓ SATISFIED | buildNotification with "↓ speed  ↑ speed" content, updated per poll |
| MON-04 | 02-03 | Auto-reconnect on network changes | ✓ SATISFIED | NetworkCallback with NET_CAPABILITY_NOT_VPN, setUnderlyingNetworks |
| ROUTE-01 | 02-02 | LAN bypass by default | ✓ SATISFIED | geoip:private + geosite:private → direct routing rules |
| ROUTE-06 | 02-02 | Split DNS (no DNS leaks) | ✓ SATISFIED | 1.1.1.1 for proxied + localhost for local |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `android/app/build.gradle.kts` | 23 | TODO: Specify application ID | ℹ️ Info | Pre-existing from Phase 1, applicationId already changed to com.arma.vpn |
| `android/app/build.gradle.kts` | 35 | TODO: Add signing config for release | ℹ️ Info | Pre-existing from Phase 1, expected for later milestone |

No blockers or warnings found. Zero TODO/FIXME/PLACEHOLDER/stub patterns in any Phase 2 code.

### Human Verification Required

### 1. Full VPN Connection End-to-End

**Test:** Configure a real proxy server, tap the connect button, and verify VPN traffic flows
**Expected:** VPN permission dialog → connecting animation → connected state → internet works through VPN tunnel → notification shows speeds
**Why human:** Requires a physical/emulated Android device with network access and a real proxy server endpoint

### 2. Connection State Visual Transitions (D-03)

**Test:** Watch the connect button animation through all 4 states
**Expected:** Grey → pulsing teal with shimmer → solid teal glow with box shadow → grey on disconnect
**Why human:** Animation quality, smoothness, and "feel" are subjective visual assessments

### 3. Network Change Resilience (D-10)

**Test:** While connected, toggle WiFi on/off or switch between WiFi and cellular
**Expected:** VPN stays connected or silently reconnects; no user action needed
**Why human:** Requires physical device with WiFi and cellular radios to test network switching

### 4. Foreground Notification (D-07)

**Test:** While connected, check the notification shade
**Expected:** Persistent notification with "Arma VPN — [server]" title, "↓ speed  ↑ speed" content, tapping opens app
**Why human:** Android notification rendering and interaction require device testing

### 5. Real-Time Traffic Stats Accuracy

**Test:** Browse the web while connected and watch traffic stats cards
**Expected:** Download and upload speed values update in real-time (~1s), values correlate with actual network activity
**Why human:** Requires actual network traffic and subjective accuracy assessment

### Gaps Summary

**No code gaps found.** All 23 artifacts exist, are substantive (no stubs, no placeholders, no empty implementations), and are fully wired through the entire data flow chain:

- **Layer 1 (Native Foundation):** AAR (53MB) + geo data (29MB) + AndroidManifest with all permissions and VpnService declaration
- **Layer 2 (Dart Config):** 290-line config builder covering 4×4×3 matrix + speed formatter with 21 passing tests
- **Layer 3 (Native Engine):** 4 Kotlin classes (ArmaVpnService, XrayCoreManager, VpnNotificationManager, TrafficMonitor) with proper shutdown order, TUN setup, network resilience
- **Layer 4 (IPC Bridge):** Messenger IPC (ServiceConnection) + Flutter platform channels (MethodChannel + EventChannel) + connection state machine (ConnectionNotifier) + traffic streaming (TrafficStatsNotifier)
- **Layer 5 (UI):** ConnectButton with 4-state animation, ConnectionTimer HH:MM:SS, TrafficStatsCard with live speeds, DashboardScreen fully wired to live providers

All 12 user decisions from 02-CONTEXT.md (D-01 through D-12) have been honored in the implementation. All 17 requirement IDs are satisfied in code. The only remaining verification is runtime behavior on an actual Android device.

---

_Verified: 2026-04-05T11:21:25Z_
_Verifier: the agent (gsd-verifier)_
