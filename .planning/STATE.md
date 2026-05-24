---
gsd_state_version: 1.0
milestone: v1.5
milestone_name: Dashboard Layout Refresh + Servers Screen Defaults
status: verifying
stopped_at: Completed 16-02-PLAN.md
last_updated: "2026-05-24T21:26:13.876Z"
last_activity: 2026-05-24
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-24)

**Core value:** Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.
**Current focus:** Planning and executing Phase 17

## Current Position

Phase: 16 (Servers Screen Defaults Integration) — COMPLETE
Plan: 2 of 2
Status: Gap plan complete — ready for Phase 17 planning/execution
Last activity: 2026-05-24

Progress: [██████████] 100%

## Performance Metrics

**Velocity:**

- Total plans completed: 38 (v1.0)
- Average duration: ~5 min
- Total execution time: ~1.8 hours

**By Phase (v1.0):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01 | 5 | 26min | 5.2min |
| 02 | 5 | 20min | 4min |
| 03 | 6 | 34min | 5.7min |
| 04 | 5 | — | — |
| 08 | 8 | - | - |
| 09 | 7 | - | - |
| 11 | 2 | - | - |

**Recent Trend:**

- Last 5 plans: 4min, 11min, 5min, 6min, — (Phase 03-04)
- Trend: Stable

| Phase 08 P01 | 157s | 2 tasks | 18 files |
| Phase 08 P02 | 113 | 2 tasks | 5 files |
| Phase 08-api-client-device-auth P03 | 25min | 3 tasks | 10 files |
| Phase 08-api-client-device-auth P04 | 492 | 2 tasks | 4 files |
| Phase 08 P05 | 191 | 2 tasks | 5 files |
| Phase 09-default-servers-home-screen-display P01 | 105 | 2 tasks | 8 files |
| Phase 09-default-servers-home-screen-display P02 | 296 | 2 tasks | 3 files |
| Phase 09-default-servers-home-screen-display P03 | 172 | 2 tasks | 15 files |
| Phase 09-default-servers-home-screen-display P04 | 3 | 2 tasks | 4 files |
| Phase 10 P01 | 193 | 2 tasks | 5 files |
| Phase 10 P02 | 150 | 2 tasks | 4 files |
| Phase 10-settings-auto-update-configuration P03 | 191 | 2 tasks | 10 files |
| Phase 10 P04 | 2 | 2 tasks | 13 files |
| Phase 10-settings-auto-update-configuration P05 | 187 | 2 tasks | 13 files |
| Phase 11 P01 | 143 | 2 tasks | 7 files |
| Phase 11 P02 | 198 | 2 tasks | 3 files |
| Phase 16 P01 | 254 | 3 tasks | 5 files |
| Phase 16 P02 | 97 | 3 tasks | 5 files |

## Accumulated Context

### Decisions

