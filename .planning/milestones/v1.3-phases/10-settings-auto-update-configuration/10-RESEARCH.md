# Phase 10: Settings & Auto-Update Configuration - Research

**Researched:** 2026-05-24  
**Status:** Ready for planning

## RESEARCH COMPLETE

## Locked Decision Alignment (from 10-CONTEXT)

- Background scheduler + app-open fallback.
- New top “Arma VPN settings” section in Settings.
- Interval options via radio list (Disabled, 12h, 24h, 7d), default Disabled.
- Retry ladder: 1m, 5m, 15m then stop until next schedule.
- Unauthorized: one silent re-auth attempt then stop.
- Expired keys pruned after successful sync; active connected server not force-disconnected.

## Requirements Mapping

| Requirement | Direction |
|---|---|
| DATA-01 | App-open overdue check triggers refresh path |
| DATA-02 | Background periodic scheduler controlled by saved interval |
| DATA-03 | Cache metadata + expire-date pruning on sync |
| COMPAT-01 | Reuse existing active/connection providers |
| COMPAT-02 | Persist setting in existing settings persistence layer |

## Key Existing Assets

- `lib/features/settings/presentation/screens/settings_screen.dart` (Settings UI integration point)
- `lib/features/settings/*providers*` and datasource patterns (persistence conventions)
- `lib/features/dashboard/presentation/providers/default_servers_provider.dart` (refresh state machine)
- `lib/features/api/data/datasources/default_server_cache_datasource.dart` (cache storage integration)
- `lib/features/api/presentation/providers/default_server_keys_provider.dart` (auth-aware key fetch)

## Core Findings

1. Phase 09 already built provider/cache/failure mapping foundation; Phase 10 should add orchestration, not duplicate fetch logic.
2. `workmanager` is the practical Flutter option for periodic background jobs.
3. Interval changes must cancel/re-register existing scheduled work to avoid duplicate executions.
4. App-open fallback is mandatory because background execution can be delayed/throttled by OS policies.
5. Preference reads used by background logic should be reload/async-safe to avoid stale values.

## Recommended Structure

- `lib/features/settings/domain/entities/default_server_auto_update_interval.dart`
- `lib/features/settings/presentation/providers/default_server_auto_update_provider.dart`
- `lib/features/api/data/services/default_server_refresh_service.dart`
- `lib/features/api/presentation/providers/default_server_refresh_scheduler_provider.dart`
- tests for scheduler registration, fallback trigger, and expire-date pruning

## Pitfalls to Avoid

1. Separate background-only refresh implementation bypassing existing auth retry/provider path.
2. Duplicate retry ladders in multiple places.
3. Not pruning expired cache entries during successful sync.
4. Force-disconnecting active sessions on expiry refresh (violates locked behavior).
5. Non-persisted or stale interval state causing scheduler drift.

## Validation Guidance

- Add tests for:
  - interval persistence + re-schedule behavior
  - overdue app-open fallback trigger
  - bounded retry timing policy handling
  - expire-date prune behavior
  - compatibility with existing connection flow
