# Phase 08: API Client & Device Authentication - Research

**Researched:** 2026-05-24  
**Status:** Ready for planning

## RESEARCH COMPLETE

## User Constraints (from CONTEXT.md)

- Riverpod `FutureProvider` / `AsyncValue` for HTTP-facing async state.
- Riverpod `StateNotifier<AuthState>` synced to encrypted Hive.
- Device-specific Android ID strategy with persisted fallback.
- Hybrid retry strategy: one silent auto-retry, then manual retry UX.

## Phase Requirements Coverage

| ID | Support in this research |
|---|---|
| API-01 | Device auth flow, API client structure, token lifecycle |
| SEC-01 (partial) | Encrypted token/HWID storage and redaction practices |

## Core Recommendations

1. Build a Riverpod-first auth pipeline: `deviceIdProvider` -> `authStateNotifierProvider` -> `authTokenProvider` -> API calls.
2. Model API states with `AsyncValue` and use `ref.refresh(provider)` for manual retry.
3. Treat 401 as explicit re-auth path (unless backend later provides refresh endpoint).
4. Keep auth/HWID in a dedicated encrypted Hive box with strict no-plaintext logging.

## Architecture Notes

- Reuse existing provider patterns from `lib/features/server/presentation/providers/subscription_provider.dart`.
- Keep data flow layered (data source -> repository -> providers) consistent with current codebase conventions.
- Use a centralized retry utility/policy instead of ad-hoc retries in every call site.

## Device ID Research Findings

- For Android uniqueness semantics, prefer Android ID-based strategy over build-label fields.
- Persist resolved device ID in Hive to avoid recomputation and maintain stable identity in app lifecycle.
- If platform ID fetch fails, fallback to generated UUID and persist once.
- Factory reset can still rotate identifiers; this is an accepted limitation for this milestone.

## Token Lifecycle Findings

- Keep token metadata in `AuthState` (`token`, `expiresAt`, flags, user/device IDs).
- Lazy refresh/check strategy is preferred: validate near request-time, not timer-driven background refresh.
- On expiry/401:
  - attempt re-auth flow,
  - update state atomically,
  - retry the original request once.

## Error Handling & Retry Findings

- Retry only transient classes (timeouts/network/5xx) with one silent backoff attempt.
- Do not auto-retry 4xx auth/client errors.
- After failed auto-retry, surface clear error and provide manual retry action.
- Timeout baseline from context remains reasonable for mobile: ~5s connect, ~10s read.

## Security Findings

- Token + HWID storage must use encrypted Hive box.
- Never log full token/HWID values.
- Keep placeholder API key/base URL configurable for non-prod and move hardening to later phase per roadmap/context.

## Environment & Blockers

- Codebase/tooling is ready for this phase.
- External unblockers remain:
  - production API base URL,
  - real `X-API-Key`,
  - backend clarification on token TTL/refresh endpoint behavior.

## Common Pitfalls to Avoid

1. Using non-unique Android fields as stable HWID.
2. Assuming refresh endpoint exists when API docs only guarantee device auth.
3. Persisting auth state unencrypted.
4. Leaking sensitive values in logs.
5. Scattering retry logic across providers instead of one policy.
6. Race conditions while updating token state across concurrent requests.
7. Missing provider invalidation/refresh consistency after auth changes.
8. Forgetting generated Riverpod artifacts when new annotated providers are introduced.

## Planning Inputs (for gsd-planner)

- Create plans that explicitly implement:
  - encrypted auth storage,
  - device auth + token lifecycle,
  - hybrid retry/error UX contract,
  - provider wiring ready for Phase 09 consumption.
- Include concrete acceptance criteria for each task (grep/test-verifiable).
- Keep implementation aligned to current server feature/provider conventions.

