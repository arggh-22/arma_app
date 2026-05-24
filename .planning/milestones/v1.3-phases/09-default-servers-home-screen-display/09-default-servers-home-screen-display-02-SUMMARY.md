---
phase: 09-default-servers-home-screen-display
plan: 02
subsystem: api
tags: [riverpod, retry, cache, dashboard, default-servers]
requires:
  - phase: 09-default-servers-home-screen-display
    provides: Hive cache + deterministic default-server mapper from Plan 01
provides:
  - Dashboard default-server state machine with live fetch, cache fallback, and refresh flags
  - Bounded queued retry flow (1s/2s/4s) for transient manual refresh failures
  - Typed failure enum surface for timeout/offline/auth/server/client/malformed handling
affects: [09-03-PLAN, dashboard, offline-fallback, snackbar-error-copy]
tech-stack:
  added: []
  patterns: [keepAlive notifier state machine, provider-driven retry delay injection]
key-files:
  created:
    - lib/features/dashboard/presentation/providers/default_servers_provider.dart
    - lib/features/dashboard/presentation/providers/default_servers_provider.g.dart
  modified:
    - test/features/dashboard/presentation/providers/default_servers_provider_test.dart
key-decisions:
  - "Default server load state is modeled as synchronous notifier state (items/refresh/offline/failure) instead of AsyncValue wrappers."
  - "Retry queue is foreground-only and bounded to three exponential attempts (1s, 2s, 4s) to satisfy REL-01 without background schedulers."
patterns-established:
  - "Manual refresh never clears visible items; spinner state is orthogonal (`isRefreshing`)."
  - "Retry timing is injectable via provider overrides for deterministic tests."
requirements-completed: [API-02, API-03, REL-01]
duration: 5m
completed: 2026-05-24
---

# Phase 09 Plan 02: Default Servers Home Screen Display Summary

**Dashboard default-server provider now delivers API-first data with offline cache fallback, typed failure metadata, and bounded queued refresh retries.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-24T15:00:33+04:00
- **Completed:** 2026-05-24T15:05:29+04:00
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added a keep-alive dashboard provider state machine for initial load, refresh, cache fallback, and failure typing.
- Preserved API-02 field fidelity (`subscriptionUrl`, `expireDate`) across live and cached item paths.
- Added queued transient retry behavior with bounded exponential backoff and deterministic provider tests.

## Task Commits

1. **Task 1: Build default servers provider state machine (D-10, D-16, D-17, D-19)** - `d8782cf` (test), `b791584` (feat)
2. **Task 2: Add queued refresh retry with exponential backoff (REL-01, D-12, D-18)** - `ab7a1d0` (test), `8347b13` (feat)

## Files Created/Modified
- `lib/features/dashboard/presentation/providers/default_servers_provider.dart` - Dashboard provider state model, load/refresh/cache logic, failure typing, retry queue.
- `lib/features/dashboard/presentation/providers/default_servers_provider.g.dart` - Generated Riverpod provider wiring.
- `test/features/dashboard/presentation/providers/default_servers_provider_test.dart` - Provider coverage for live/cached/error states, refresh visibility, and retry/backoff behavior.

## Decisions Made
- Kept retry queue foreground-scoped and bounded (no background timers/services) to match plan scope and REL-01.
- Exposed retry timing providers so backoff behavior can be tested without real delays.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Added wrapper-tolerant failure handling for provider-thrown API errors**
- **Found during:** Task 1 + Task 2 provider tests
- **Issue:** `defaultServerKeysProvider.future` failures can surface wrapped errors, causing unknown failure classification and skipped retry eligibility.
- **Fix:** Added resilient failure unwrapping/string fallback and conservative transient retry gating when cached offline fallback is active.
- **Files modified:** `lib/features/dashboard/presentation/providers/default_servers_provider.dart`, `test/features/dashboard/presentation/providers/default_servers_provider_test.dart`
- **Verification:** `flutter test test/features/dashboard/presentation/providers/default_servers_provider_test.dart -r compact`; `flutter analyze lib/features/dashboard/presentation/providers/default_servers_provider.dart`
- **Committed in:** `8347b13`

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Required for deterministic failure/retry behavior; no scope creep.

## Issues Encountered
- Riverpod FutureProvider error wrapping made direct ApiClientException classification non-trivial in tests; handled with resilient mapping logic.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Dashboard UI task (09-03) can now bind directly to `defaultServersProvider` for loading/refresh/offline/error rendering.
- Typed failure and retry metadata are ready for snackbar copy mapping and refresh icon spinner states.

## Self-Check: PASSED
- FOUND: `.planning/phases/09-default-servers-home-screen-display/09-default-servers-home-screen-display-02-SUMMARY.md`
- FOUND commits: `d8782cf`, `b791584`, `ab7a1d0`, `8347b13`
