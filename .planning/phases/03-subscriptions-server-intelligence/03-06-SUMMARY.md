---
phase: 03-subscriptions-server-intelligence
plan: 06
subsystem: ui
tags: [flutter, riverpod, material3, multi-select, sort-filter, latency]

# Dependency graph
requires:
  - phase: 03-01
    provides: "Subscription model, server config with subscriptionId/groupName"
  - phase: 03-03
    provides: "LatencyNotifier, BestServerProvider for latency testing"
  - phase: 03-05
    provides: "QrScannerScreen, AddSubscriptionDialog, SubscriptionNotifier"
provides:
  - "Multi-select mode with bulk delete for server list"
  - "Sort/filter bar (name/latency/protocol sort, all/working/failed filter)"
  - "LatencyIndicator widget with color-coded latency display"
  - "Subscription group headers with metadata, collapse, refresh"
  - "Best Server and Test All buttons in AppBar"
  - "Pull-to-refresh triggering subscription auto-update"
  - "Functional QR scan and Add Subscription in ImportFab"
affects: [04-advanced]

# Tech tracking
tech-stack:
  added: []
  patterns: [multi-select-via-riverpod, sort-filter-records]

key-files:
  created:
    - lib/features/server/presentation/providers/multi_select_provider.dart
    - lib/features/server/presentation/providers/sort_filter_provider.dart
    - lib/features/server/presentation/widgets/sort_filter_bar.dart
    - lib/features/server/presentation/widgets/latency_indicator.dart
  modified:
    - lib/features/server/presentation/widgets/server_card.dart
    - lib/features/server/presentation/widgets/server_group_header.dart
    - lib/features/server/presentation/screens/server_list_screen.dart
    - lib/features/server/presentation/widgets/import_fab.dart

key-decisions:
  - "Used AsyncValue.value (not valueOrNull) per Riverpod 3.2.1 API"
  - "Multi-select uses Riverpod notifier with Set<String> for selected IDs"
  - "Sort/filter state uses Dart 3 record type for compound state"

patterns-established:
  - "Multi-select pattern: Riverpod Set<String> notifier, empty set = inactive mode"
  - "Sort/filter pattern: Dart 3 record ({SortCriteria sort, FilterCriteria filter})"
  - "LatencyIndicator: fixed-width (56dp) widget with sentinel values (-2=testing, -1=failed)"

requirements-completed: [SERV-05, SERV-06, SERV-07, SERV-08]

# Metrics
duration: 6min
completed: 2026-04-05
---

# Phase 03 Plan 06: Server List UI Integration Summary

**Full server list wired with multi-select bulk delete, sort/filter bar, latency indicators, subscription headers with metadata, pull-to-refresh, Best Server/Test All, and functional QR scan + subscription import FAB**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-05T17:15:21Z
- **Completed:** 2026-04-05T17:21:20Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- Multi-select mode activated by long-press with checkbox UI, Select All, and bulk delete with confirmation dialog
- Sort/filter bar with dropdown (Name/Latency/Protocol) and filter chips (All/Working/Failed)
- LatencyIndicator widget with color-coded display (green ≤150ms, orange ≤300ms, red >300ms) and tap-to-retest
- Subscription group headers showing server count, data usage (GB), expiry (days), with collapse toggle and individual refresh
- Best Server button (auto_awesome icon) selects lowest-latency server, Test All button (speed icon) triggers bulk latency testing
- Pull-to-refresh triggers subscription auto-update via RefreshIndicator
- ImportFab upgraded from 3 to 4 options: QR scan → QrScannerScreen, Add Subscription → AddSubscriptionDialog

## Task Commits

Each task was committed atomically:

1. **Task 1: Create multi-select, sort/filter providers + SortFilterBar + LatencyIndicator widgets** - `36070cf` (feat)
2. **Task 2: Wire ServerCard, ServerGroupHeader, ServerListScreen, ImportFab — full UI integration** - `8b4d196` (feat)

## Files Created/Modified
- `lib/features/server/presentation/providers/multi_select_provider.dart` - Multi-select state management with enter/toggle/selectAll/clear
- `lib/features/server/presentation/providers/sort_filter_provider.dart` - Sort/filter enums and Riverpod notifier
- `lib/features/server/presentation/widgets/sort_filter_bar.dart` - Horizontal bar with sort dropdown and filter chips
- `lib/features/server/presentation/widgets/latency_indicator.dart` - Color-coded latency display with tap-to-retest
- `lib/features/server/presentation/widgets/server_card.dart` - Extended with latency indicator, multi-select checkbox, primaryContainer tint
- `lib/features/server/presentation/widgets/server_group_header.dart` - Extended with subscription metadata, collapse/expand, refresh
- `lib/features/server/presentation/screens/server_list_screen.dart` - Major rewrite: ConsumerStatefulWidget with all Phase 3 features
- `lib/features/server/presentation/widgets/import_fab.dart` - Added QrScannerScreen navigation and AddSubscriptionDialog option

## Decisions Made
- Used `AsyncValue.value` instead of `valueOrNull` — Riverpod 3.2.1 API provides nullable `value` getter directly on AsyncValue
- Multi-select uses Riverpod Set<String> notifier — empty set signals inactive mode, no separate boolean needed
- Sort/filter state uses Dart 3 record type for clean compound state management

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed AsyncValue.valueOrNull to AsyncValue.value**
- **Found during:** Task 2 (ServerListScreen integration)
- **Issue:** Plan code used `valueOrNull` which doesn't exist in Riverpod 3.2.1; the nullable value getter is just `.value`
- **Fix:** Replaced all 3 occurrences of `.valueOrNull` with `.value`
- **Files modified:** server_list_screen.dart
- **Verification:** flutter analyze passes with 0 errors
- **Committed in:** 8b4d196 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Trivial API name correction. No scope change.

## Issues Encountered
- `dart run build_runner` failed due to system Dart SDK being too old — used `flutter pub run build_runner` per established project convention (documented in STATE.md decisions)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 3 is now fully complete: all 6 plans executed
- Server list has all planned features integrated and wired
- Ready for Phase 4 (Advanced features) if applicable

---
*Phase: 03-subscriptions-server-intelligence*
*Completed: 2026-04-05*
