---
phase: 03-subscriptions-server-intelligence
plan: 03
subsystem: server
tags: [latency, measure-delay, xray-core, riverpod, kotlin-coroutines, auto-select, auto-fallback]

# Dependency graph
requires:
  - phase: 02-vpn-engine
    provides: "MethodChannel bridge, VpnPlatformService, XrayConfigBuilder, ConnectionNotifier"
provides:
  - "measureDelay MethodChannel handler (Kotlin → Go AAR)"
  - "VpnPlatformService.measureDelay Dart wrapper"
  - "LatencyNotifier with individual + bulk testing (concurrency 3)"
  - "bestServer reactive provider and selectBestServer pure function"
  - "ConnectionNotifier auto-fallback on error (D-17)"
affects: [server-ui, dashboard, settings]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Coroutine-based MethodChannel handler: Dispatchers.IO for blocking Go calls, result on Dispatchers.Main"
    - "Sentinel values in state map: -2 = testing, -1 = failed, >0 = ms"
    - "Batch-concurrent async: process list in chunks of 3 with Future.wait"
    - "Auto-fallback with bounded retry counter to prevent infinite loops"

key-files:
  created:
    - "lib/features/server/presentation/providers/latency_provider.dart"
    - "lib/features/server/presentation/providers/best_server_provider.dart"
  modified:
    - "android/app/src/main/kotlin/com/arma/vpn/MainActivity.kt"
    - "lib/features/connection/data/datasources/vpn_platform_service.dart"
    - "lib/features/connection/presentation/providers/connection_provider.dart"

key-decisions:
  - "Fallback bounded to 3 attempts max to prevent infinite reconnection loops"
  - "isManual parameter on connect() preserves fallback counter during auto-retry"
  - "selectBestServer as pure function (not provider) for reuse in auto-fallback"

patterns-established:
  - "Sentinel state values: -2 (testing), -1 (failed), positive (ms result)"
  - "Batched concurrency: process N items in chunks of 3 with Future.wait"
  - "Bounded auto-retry: counter + max constant, reset on manual action or success"

requirements-completed: [SERV-03, SERV-04, SERV-09]

# Metrics
duration: 4min
completed: 2026-04-05
---

# Phase 03 Plan 03: Latency Testing & Auto-Select Summary

**MeasureDelay pipeline from Go AAR through Kotlin coroutine to Dart async method, with bulk testing (concurrency 3), auto-select best server, and connection auto-fallback on failure**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-05T16:20:03Z
- **Completed:** 2026-04-05T16:24:13Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Bridged Xray-core's `measureOutboundDelay` from Go AAR through Kotlin MethodChannel to Dart
- Built LatencyNotifier with individual server test and bulk test (batched concurrency of 3)
- Created best server auto-select algorithm (lowest latency, excludable servers)
- Added connection auto-fallback to next best server when current server fails (D-17)
- Bounded fallback to 3 attempts to prevent infinite reconnection loops

## Task Commits

Each task was committed atomically:

1. **Task 1: Add measureDelay to Kotlin MethodChannel + Dart platform service** - `8f5c85f` (feat)
2. **Task 2: Latency provider + best server auto-select + connection auto-fallback** - `188cbb2` (feat)

## Files Created/Modified
- `android/app/src/main/kotlin/com/arma/vpn/MainActivity.kt` - Added measureDelay MethodChannel handler with coroutine IO dispatch
- `lib/features/connection/data/datasources/vpn_platform_service.dart` - Added measureDelay Dart wrapper returning int ms or -1 on failure
- `lib/features/server/presentation/providers/latency_provider.dart` - LatencyNotifier with testServer() and testAllServers() (concurrency 3)
- `lib/features/server/presentation/providers/best_server_provider.dart` - Reactive bestServer provider + selectBestServer pure function
- `lib/features/connection/presentation/providers/connection_provider.dart` - Added auto-fallback with bounded retry on error events

## Decisions Made
- Bounded auto-fallback to 3 consecutive attempts to prevent infinite reconnection loops (Rule 1 proactive fix)
- Added `isManual` parameter to `connect()` to distinguish user-initiated vs auto-fallback connections — ensures fallback counter is preserved during auto-retry
- `selectBestServer` implemented as a pure function (not a provider) so it can be called from ConnectionNotifier without circular provider dependencies

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added bounded fallback counter to prevent infinite reconnection loops**
- **Found during:** Task 2 (Auto-fallback implementation)
- **Issue:** Plan's auto-fallback calls `connect()` which resets the counter, and if all servers fail, creates infinite retry loop
- **Fix:** Added `_fallbackAttempts` counter with max 3, `isManual` parameter on `connect()` to only reset on user action, and reset on successful connection
- **Files modified:** `lib/features/connection/presentation/providers/connection_provider.dart`
- **Verification:** Counter increments on each fallback, stops at 3, resets on manual connect or successful connection
- **Committed in:** `188cbb2` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug prevention)
**Impact on plan:** Essential for correctness — prevents infinite loop that would drain battery and flood server. No scope creep.

## Issues Encountered
- System dart SDK (3.10.7) too old for project — used `flutter pub run build_runner` per Phase 03 decision

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Latency testing pipeline fully operational: Kotlin ↔ Dart ↔ Provider
- Ready for server list UI integration (latency display, test buttons, sort-by-latency)
- Auto-fallback wired into connection error handling — transparent to user

---
*Phase: 03-subscriptions-server-intelligence*
*Completed: 2026-04-05*
