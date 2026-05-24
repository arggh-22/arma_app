---
phase: 09-default-servers-home-screen-display
plan: 04
subsystem: storage
tags: [hive, riverpod, startup, regression]
requires:
  - phase: 09-default-servers-home-screen-display
    provides: dashboard default-server provider and cache fallback flow
provides:
  - startup Hive bootstrap entrypoint that opens default_server_cache before provider reads
  - main startup wiring that awaits storage bootstrap before runApp
  - regression test proving API failure path returns provider state without ProviderException/HiveError
affects: [dashboard, api, app-startup]
tech-stack:
  added: []
  patterns: [centralized Hive bootstrap, startup regression coverage]
key-files:
  created:
    - lib/core/storage/app_hive_bootstrap.dart
    - test/core/storage/app_hive_bootstrap_test.dart
    - test/features/dashboard/presentation/providers/default_servers_startup_regression_test.dart
  modified:
    - lib/main.dart
key-decisions:
  - "Centralized startup storage open sequence in bootstrapAppHiveStorage and reused it from main()."
  - "Opened default_server_cache in bootstrap path so defaultServersProvider fallback no longer hits unopened-box crash."
patterns-established:
  - "App startup must await initializeAppHiveStorage before runApp."
  - "Provider cold-start regressions are covered with targeted Riverpod startup tests."
requirements-completed: [UI-01, API-03, REL-01]
duration: 3m
completed: 2026-05-24
---

# Phase 09 Plan 04: Gap Closure Summary

**Hive startup now opens `default_server_cache` before provider initialization, preventing cold-start ProviderException/HiveError crashes on dashboard fallback reads.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-24T11:31:08Z
- **Completed:** 2026-05-24T11:33:49Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `initializeAppHiveStorage` / `bootstrapAppHiveStorage` and moved startup storage wiring out of `main.dart`.
- Ensured `default_server_cache` is explicitly opened during bootstrap before `runApp`.
- Added startup regression coverage proving API failure fallback maps to provider state and does not crash.

## Task Commits

1. **Task 1: Add explicit Hive bootstrap for default-server cache before app providers initialize**
   - `cee19be` (test)
   - `b255d80` (feat)
2. **Task 2: Add startup regression test for defaultServersProvider offline/error path without ProviderException**
   - `c3f94f7` (test)
   - `0ade200` (feat)

## Files Created/Modified
- `lib/core/storage/app_hive_bootstrap.dart` - centralized Hive bootstrap with required box-open sequence.
- `lib/main.dart` - awaits bootstrap before `ProviderScope/runApp`.
- `test/core/storage/app_hive_bootstrap_test.dart` - bootstrap contract tests.
- `test/features/dashboard/presentation/providers/default_servers_startup_regression_test.dart` - startup fallback regression test.

## Decisions Made
- Centralize Hive startup behavior in a dedicated module for deterministic app boot ordering.
- Keep auth encrypted box initialization in bootstrap to preserve existing startup behavior while adding default cache opening.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- Initial bootstrap test helper returned incompatible typed box instances; resolved by making injected open-box callback return `Future<void>` because bootstrap only requires side effects.

## Auth Gates
None.

## Known Stubs
None.

## Next Phase Readiness
- UAT blocker path is covered by startup bootstrap + regression tests.
- Ready for verification rerun of phase 09 UAT test set.

## Self-Check: PASSED
