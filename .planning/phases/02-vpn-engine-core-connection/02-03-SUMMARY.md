---
phase: 02-vpn-engine-core-connection
plan: 03
subsystem: engine
tags: [vpnservice, xray-core, tun, foreground-service, traffic-monitor, network-callback, messenger-ipc, kotlin]

# Dependency graph
requires:
  - phase: 02-01
    provides: "Xray-core AAR integrated, AndroidManifest VpnService declared, geo-routing data bundled"
  - phase: 02-02
    provides: "XrayConfigBuilder.build(ServerConfig) → complete Xray JSON with stats/policy sections"
provides:
  - "XrayCoreManager singleton: Go runtime init, geo asset copy, CoreController factory"
  - "VpnNotificationManager: notification channel + foreground notification builder"
  - "TrafficMonitor: 1-second QueryStats polling with callback"
  - "ArmaVpnService: complete VPN engine with TUN, lifecycle, D-09 shutdown, network resilience"
affects: [02-04, 02-05]

# Tech tracking
tech-stack:
  added: []
  patterns: [Messenger IPC for cross-process communication, ConnectivityManager.requestNetwork with NET_CAPABILITY_NOT_VPN, D-09 shutdown order (stopLoop → stopSelf → close TUN)]

key-files:
  created:
    - android/app/src/main/kotlin/com/arma/vpn/core/XrayCoreManager.kt
    - android/app/src/main/kotlin/com/arma/vpn/notification/VpnNotificationManager.kt
    - android/app/src/main/kotlin/com/arma/vpn/monitor/TrafficMonitor.kt
    - android/app/src/main/kotlin/com/arma/vpn/service/ArmaVpnService.kt
  modified: []

key-decisions:
  - "CoreCallbackHandler requires shutdown() + startup() callbacks (not just onEmitStatus) — discovered during build"
  - "startLoop() takes Int fd (not Long) — AAR API uses native Int for file descriptors"

patterns-established:
  - "VPN process isolation: all Kotlin VPN classes in :vpn_process, communicate via Messenger IPC"
  - "Shutdown order: trafficMonitor.stop → coreController.stopLoop → stopSelf → tunInterface.close (D-09)"
  - "Network resilience: requestNetwork with NET_CAPABILITY_NOT_VPN, setUnderlyingNetworks on change"
  - "Foreground notification: channel creation in onCreate, buildNotification + startForeground before TUN setup"

requirements-completed: [ENG-01, ENG-05, MON-03, MON-04]

# Metrics
duration: 5min
completed: 2026-04-05
---

# Phase 02 Plan 03: VPN Engine — VpnService + Core Manager + Notification + Traffic Monitor Summary

**Four Kotlin classes forming the complete VPN engine in :vpn_process — ArmaVpnService with TUN/IPv4/IPv6, D-09 shutdown order, Messenger IPC, foreground notification with traffic speeds, and network resilience via NET_CAPABILITY_NOT_VPN callback**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-05T10:57:46Z
- **Completed:** 2026-04-05T11:02:46Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- ArmaVpnService with complete VPN lifecycle: TUN setup (MTU 9000, IPv4/IPv6, self-exclusion), Xray-core start/stop, foreground notification, traffic monitoring, network callback
- D-09 shutdown order enforced: stopLoop → stopSelf → close TUN fd (prevents port-in-use errors on reconnect)
- XrayCoreManager singleton with Go runtime init (Seq.setContext), geo asset copy, and CoreController factory
- VpnNotificationManager with LOW importance channel and persistent notification showing status/server/speeds
- TrafficMonitor polling QueryStats("proxy", "uplink/downlink") every 1 second
- Messenger IPC for cross-process communication between main process and :vpn_process
- Network resilience: ConnectivityManager.requestNetwork with NET_CAPABILITY_NOT_VPN, setUnderlyingNetworks on change
- Build verified: `flutter build apk --debug` compiles successfully

## Task Commits

Each task was committed atomically:

1. **Task 1: XrayCoreManager + VpnNotificationManager + TrafficMonitor** - `794eb54` (feat)
2. **Task 2: ArmaVpnService with TUN, lifecycle, shutdown order, network callback** - `74bb99b` (feat)

## Files Created/Modified
- `android/app/src/main/kotlin/com/arma/vpn/core/XrayCoreManager.kt` - Go runtime init, geo asset copy, CoreController factory (singleton)
- `android/app/src/main/kotlin/com/arma/vpn/notification/VpnNotificationManager.kt` - Notification channel + foreground notification builder
- `android/app/src/main/kotlin/com/arma/vpn/monitor/TrafficMonitor.kt` - 1-second QueryStats polling with callback
- `android/app/src/main/kotlin/com/arma/vpn/service/ArmaVpnService.kt` - Complete VpnService: TUN, lifecycle, shutdown, IPC, network callback

## Decisions Made
- **CoreCallbackHandler API:** AAR requires `shutdown()` and `startup()` callbacks in addition to `onEmitStatus()` — discovered during build compilation. Both return 0 (no-op, used for lifecycle logging).
- **startLoop fd type:** AAR's `startLoop(config, tunFd)` takes `Int` (not `Long`) for the file descriptor — fixed during build verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CoreCallbackHandler missing shutdown/startup callbacks**
- **Found during:** Task 2 (ArmaVpnService implementation)
- **Issue:** Plan only showed `onEmitStatus` callback, but AAR's CoreCallbackHandler interface also requires `shutdown(): Long` and `startup(): Long` abstract methods
- **Fix:** Added both callbacks returning 0 with debug logging
- **Files modified:** android/app/src/main/kotlin/com/arma/vpn/service/ArmaVpnService.kt
- **Verification:** `flutter build apk --debug` compiles successfully
- **Committed in:** `74bb99b` (Task 2 commit)

**2. [Rule 1 - Bug] startLoop() expects Int, not Long for TUN fd**
- **Found during:** Task 2 (ArmaVpnService implementation)
- **Issue:** Plan used `tunInterface!!.fd.toLong()` but AAR API expects `Int` parameter
- **Fix:** Changed to `tunInterface!!.fd` (already Int from ParcelFileDescriptor)
- **Files modified:** android/app/src/main/kotlin/com/arma/vpn/service/ArmaVpnService.kt
- **Verification:** `flutter build apk --debug` compiles successfully
- **Committed in:** `74bb99b` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs — AAR API signature mismatches in plan)
**Impact on plan:** Both auto-fixes necessary for compilation. No scope creep — just corrected AAR API signatures that differed from research assumptions.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- VPN engine is fully implemented and compiles — ready for platform channel bridge (Plan 04)
- Messenger IPC constants (MSG_*) ready for use by platform channel bridge
- ArmaVpnService ACTION_START/STOP + EXTRA_CONFIG/EXTRA_SERVER_NAME ready for intent-based start
- TrafficMonitor + VpnNotificationManager ready to receive live data from running core
- Note: VPN cannot be started yet from Flutter — Plan 04 builds the MethodChannel/EventChannel bridge

---
*Phase: 02-vpn-engine-core-connection*
*Completed: 2026-04-05*

## Self-Check: PASSED

All 4 created files verified present. Both task commits (794eb54, 74bb99b) verified in git log. Build verified with `flutter build apk --debug`.
