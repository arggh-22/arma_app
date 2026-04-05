---
phase: 02-vpn-engine-core-connection
plan: 04
subsystem: engine
tags: [platform-channels, methodchannel, eventchannel, messenger-ipc, riverpod, connection-state, traffic-stats, vpn-permission]

# Dependency graph
requires:
  - phase: 02-02
    provides: "XrayConfigBuilder.build(ServerConfig) → complete Xray JSON config string"
  - phase: 02-03
    provides: "ArmaVpnService with Messenger IPC, MSG_* constants, ACTION_* constants"
provides:
  - "VpnServiceConnection: Messenger IPC bridge between main process and VPN process"
  - "MainActivity: MethodChannel (com.arma.vpn/method) + EventChannel (com.arma.vpn/vpn_status) + VPN permission flow"
  - "ConnectionNotifier: Riverpod keepAlive provider with connect/disconnect state machine"
  - "TrafficStatsNotifier: Riverpod keepAlive provider streaming uplink/downlink stats"
  - "VpnPlatformService: Dart wrapper for native platform channels"
  - "ConnectionStatus: sealed class with 4 states (Disconnected/Connecting/Connected/Disconnecting)"
  - "TrafficStats: data class with uplinkBytesPerSecond/downlinkBytesPerSecond"
affects: [02-05]

# Tech tracking
tech-stack:
  added: []
  patterns: [Two-hop IPC bridge (Flutter ↔ MainActivity ↔ VpnService), Sealed class state machine, keepAlive Riverpod notifier for connection lifecycle]

key-files:
  created:
    - android/app/src/main/kotlin/com/arma/vpn/ipc/ServiceConnection.kt
    - lib/features/connection/domain/entities/connection_status.dart
    - lib/features/connection/domain/entities/traffic_stats.dart
    - lib/features/connection/data/datasources/vpn_platform_service.dart
    - lib/features/connection/presentation/providers/connection_provider.dart
    - lib/features/connection/presentation/providers/connection_provider.g.dart
    - lib/features/connection/presentation/providers/traffic_stats_provider.dart
    - lib/features/connection/presentation/providers/traffic_stats_provider.g.dart
  modified:
    - android/app/src/main/kotlin/com/arma/vpn/MainActivity.kt

key-decisions:
  - "VpnServiceConnection uses Handler(Looper.getMainLooper()) for thread-safe Messenger callbacks"
  - "EventChannel events forwarded via runOnUiThread to ensure Flutter thread safety"
  - "ConnectionNotifier syncs with native isRunning on build() to handle app resume after process death"
  - "TrafficStats uses num?.toInt() casting for platform channel int/long compatibility"

patterns-established:
  - "Two-hop IPC: Flutter EventChannel ← runOnUiThread ← VpnServiceConnection ← Messenger ← ArmaVpnService"
  - "VPN permission: VpnService.prepare() → startActivityForResult → onActivityResult → MethodChannel.Result"
  - "Connection state machine: sealed class with switch-based event handling from EventChannel"
  - "Platform service pattern: static const channels with async method wrappers"

requirements-completed: [ENG-03, ENG-04, MON-01, MON-02]

# Metrics
duration: 3min
completed: 2026-04-05
---

# Phase 02 Plan 04: Flutter ↔ Native Platform Channel Bridge + Connection State Management Summary

