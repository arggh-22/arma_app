---
phase: 09-default-servers-home-screen-display
plan: 01
subsystem: api
tags: [hive, riverpod, cache, mapper, default-servers]
requires:
  - phase: 08-api-client-device-auth
    provides: Authenticated default server key fetch contract (`DefaultServerKey`)
provides:
  - Hive-backed default-server cache envelope with fetch metadata
  - Deterministic key-to-dashboard item mapper with guarded parser behavior
affects: [09-02-PLAN, 09-03-PLAN, dashboard, offline-fallback]
tech-stack:
  added: []
  patterns: [json-encoded Hive snapshot cache, deterministic default-api-{id} mapping]
key-files:
  created:
    - lib/features/api/data/models/default_server_cache_model.dart
    - lib/features/api/data/datasources/default_server_cache_datasource.dart
    - lib/features/api/presentation/providers/default_server_cache_provider.dart
    - lib/features/dashboard/domain/entities/default_server_item.dart
    - lib/features/dashboard/data/mappers/default_server_item_mapper.dart
    - test/features/api/data/models/default_server_cache_model_test.dart
    - test/features/api/data/datasources/default_server_cache_datasource_test.dart
    - test/features/dashboard/data/mappers/default_server_item_mapper_test.dart
  modified: []
key-decisions:
  - "Cache reads degrade to null (no-cache) on missing/corrupt payloads to safely distinguish offline/no-cache states."
  - "Default server mapper normalizes parser output IDs to `default-api-{id}` while preserving API metadata unchanged."
patterns-established:
  - "Default server cache persists a single snapshot envelope keyed as `snapshot` in Hive."
  - "Mapper-level parser guarding returns non-connectable items instead of throwing on malformed key_body."
requirements-completed: [API-02, REL-01]
duration: 2m
completed: 2026-05-24
---

# Phase 09 Plan 01: Default Servers Home Screen Display Summary

**Offline-safe default-server cache and deterministic key-body mapping now provide stable dashboard-ready data contracts for Phase 09 UI wiring.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-24T10:55:53Z
- **Completed:** 2026-05-24T10:57:38Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added persistent cache model + datasource with defensive corrupted-payload fallback.
- Exposed cache datasource/read provider for dashboard consumers.
- Added deterministic mapper from `DefaultServerKey` to connect-ready dashboard item with parse guards.

## Task Commits

1. **Task 1: Add persistent default-server cache contracts (D-16, D-17)** - `7062e9a` (test), `e7e9911` (feat)
2. **Task 2: Create deterministic default-server item mapper (D-05, D-06, D-08, D-15)** - `b352ef4` (test), `ed5a708` (feat)

**Plan metadata:** Included in final docs commit for this plan.

## Files Created/Modified
- `lib/features/api/data/models/default_server_cache_model.dart` - Cache envelope with `fetchedAt` and serialized API key payload list.
- `lib/features/api/data/datasources/default_server_cache_datasource.dart` - Hive snapshot read/write/clear APIs with corrupt fallback.
- `lib/features/api/presentation/providers/default_server_cache_provider.dart` - Riverpod providers for cache datasource + snapshot read.
- `lib/features/dashboard/domain/entities/default_server_item.dart` - Dashboard contract carrying status/traffic/subscription metadata and connectability.
- `lib/features/dashboard/data/mappers/default_server_item_mapper.dart` - Deterministic mapper with `ShareLinkParser` normalization and guard.
- `test/features/api/data/models/default_server_cache_model_test.dart` - Round-trip cache payload preservation tests.
- `test/features/api/data/datasources/default_server_cache_datasource_test.dart` - Empty/restore/corrupt datasource behavior tests.
- `test/features/dashboard/data/mappers/default_server_item_mapper_test.dart` - Deterministic ID and malformed `keyBody` tests.

## Decisions Made
- Used a single `snapshot` cache key to atomically replace prior payloads on each write.
- Kept mapper output non-throwing for malformed `keyBody` by returning `serverConfig: null` and `isConnectable: false`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 09-02 can build provider state machine on top of stable cache + mapper contracts.
- No blockers identified for planned follow-up work.

## Self-Check: PASSED
- FOUND: `.planning/phases/09-default-servers-home-screen-display/09-default-servers-home-screen-display-01-SUMMARY.md`
- FOUND commits: `7062e9a`, `e7e9911`, `b352ef4`, `ed5a708`
