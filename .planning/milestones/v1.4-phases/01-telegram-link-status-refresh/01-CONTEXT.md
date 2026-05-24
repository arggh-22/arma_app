# Phase 1: Telegram Link Status Refresh - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Add Step 3 status refresh in Telegram link flow and ensure `/auth/device/` request payload uses the same app-version source used in Settings, so status updates are reliable and consistent.

</domain>

<decisions>
## Implementation Decisions

### Status check flow
- **D-01:** Step 3 includes a **Check Link Status** action that calls `/auth/device/` through the existing auth pipeline.
- **D-02:** While status check is running, disable the Step 3 action and show an inline spinner on that action.
- **D-03:** If status check returns `is_guest=false`, show success snackbar and navigate back to dashboard immediately.
- **D-04:** If status check fails (network/server), show error snackbar and keep action enabled for immediate retry on the same screen.

### Version payload source
- **D-05:** `/auth/device/` must use the same shared app-version source shown in Settings (remove stale hardcoded auth-flow value).

### the agent's Discretion
- Exact snackbar text wording and iconography.
- Internal provider method naming for status refresh.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### API contract
- `docs/api_documentation.md` — `/auth/device/` payload/response contract (`app_version`, `is_guest`, announcement fields).

### Milestone scope and mapping
- `.planning/ROADMAP.md` — v1.4 Phase 1 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `TGSTAT-01`, `TGVER-01`.

### Existing implementation baselines
- `lib/features/dashboard/presentation/screens/telegram_link_guide_screen.dart` — current Telegram guide flow and submit behavior.
- `lib/features/api/presentation/providers/auth_provider.dart` — current auth repository wiring with stale hardcoded app version.
- `lib/features/settings/presentation/screens/settings_screen.dart` — settings app version display source used as baseline.
- `lib/core/constants/app_constants.dart` — current centralized app version constant.
- `lib/features/api/data/models/device_auth_response.dart` — current `/auth/device/` DTO fields (`is_guest` currently parsed).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `telegram_link_guide_screen.dart`: existing Telegram flow UI with in-button loading pattern for submit.
- `auth_provider.dart`: centralized auth repository construction point; best location to swap version source.
- `DeviceAuthResponse`: existing typed parse/mapping for `/auth/device/` response.

### Established Patterns
- User feedback uses `ScaffoldMessenger` snackbars.
- Async action buttons disable during in-flight operations.
- API/auth refresh is centralized via auth providers/repositories.

### Integration Points
- Telegram guide Step 3 action in `telegram_link_guide_screen.dart`.
- Auth refresh path through `authRepositoryProvider` and state notifier reload.

</code_context>

<specifics>
## Specific Ideas

- User explicitly wants Step 3 status check action and immediate dashboard return after linked status.
- User wants to reuse existing Settings app-version source for auth payload consistency.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 1 scope.

</deferred>

---

*Phase: 01-telegram-link-status-refresh*
*Context gathered: 2026-05-24*