**Two-hop IPC bridge (Flutter ↔ MainActivity ↔ VpnService) with MethodChannel commands, EventChannel streaming, VPN permission flow, and Riverpod connection state machine + traffic stats providers — flutter analyze clean, APK builds**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-05T11:06:14Z
- **Completed:** 2026-04-05T11:09:38Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- VpnServiceConnection: Messenger-based IPC bridge with sendStart/sendStop/queryIsRunning between main process and :vpn_process
- MainActivity: MethodChannel "com.arma.vpn/method" with startVpn/stopVpn/isRunning/requestVpnPermission handlers
- MainActivity: EventChannel "com.arma.vpn/vpn_status" streaming connection status + traffic stats to Flutter
- VPN permission flow: VpnService.prepare() → startActivityForResult → onActivityResult → MethodChannel.Result
- Service binding with BIND_AUTO_CREATE on configureFlutterEngine for early IPC setup
- ConnectionStatus sealed class with 4 states: Disconnected, Connecting, Connected, Disconnecting
- TrafficStats data class with uplinkBytesPerSecond/downlinkBytesPerSecond and zero constant
- VpnPlatformService: Dart-side MethodChannel/EventChannel wrapper with type-safe async methods
- ConnectionNotifier: Riverpod keepAlive provider managing full connect/disconnect state machine
- ConnectionNotifier syncs with native isRunning on build() for app resume resilience (T-02-14 mitigation)
- ConnectionNotifier checks VPN permission result and sets clear error state (T-02-15 mitigation)
- TrafficStatsNotifier: Riverpod keepAlive provider streaming real-time uplink/downlink stats from EventChannel
- XrayConfigBuilder.build() called from ConnectionNotifier.connect() — all config logic stays in Dart (D-02)
- flutter analyze passes with no issues
- flutter build apk --debug compiles successfully (full native + Dart build)

## Task Commits

Each task was committed atomically:

1. **Task 1: IPC ServiceConnection + MainActivity platform channels** - `60820bb` (feat)
2. **Task 2: Dart connection entities + platform service + Riverpod providers** - `6513312` (feat)

## Files Created/Modified
- `android/app/src/main/kotlin/com/arma/vpn/ipc/ServiceConnection.kt` - Messenger IPC bridge (VpnServiceConnection class)
- `android/app/src/main/kotlin/com/arma/vpn/MainActivity.kt` - MethodChannel + EventChannel + VPN permission + service binding
- `lib/features/connection/domain/entities/connection_status.dart` - Sealed class: Disconnected/Connecting/Connected/Disconnecting
- `lib/features/connection/domain/entities/traffic_stats.dart` - TrafficStats data class with zero constant
- `lib/features/connection/data/datasources/vpn_platform_service.dart` - Platform channel wrapper (startVpn/stopVpn/isRunning/requestVpnPermission/vpnEvents)
- `lib/features/connection/presentation/providers/connection_provider.dart` - ConnectionNotifier with state machine + native sync
- `lib/features/connection/presentation/providers/connection_provider.g.dart` - Generated connectionProvider
- `lib/features/connection/presentation/providers/traffic_stats_provider.dart` - TrafficStatsNotifier streaming stats
- `lib/features/connection/presentation/providers/traffic_stats_provider.g.dart` - Generated trafficStatsProvider

## Decisions Made
- **Thread safety:** VpnServiceConnection uses `Handler(Looper.getMainLooper())` for incoming Messenger messages; EventChannel events forwarded via `runOnUiThread` to ensure Flutter thread safety.
- **Native sync on resume:** ConnectionNotifier calls `_syncWithNative()` in build() to handle app resume after process death — checks `isRunning` and restores Connected state if service is still active (T-02-14 mitigation).
- **Platform channel casting:** TrafficStats uses `(event['uplink'] as num?)?.toInt()` for safe int/long compatibility across the platform channel boundary.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Complete Flutter ↔ Kotlin ↔ VPN process bridge is operational
- ConnectionNotifier ready to be used by dashboard connect button (Plan 05)
- TrafficStatsNotifier ready to feed traffic stats widgets (Plan 05)
- VPN permission flow handles first-connect dialog automatically
- Note: UI integration (connect button, traffic cards, timer) is Plan 05 scope

---
*Phase: 02-vpn-engine-core-connection*
*Completed: 2026-04-05*

## Self-Check: PASSED

All 9 created/modified files verified present. Both task commits (60820bb, 6513312) verified in git log. Build verified with `flutter build apk --debug`.
