---
phase: 17-dashboard-35-65-layout-refresh
plan: 01
subsystem: ui
tags: [flutter, riverpod, dashboard, widget-test]
requires:
  - phase: 16-servers-screen-defaults-integration
    provides: default servers section tap/connect parity behavior
provides:
  - Dashboard top/bottom visual grouping in single-scroll composition
  - Announcement-first bottom section ordering with content gating
  - Parked highlight styling for selected active server card
  - Widget regression coverage for grouping/top-panel/parked states
affects: [dashboard, default-servers, announcement-ui]
tech-stack:
  added: []
  patterns:
    - Explicit visual-group containers with stable test keys in scroll layouts
    - Selected-vs-neutral UI styling bound directly to provider state
key-files:
  created:
    - test/features/dashboard/presentation/screens/dashboard_screen_layout_grouping_test.dart
    - test/features/dashboard/presentation/screens/dashboard_screen_top_panel_test.dart
    - test/features/dashboard/presentation/widgets/active_server_card_parked_style_test.dart
  modified:
    - lib/features/dashboard/presentation/screens/dashboard_screen.dart
    - lib/features/dashboard/presentation/widgets/active_server_card.dart
    - test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart
key-decisions:
  - "Kept SingleChildScrollView as root and used top/bottom visual groups instead of hard 35/65 viewport split math."
  - "Bound parked styling strictly to activeServerProvider selected-state (server != null) to preserve behavior contracts."
patterns-established:
  - "Dashboard grouping keys (`dashboard-top-visual-group`, `dashboard-bottom-visual-group`) anchor structure tests."
  - "Announcement block remains content-gated and always precedes DefaultServersSection when present."
requirements-completed: [DLAY-01, DLAY-02, DLAY-03, DLAY-04]
duration: 3min
completed: 2026-05-24
---

# Phase 17 Plan 01: Dashboard 35/65 Layout Refresh Summary

**Dashboard now reads as grouped 35/65 visual composition in a single scroll while preserving announcement/FAB/default-server parity and adding selected-server parked emphasis.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-24T22:22:10Z
- **Completed:** 2026-05-24T22:25:13Z
- **Tasks:** 3
- **Files modified:** 6

## Accomplishments
- Added Wave-0 regression tests for layout grouping, top panel content path, and parked card styling.
- Refactored `DashboardScreen` into explicit top/bottom visual groups with stable keys and announcement-first bottom composition.
- Added parked highlight treatment to `ActiveServerCard` selected state without changing tap/navigation/provider flows.

## Task Commits

1. **Task 1: Add Wave-0 dashboard layout/parked-style regression tests before implementation** - `6eb46c1` (test)
2. **Task 2: Refactor DashboardScreen into top/bottom visual groups with announcement-first bottom composition** - `afb6cfa` (test), `88db4ac` (feat)
3. **Task 3: Apply parked highlight treatment to ActiveServerCard and run focused parity suite** - `6a012d9` (feat)

## Files Created/Modified
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` - Added top/bottom visual grouping containers and preserved bottom announcement/default ordering.
- `lib/features/dashboard/presentation/widgets/active_server_card.dart` - Added selected-state border+tint parked styling while preserving existing interaction shell.
- `test/features/dashboard/presentation/screens/dashboard_screen_layout_grouping_test.dart` - New grouping/ordering regression tests.
- `test/features/dashboard/presentation/screens/dashboard_screen_top_panel_test.dart` - New top-group required widget path tests.
- `test/features/dashboard/presentation/widgets/active_server_card_parked_style_test.dart` - New selected vs neutral style regression tests.
- `test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart` - Strengthened ordering assertions inside bottom visual group.

## Decisions Made
- Kept visual 35/65 as grouped scroll composition (no strict viewport split).
- Preserved provider contracts and interaction flows; only composition/styling changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Analyzer warnings blocked Task 3 verification**
- **Found during:** Task 3 verification
- **Issue:** `flutter analyze` failed on updated `dashboard_screen.dart` (sized_box_for_whitespace + unnecessary non-null assertions).
- **Fix:** Replaced non-decorative `Container` with `SizedBox` and removed redundant non-null assertions guarded by existing booleans.
- **Files modified:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- **Verification:** `flutter analyze lib/features/dashboard/presentation/screens/dashboard_screen.dart lib/features/dashboard/presentation/widgets/active_server_card.dart`
- **Committed in:** `6a012d9`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Verification-only cleanup; no behavior or scope changes.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Dashboard layout refresh requirements DLAY-01..04 are implemented and regression-covered.
- Ready for human visual UAT of 35/65 perception across device sizes.

## Known Stubs
None.

## Self-Check: PASSED
- FOUND: `.planning/phases/17-dashboard-35-65-layout-refresh/17-01-SUMMARY.md`
- FOUND commits: `6eb46c1`, `afb6cfa`, `88db4ac`, `6a012d9`