- v1.2 Layout: Default servers shown in home screen bottom half (below connection stats)
- v1.2 Auth: Users must authenticate with VPN API first before fetching defaults
- v1.2 Updates: Fetch on first launch, manual refresh button, auto-update with user-configurable intervals
- v1.1 Roadmap: 3 phases (coarse granularity) — Foundation+Config → VPN Service+Monitoring → Feature Parity+Rollback
- v1.1 Roadmap: Phase 05 merges library swap + config builder (parallelizable Kotlin/Dart, common foundation)
- [Phase 08]: Token contract is opaque and not parsed as JWT in DTO/domain mapping
- [Phase 08]: API DTO decode now enforces strict field-type checks with FormatException on malformed payloads
- [Phase 08]: Auth box encryption key is generated once, stored in flutter_secure_storage, and reused on reopen.
- [Phase 08]: Device ID resolution prioritizes persisted value, then Android Build.ID, then UUID fallback persisted once.
- [Phase 08-api-client-device-auth]: 401 is treated as explicit re-auth signal; repository clears stale auth and retries protected action once.
- [Phase 08-api-client-device-auth]: Auth providers expose AsyncValue contracts (authState/authToken/defaultServerKeys) and keep UI retry manual via ref.refresh.
- [Phase 08]: Startup auth bootstrap is triggered from ArmaApp initState post-frame and does not block UI render.
- [Phase 08]: authBootstrapProvider is refreshable for explicit reruns while staying idempotent across repeated reads.
- [Phase 08]: Use android_id for stable Android identifier resolution because device_info_plus removed androidId.
- [Phase 08]: Migrate persisted legacy IDs to stable platform IDs when available; UUID fallback remains unavailable-ID only.
- [Phase 09]: Cache reads degrade to null on missing/corrupt payloads to preserve offline/no-cache distinction.
- [Phase 09]: Default server mapping normalizes IDs as default-api-{id} while preserving API metadata unchanged.
- [Phase 09]: Default server dashboard state modeled as keepAlive notifier state (items/refresh/offline/failure) instead of AsyncValue wrapper-driven UI.
- [Phase 09]: Manual refresh retries are foreground-only and bounded to 1s/2s/4s exponential delays via injectable timing providers.
- [Phase 09-default-servers-home-screen-display]: Dashboard default servers remain inline and scrollable with top-3 preview plus show-all sheet.
- [Phase 09-default-servers-home-screen-display]: Tap flow selects via activeServerProvider first, then reconnects only when already connected to a different server.
- [Phase 09-default-servers-home-screen-display]: Centralized Hive startup flow in bootstrapAppHiveStorage and called it from main before runApp.
- [Phase 09-default-servers-home-screen-display]: Opened default_server_cache during startup bootstrap to remove provider cold-start Box-not-found crash path.
- [Phase 10]: Persist interval as fixed string tokens with disabled fallback for invalid decode.
- [Phase 10]: Use keep-alive NotifierProvider as canonical default-server auto-update preference state.
- [Phase 10]: Centralized default-server fetch/prune/write in DefaultServerRefreshService with prune-before-write guarantees.
- [Phase 10]: DefaultServersNotifier now routes refresh/load through shared service while keeping existing retry and offline fallback behavior.
- [Phase 10]: Scheduler wraps Workmanager behind an injectable client so interval/retry policy is unit-testable.
- [Phase 10]: ArmaApp triggers non-blocking auto-update recovery on first frame and resume via scheduler apply/check hooks.
- [Phase 10]: Placed Arma VPN auto-update controls at top of Settings for highest visibility.
- [Phase 10]: Reused defaultServerAutoUpdateProvider.setInterval to keep persistence and scheduler updates centralized.
- [Phase 10]: Bound overdue-refresh indicator visibility directly to scheduler provider typed fields in Settings.
- [Phase 10]: Used MaterialLocalizations compact date/time plus ARB placeholder microcopy for overdue refresh timestamp text.
- [Phase 11]: Mapped client 400 to invalidId and client 409 to alreadyLinked to preserve locked outcome set.
- [Phase 11]: Kept Telegram link execution strictly behind AuthRepository.executeWithAuthRetry.
- [Phase 11]: Used a dedicated keep-alive telegramLinkRepositoryProvider in auth_provider.dart instead of introducing alternate auth/token paths.
- [Phase 11]: Returned the existing in-flight Future from submit() to suppress duplicate taps without launching duplicate requests.
- [Phase 16]: Hide defaults section in multi-select mode via existing isMultiSelectActive gate.
- [Phase 16]: Implement default-row tap parity as select first, then conditional disconnect/connect when target differs.
- [Phase 16]: Use deterministic server-group header keys to make imported regression tests stable.
- [Phase 16]: Use SubscriptionParser parseBody + deterministic default-api-{keyId}-{index} IDs for multi-link default rows while preserving single-link compatibility.
- [Phase 16]: Gate ServerList empty state on imported and defaults availability so defaults remain reachable when imported list is empty in normal mode.

### Roadmap Evolution

- Phase 15.1 inserted after Phase 15: Fix TGAPI-01 bearer authorization regression (URGENT)

### Pending Todos

None yet.

### Blockers/Concerns

- v1.2 API Integration: Need to validate API error handling (offline, timeout, 401 unauthorized)
- v1.2 UX: Need to decide storage strategy for default servers (refresh each launch vs cache with TTL)
- v1.1 Phase 06 risk: PlatformInterface inverted TUN control — highest-risk architectural change.
- Build: sing-box v1.13.6 pinned — do NOT pull v1.14+ (breaking DNS format changes).

## Session Continuity

Last session: 2026-05-24T21:26:13.872Z
Stopped at: Completed 16-02-PLAN.md
Resume file: None
