---
phase: 16-servers-screen-defaults-integration
plan: 03
subsystem: ui
tags: [flutter, riverpod, defaults, subscription, regression]
requires:
  - phase: 16-servers-screen-defaults-integration
    provides: Servers-screen defaults section shell, tap parity, and keyBody expansion baseline
provides:
  - Per-key `subscription_url` resolution in default servers provider with per-key keyBody fallback
  - Collapsible grouped defaults sublists on Servers screen with expanded-on-open behavior
  - Regression coverage for imported groups while grouped defaults are present
affects: [phase-17-dashboard-layout-refresh]
tech-stack:
  added: []
  patterns:
    - Default keys are converted into deterministic synthetic subscriptions for reuse of SubscriptionService parsing/fetch flow
    - Defaults section renders nested subgroup headers keyed by subscription_url while preserving row tap behavior
key-files:
  created: []
  modified:
    - lib/features/dashboard/presentation/providers/default_servers_provider.dart
    - lib/features/dashboard/data/mappers/default_server_item_mapper.dart
    - lib/features/server/presentation/widgets/server_list_default_servers_section.dart
    - test/features/dashboard/presentation/providers/default_servers_provider_test.dart
    - test/features/server/presentation/screens/server_list_screen_defaults_test.dart
    - test/features/server/presentation/screens/server_list_screen_regression_test.dart
key-decisions:
  - "Resolve defaults through SubscriptionService.fetch per key and fallback to keyBody only for that key on fetch failure."
  - "Use serverConfig.groupName (not raw URL) for subgroup labels to keep grouped UI safe and user-readable."
  - "Keep default-row tap flow unchanged (select first, then conditional reconnect when connected to another target)."
patterns-established:
  - "Provider mapping now supports mixed resolved/fallback rows per refresh cycle without failing entire defaults state."
  - "Servers-screen defaults tests assert subgroup keys/toggles and expanded-on-open lifecycle behavior."
requirements-completed: [SRVD-01, SRVD-02, SRVD-03, SRVD-04]
duration: 7m 2s
completed: 2026-05-24
---

# Phase 16 Plan 03: subscription_url grouped defaults gap closure summary

**Default keys now resolve through each `subscription_url` and render as collapsible grouped default server lists while preserving imported-group and tap-parity behavior.**

## Performance

- **Duration:** 7m 2s
- **Started:** 2026-05-24T21:48:12Z
- **Completed:** 2026-05-24T21:55:14Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Replaced keyBody-first provider mapping with per-key `SubscriptionService.fetch` resolution and deterministic synthetic subscriptions.
- Refactored defaults section into per-subscription grouped sublists with independent collapse toggles and expanded-on-open behavior.
- Added regression tests that keep imported group collapse/multi-select behavior stable while grouped defaults are visible.

## Task Commits

1. **Task 1: Resolve each default key through subscription_url in provider mapping pipeline**
   - `1621551` (test): RED provider tests for subscription_url-driven expansion/fallback
   - `181203b` (feat): GREEN provider+mapper implementation with per-key fetch fallback
2. **Task 2: Render default servers as collapsible per-key grouped lists in Servers screen section**
   - `2298923` (test): RED grouped defaults widget tests
   - `c8969e3` (feat): GREEN grouped defaults section implementation
3. **Task 3: Add regression safety for imported groups and gap-closure verification run**
   - `2cd36a9` (test): RED imported-group + grouped-default regression case
   - `954a435` (test): GREEN regression fixture updates + final verification compliance

## Files Created/Modified
- `lib/features/dashboard/presentation/providers/default_servers_provider.dart` - Adds async per-key subscription resolution with deterministic synthetic subscription entities.
- `lib/features/dashboard/data/mappers/default_server_item_mapper.dart` - Adds `mapResolved` path for fetched server rows while preserving deterministic IDs/fallback behavior.
- `lib/features/server/presentation/widgets/server_list_default_servers_section.dart` - Renders grouped default subheaders/toggles and keeps row tap parity flow.
- `test/features/dashboard/presentation/providers/default_servers_provider_test.dart` - Covers subscription_url expansion and per-key fallback semantics.
- `test/features/server/presentation/screens/server_list_screen_defaults_test.dart` - Covers grouped rendering, subgroup toggles, and expanded-on-open behavior.
- `test/features/server/presentation/screens/server_list_screen_regression_test.dart` - Covers imported-group behavior while grouped defaults are present.

## Decisions Made
- Reused existing subscription import fetch/parser contract (`SubscriptionService`) instead of adding a new default-specific parser path.
- Kept subgroup titles sourced from safe metadata (`groupName`/name), never rendering raw `subscription_url`.
- Preserved D-07 parity path exactly by leaving `_onTapDefaultServer` select + conditional reconnect logic intact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed analyzer gate on grouped-row loop structure**
- **Found during:** Task 3 verification suite
- **Issue:** `curly_braces_in_flow_control_structures` triggered in grouped row rendering loop, causing analyze command failure.
- **Fix:** Wrapped subgroup row `for` body in braces.
- **Files modified:** `lib/features/server/presentation/widgets/server_list_default_servers_section.dart`
- **Verification:** Full plan verification command suite (3 test files + targeted analyze) passed.
- **Committed in:** `954a435`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** No scope creep; required to satisfy mandatory verification gate.

## Issues Encountered
- Provider tests initially became network-dependent after per-key fetch integration; stabilized with test-only `SubscriptionService` overrides to keep deterministic, offline-safe execution.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None.

## Next Phase Readiness
- Phase 16 UAT gap for subscription_url grouped defaults is covered with passing provider/widget/regression suites.
- Phase 17 can reuse grouped defaults structure without reworking server selection or imported-group behavior.

## Self-Check: PASSED
- FOUND: `.planning/phases/16-servers-screen-defaults-integration/16-03-SUMMARY.md`
- FOUND commits: `1621551`, `181203b`, `2298923`, `c8969e3`, `2cd36a9`, `954a435`
