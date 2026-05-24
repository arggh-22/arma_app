---
phase: 16-servers-screen-defaults-integration
plan: 02
subsystem: ui
tags: [flutter, riverpod, defaults, mapper, widget-test]
requires:
  - phase: 16-servers-screen-defaults-integration
    provides: Servers-screen defaults section shell and tap parity baseline
provides:
  - Default keyBody sub-link payloads expand into per-server default rows
  - Servers screen shows defaults when imported list is empty in normal mode
  - Regression tests for mapper expansion and empty-imported visibility path
affects: [phase-17-dashboard-layout-refresh]
tech-stack:
  added: []
  patterns:
    - Mapper exposes flattenable mapAll output for deterministic default rows
    - Servers empty state is gated by combined imported/default availability
key-files:
  created: []
  modified:
    - lib/features/dashboard/data/mappers/default_server_item_mapper.dart
    - lib/features/dashboard/presentation/providers/default_servers_provider.dart
    - lib/features/server/presentation/screens/server_list_screen.dart
    - test/features/dashboard/data/mappers/default_server_item_mapper_test.dart
    - test/features/server/presentation/screens/server_list_screen_defaults_test.dart
key-decisions:
  - "Use SubscriptionParser.parseBody for keyBody expansion and deterministic IDs scoped by default API key ID."
  - "Gate EmptyServerState on imported emptiness plus visible-default availability to preserve D-02 multi-select hiding."
patterns-established:
  - "DefaultServersNotifier mapping now flattens mapper output so one API key can produce many connectable rows."
  - "Servers-screen defaults visibility regressions are covered with explicit empty-imported permutations."
requirements-completed: [SRVD-01, SRVD-03]
duration: 2m
completed: 2026-05-24
---

# Phase 16 Plan 02: UAT defaults-gap closure summary

**Closed UAT Test 1 by expanding default sub-link payloads into per-server rows and keeping defaults reachable when imported servers are absent.**

## Performance

- **Duration:** 2m
- **Started:** 2026-05-24T21:23:58Z
- **Completed:** 2026-05-24T21:25:35Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- Added `DefaultServerItemMapper.mapAll` with deterministic row IDs and safe fallback behavior.
- Updated default servers provider mapping to flatten expanded mapper output.
- Removed empty-imported early exit so defaults render in normal mode even without imported groups.

## Task Commits

1. **Task 1: Expand default-server mapping from key payloads into per-server items**
   - `52fb391` (test): RED mapper expansion tests
   - `d921747` (feat): GREEN mapper/provider expansion implementation
2. **Task 2: Keep defaults section reachable when imported list is empty**
   - `ed44e93` (test): RED empty-imported defaults visibility tests
   - `137cb24` (feat): GREEN server-list empty-state gating implementation
3. **Task 3: Run phase-16 gap verification suite for UAT Test 1 closure**
   - `a558898` (chore): verification suite execution record

## Files Created/Modified
- `lib/features/dashboard/data/mappers/default_server_item_mapper.dart` - Adds `mapAll`, deterministic scoped IDs, and safe fallback mapping.
- `lib/features/dashboard/presentation/providers/default_servers_provider.dart` - Flattens expanded mapper output into notifier state.
- `lib/features/server/presentation/screens/server_list_screen.dart` - Shows empty state only when both imported and visible defaults are empty.
- `test/features/dashboard/data/mappers/default_server_item_mapper_test.dart` - Covers sub-link expansion, deterministic IDs, and single-link compatibility.
- `test/features/server/presentation/screens/server_list_screen_defaults_test.dart` - Adds regression coverage for imported-empty/defaults-present and full-empty scenarios.

## Decisions Made
- Reused `SubscriptionParser` for untrusted keyBody parsing to keep protocol validation and malformed-row skipping centralized.
- Preserved existing single-link mapper behavior (`default-api-{id}` + key name) while expanding only multi-link payloads.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
- Initial RED edit nested `testWidgets` declarations accidentally; corrected test structure before proceeding with planned RED assertions.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None.

## Next Phase Readiness
- Phase 16 UAT Test 1 gaps are now covered by passing focused tests and analyzer checks.
- Locked behavior remains intact: defaults hidden in multi-select and tap parity logic unchanged.

## Self-Check: PASSED
- FOUND: `.planning/phases/16-servers-screen-defaults-integration/16-02-SUMMARY.md`
- FOUND commits: `52fb391`, `d921747`, `ed44e93`, `137cb24`, `a558898`
