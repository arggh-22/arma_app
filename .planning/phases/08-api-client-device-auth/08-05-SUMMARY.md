---
phase: 08-api-client-device-auth
plan: 05
subsystem: api
tags: [device-auth, hwd, android-id, flutter, testing]
requires:
  - phase: 08-api-client-device-auth
    provides: startup auth bootstrap and provider wiring from plans 08-03/08-04
provides:
  - stable Android HWID resolution using android_id with legacy migration
  - reinstall/update semantics regression coverage for HWID behavior
affects: [09-home-default-server-display, 10-auto-update]
tech-stack:
  added: [android_id]
  patterns:
    - "Prefer stable Android ID semantics over Build.ID-style identifiers."
    - "Treat reinstall/update identity claims as executable tests."
key-files:
  created:
    - test/features/api/data/services/device_id_reinstall_semantics_test.dart
  modified:
    - lib/features/api/data/services/device_id_service.dart
    - test/features/api/data/services/device_id_service_test.dart
    - pubspec.yaml
    - pubspec.lock
key-decisions:
  - "Use android_id plugin for stable Android identifier resolution because device_info_plus removed androidId."
  - "Migrate persisted legacy IDs to stable platform IDs when available; fallback UUID remains persisted-only fallback."
patterns-established:
  - "Resolver-first migration: if stable platform ID exists, overwrite mismatched legacy persisted value once."
  - "Reinstall semantics are proven with isolated datasource environments in tests."
requirements-completed: [API-01, SEC-01]
duration: 7min
completed: 2026-05-23
---

# Phase 08 Plan 05: HWID Gap Closure Summary

**Stable Android HWID migration now uses `android_id`, with reinstall/update semantics enforced by executable tests.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-23T23:49:57Z
- **Completed:** 2026-05-23T23:56:54Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Removed Build.ID-style primary HWID behavior from resolver flow.
- Added one-time migration from legacy stored IDs to stable platform IDs.
- Added reinstall/update semantics tests and deterministic UUID fallback coverage.

## Task Commits

Each task was committed atomically:

1. **Task 1: Harden device identifier strategy and migration**
   - `9d37cb1` (test) RED gate
   - `e3490ee` (feat) GREEN gate
2. **Task 2: Add reinstall/update semantics tests**
   - `f0f86d4` (test)

## Files Created/Modified
- `lib/features/api/data/services/device_id_service.dart` - stable-ID-first resolver with legacy migration and fallback gating.
- `test/features/api/data/services/device_id_service_test.dart` - migration-focused resolver expectations.
- `test/features/api/data/services/device_id_reinstall_semantics_test.dart` - reinstall/update/fallback semantics regression tests.
- `pubspec.yaml` - added `android_id`.
- `pubspec.lock` - locked new dependency.

## Decisions Made
- Switched stable ID retrieval to `android_id` because `device_info_plus` no longer exposes usable `androidId`.
- Kept UUID fallback strictly for stable-ID-unavailable branches and persisted it once.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `android_id` dependency for stable Android identifier**
- **Found during:** Task 1
- **Issue:** `device_info_plus` no longer provides Android ID; current implementation depended on `Build.ID` semantics.
- **Fix:** Added `android_id` package and updated resolver to use it as stable source.
- **Files modified:** `pubspec.yaml`, `pubspec.lock`, `lib/features/api/data/services/device_id_service.dart`
- **Verification:** `flutter test test/features/api/data/services/device_id_service_test.dart -r compact`
- **Committed in:** `e3490ee`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary for correctness; directly aligned with verification gap closure scope.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- HWID behavior now matches stable-ID and migration expectations from verification gap #2.
- Ready for re-verification of Phase 08 truths.

## Self-Check: PASSED
