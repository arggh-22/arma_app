---
phase: 09-default-servers-home-screen-display
plan: 03
subsystem: dashboard
tags: [dashboard, default-servers, riverpod, l10n, reconnect]
requires:
  - phase: 09-default-servers-home-screen-display
    provides: provider state machine + cache fallback from Plan 02
provides:
  - Inline dashboard default-server section with top-3 preview and show-all sheet
  - Refresh spinner + offline/empty states + typed snackbar copy localization
  - Tap-to-connect routing through activeServerProvider and connectionProvider
affects: [dashboard_screen, default_servers_section, default_servers_sheet, l10n]
tech-stack:
  added: []
  patterns: [provider-driven UI state render, select-before-reconnect flow]
key-files:
  created:
    - lib/features/dashboard/presentation/widgets/default_servers_section.dart
    - lib/features/dashboard/presentation/widgets/default_servers_sheet.dart
    - test/features/dashboard/presentation/widgets/default_servers_section_test.dart
  modified:
    - lib/features/dashboard/presentation/screens/dashboard_screen.dart
    - lib/core/l10n/app_en.arb
    - lib/core/l10n/app_fa.arb
    - lib/core/l10n/app_hy.arb
    - lib/core/l10n/app_ru.arb
    - lib/core/l10n/app_zh.arb
    - lib/core/l10n/app_localizations.dart
    - lib/core/l10n/app_localizations_en.dart
    - lib/core/l10n/app_localizations_fa.dart
    - lib/core/l10n/app_localizations_hy.dart
    - lib/core/l10n/app_localizations_ru.dart
    - lib/core/l10n/app_localizations_zh.dart
key-decisions:
  - "Dashboard section remains inline and scrollable; no route transition for default servers."
  - "Tap flow always selects via activeServerProvider first, then reconnects only when currently Connected and target differs."
requirements-completed: [UI-01, UI-02, API-03, REL-01]
duration: 172
completed: 2026-05-24
---

# Phase 09 Plan 03: Default Servers Home Screen Display Summary

**Dashboard now shows API-backed default servers inline with refresh/offline UX, show-all sheet, and provider-integrated tap-to-connect behavior.**

## Performance

- **Duration:** 172s
- **Tasks:** 2
- **Files modified:** 15

## Accomplishments

- Added `DefaultServersSection` below dashboard traffic with top-3 preview, refresh spinner, status badges, traffic progress, and empty/offline rendering.
- Added `DefaultServersSheet` for “Show all servers” modal list.
- Localized all new default-server copy (EN/FA/HY/RU/ZH), including refresh semantics and typed failure snackbar messages.
- Implemented tap behavior through existing providers: disconnected tap selects only; connected tap on different server selects then disconnects/connects.
- Added widget tests covering preview/sheet, refresh spinner retention, empty/offline states, snackbar error mapping, reconnect branch, and disabled taps.

## Task Commits

1. **Task 1: Build default server section and sheet widgets** — `a485a0d` (test), `3c2bcd5` (feat)
2. **Task 2: Wire tap-to-connect behavior through existing providers** — `f833d8f` (test), `2e3bb3d` (feat)

## Decisions Made

- Kept server list visible during refresh and represented loading via icon spinner only.
- Reused existing provider pathways (`defaultServersProvider`, `activeServerProvider`, `connectionProvider`) with no parallel default-server selection state.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: `.planning/phases/09-default-servers-home-screen-display/09-default-servers-home-screen-display-03-SUMMARY.md`
- FOUND commits: `a485a0d`, `3c2bcd5`, `f833d8f`, `2e3bb3d`
