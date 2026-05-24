# Phase 11: Telegram Link API Integration - Context

**Gathered:** 2026-05-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement Telegram linking API integration for authenticated users: validate Telegram ID input, call `POST /auth/telegram/link/` with bearer auth, and return typed outcomes that downstream UI can consume.  
This phase does not introduce new UI screens or home-button placement (covered in later phases).

</domain>

<decisions>
## Implementation Decisions

### Telegram ID validation contract
- **D-01:** Normalize Telegram ID by trimming whitespace before validation.
- **D-02:** Accept only numeric IDs (`0-9`), no signs, no spaces, no symbols.
- **D-03:** Valid length range is 5–20 digits; out-of-range values are rejected client-side before network call.

### Auth and retry policy for link endpoint
- **D-04:** Execute link requests through existing `AuthRepository.executeWithAuthRetry(...)` flow.
- **D-05:** Keep current unauthorized behavior: one silent re-auth retry on `401`, then surface `unauthorizedAfterRetry`.
- **D-06:** Keep existing transient retry behavior in API client for network/timeouts/server responses where applicable.

### Response typing and phase-11 output
- **D-07:** Introduce typed link outcomes: `linked`, `already_linked`, `invalid_id`, `unauthorized`, `network`, `server`, `unknown`.
- **D-08:** Phase 11 returns structured outcome objects for UI consumption; no new persisted Telegram-link state storage is added in this phase.
- **D-09:** Keep diagnostics logging/redaction consistent with existing API client rules (never expose bearer token in logs).

### the agent's Discretion
- Exact Dart type names and file boundaries for new link request/response models.
- Mapping details from backend response payload fields to domain outcome enums when payload variants are discovered.

</decisions>

<specifics>
## Specific Ideas

- Endpoint contract locked by user: `POST /auth/telegram/link/` with bearer token and JSON `{ "telegram_id": "<id>" }`.
- This milestone’s UX flow will direct users to `https://t.me/devarmabot`, then `Start`, then `Get Telegram ID` or `/my_id`, then paste and link in-app.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement sources
- `.planning/ROADMAP.md` — Phase 11 goal, dependencies, and success criteria for Telegram link API integration.
- `.planning/REQUIREMENTS.md` — v1.3 requirements `TGAPI-01`, `TGAPI-02`, `TGCOMP-01`.
- `.planning/PROJECT.md` — current milestone objective and target feature list for v1.3.

### Existing auth/API contracts to extend
- `lib/features/api/data/datasources/api_client.dart` — current API path patterns, retry policy, diagnostics redaction.
- `lib/features/api/domain/repositories/auth_repository.dart` — auth lifecycle contract and retry entry point.
- `lib/features/api/data/repositories/auth_repository_impl.dart` — one-retry unauthorized handling and token lifecycle behavior.
- `lib/features/api/presentation/providers/auth_provider.dart` — Riverpod provider graph for API/auth dependencies.

### Prior phase decisions
- `.planning/phases/08-api-client-device-auth/08-CONTEXT.md` — locked patterns for API/auth/token/HWID/error handling.
- `.planning/phases/09-default-servers-home-screen-display/09-CONTEXT.md` — inherited unauthorized/error UX principles used by API-backed flows.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ApiClient` already centralizes endpoint calls, timeout/retry logic, and diagnostics redaction.
- `AuthRepository.executeWithAuthRetry` already encapsulates `401` recovery and re-auth retry rules.
- Existing `ApiClientException` + repository exception typing can be extended for Telegram-link outcomes.

### Established Patterns
- Riverpod provider composition (`auth_provider.dart`) is the canonical wiring style.
- API errors are mapped to typed failure enums before UI consumption.
- Security-sensitive headers and bodies are masked in diagnostics output.

### Integration Points
- Add Telegram link endpoint method in API datasource layer.
- Add repository/domain wrapper for link operation through auth retry path.
- Expose provider contract that Phase 12 UI can call without duplicating auth/token logic.

</code_context>

<deferred>
## Deferred Ideas

- Home-screen `Link` button and Telegram icon placement (Phase 12).
- Guided Telegram instruction screen and copy/CTA UX (Phase 12).
- Result-state UX polish and broader validation pass (Phase 13).

</deferred>

---

*Phase: 11-telegram-link-api-integration*  
*Context gathered: 2026-05-24*
