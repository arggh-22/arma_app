---
phase: 08-api-client-device-auth
plan: 03
subsystem: api
tags: [device-auth, http-client, retry-policy, riverpod, token-lifecycle]
requires:
  - phase: 08-01
    provides: typed auth/key DTO contracts and API config constants
  - phase: 08-02
    provides: encrypted auth persistence and stable device ID resolution
provides:
  - API client for `/auth/device/` and `/keys/` with bounded transient retry
  - Auth repository token lifecycle with 5-minute pre-expiry refresh and one-shot 401 re-auth replay
  - Riverpod auth/token/default-keys providers for Phase 09 UI consumption
affects: [09-default-server-ui, auth, api-client, provider-graph]
tech-stack:
  added: []
  patterns: [typed API failures, one-retry transient policy, provider-driven auth orchestration]
key-files:
  created:
    - lib/features/api/data/datasources/api_client.dart
    - lib/features/api/domain/repositories/auth_repository.dart
    - lib/features/api/data/repositories/auth_repository_impl.dart
    - lib/features/api/presentation/providers/auth_provider.dart
    - lib/features/api/presentation/providers/default_server_keys_provider.dart
    - test/features/api/data/datasources/api_client_test.dart
    - test/features/api/data/repositories/auth_repository_impl_test.dart
    - test/features/api/presentation/providers/auth_provider_test.dart
  modified:
    - lib/features/api/presentation/providers/auth_provider.g.dart
    - lib/features/api/presentation/providers/default_server_keys_provider.g.dart
key-decisions:
  - "401 is treated as explicit re-auth signal; repository clears stale auth and retries protected action once."
  - "Auth providers expose AsyncValue contracts (authState/authToken/defaultServerKeys) and keep UI retry manual via ref.refresh."
patterns-established:
  - "ApiClient maps HTTP/network failures into typed ApiClientException with bounded retry."
  - "AuthRepository centralizes token validity checks and replay logic instead of spreading retry across providers."
requirements-completed: [API-01, SEC-01]
duration: 25min
completed: 2026-05-24
---

# Phase 08 Plan 03: API Client + Auth Orchestration Summary

**Device-auth HTTP calls, token lifecycle replay, and Riverpod auth/key providers are now wired end-to-end for Phase 09 UI integration.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-24T00:00:00Z
- **Completed:** 2026-05-24T00:25:00Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments
- Implemented `ApiClient` with `/auth/device/` + `/keys/`, strict headers/payloads, typed errors, and one transient retry max.
- Added `AuthRepository` contract + implementation for lazy token refresh, 5-minute expiry buffer, and one-time 401 re-auth replay.
- Added Riverpod providers for auth state restore, token retrieval, and default key fetch with manual retry (`ref.refresh(defaultServerKeysProvider)`).

## Task Commits

1. **Task 1: Implement API client with strict timeout and retry policy**
   - `b22eef6` (test) RED
   - `9fd6786` (feat) GREEN
2. **Task 2: Implement auth repository token lifecycle + 401 re-auth**
   - `0feb284` (test) RED
   - `4c2e629` (feat) GREEN
3. **Task 3: Wire Riverpod providers for auth and default-server key fetch**
   - `60c48c0` (test) RED
   - `7736e56` (feat) GREEN

## Files Created/Modified
- `lib/features/api/data/datasources/api_client.dart` - API transport, retry policy, and typed network/auth/server errors.
- `lib/features/api/domain/repositories/auth_repository.dart` - Auth lifecycle abstraction and typed repository failures.
- `lib/features/api/data/repositories/auth_repository_impl.dart` - Device auth orchestration, token validity checks, and one-shot replay logic.
- `lib/features/api/presentation/providers/auth_provider.dart` - Datasource/service/repository wiring plus auth state and token providers.
- `lib/features/api/presentation/providers/default_server_keys_provider.dart` - Tokenized key fetch provider for Phase 09.
- `test/features/api/data/datasources/api_client_test.dart` - HTTP contract + retry behavior tests.
- `test/features/api/data/repositories/auth_repository_impl_test.dart` - Token lifecycle and 401 recovery tests.
- `test/features/api/presentation/providers/auth_provider_test.dart` - Provider restore and token resolution tests.

## Decisions Made
- Used typed exception surfaces (`ApiClientException`, `AuthRepositoryException`) so provider/UI layers can distinguish unauthorized vs transient failures.
- Kept retry deterministic: exactly one silent retry for transient failures, no auto-retry for 4xx, and one re-auth replay on 401.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed nullable token normalization in repository auth persistence**
- **Found during:** Task 2
- **Issue:** `state.token.trim()` and `state.token.isNotEmpty` accessed nullable token directly, causing compile failure.
- **Fix:** Normalized through local nullable-safe token variable before persisting and setting `isAuthenticated`.
- **Files modified:** `lib/features/api/data/repositories/auth_repository_impl.dart`
- **Verification:** `flutter test test/features/api/data/repositories/auth_repository_impl_test.dart -r compact`
- **Committed in:** `4c2e629`

**2. [Rule 3 - Blocking] Used Flutter-managed build_runner after host Dart SDK mismatch**
- **Found during:** Task 3
- **Issue:** `dart run build_runner` failed because host Dart was `3.10.7` while project requires `^3.11.4`.
- **Fix:** Switched generation command to `flutter pub run build_runner build --delete-conflicting-outputs`.
- **Files modified:** Generated provider artifacts under `lib/features/api/presentation/providers/*.g.dart`
- **Verification:** `flutter test test/features/api/presentation/providers/auth_provider_test.dart -r compact`
- **Committed in:** `7736e56`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)  
**Impact on plan:** Fixes were required for compilation and deterministic provider generation; no scope creep.

## Issues Encountered
- Riverpod generated provider name for `AuthStateNotifier` was `authStateProvider`; usage was corrected accordingly before final verification.

## User Setup Required
**External services require manual configuration for production API values.**
- `VPN_API_BASE_URL`
- `VPN_API_KEY`

## Next Phase Readiness
- Phase 09 can consume `authTokenProvider` and `defaultServerKeysProvider` directly without adding auth transport logic.
- Remaining production integration step is wiring real API base URL and app key into runtime config.

## Self-Check: PASSED
- Found summary file: `.planning/phases/08-api-client-device-auth/08-api-client-device-auth-03-SUMMARY.md`
- Found commits: `b22eef6`, `9fd6786`, `0feb284`, `4c2e629`, `60c48c0`, `7736e56`
