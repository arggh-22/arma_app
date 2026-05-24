# Phase 09: Default Servers Home Screen Display - Context

**Gathered:** 2026-05-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Display API-backed default servers on the Dashboard (home screen) bottom section with manual refresh, connection interaction, and offline/error behavior.  
Scope is limited to Phase 09 requirements (API-02, API-03, UI-01, UI-02, REL-01).

</domain>

<decisions>
## Implementation Decisions

### Dashboard layout placement
- **D-01:** Default Servers section is **inline on Dashboard**, below traffic stats, within same page scroll.
- **D-02:** Section shows **top 3 servers** by default, plus a **Show all** action.
- **D-03:** `Show all` opens a **modal/bottom sheet on Dashboard** (not navigation to `/servers` tab).
- **D-04:** Preview items reuse existing **ServerCard visual style** for consistency.

### Card content and status behavior
- **D-05:** Each item shows **name + status badge + traffic usage**.
- **D-06:** Status badge mapping is fixed:
  - `active` → green
  - `expired` → red
  - `limited` → orange
  - unknown → gray
- **D-07:** Non-active servers (`expired`, `limited`, unknown/non-active) are **not tappable** and must render disabled state.
- **D-08:** Traffic is shown as **progress bar + used/limit text** (example: `2.1GB / 10GB`).

### Refresh behavior
- **D-09:** Manual refresh control is a **header icon button** in the section.
- **D-10:** During refresh, keep current list visible and show spinner in refresh icon.
- **D-11:** Success is silent; show snackbar only on failure.
- **D-12:** Retry uses same header refresh button (no additional inline retry button).

### Tap-to-connect integration
- **D-13:** If disconnected and user taps active default server, it is selected first (not immediate connect).
- **D-14:** If already connected and user taps another active default server, **auto-disconnect and reconnect immediately** to the new server.
- **D-15:** Selection/connect uses existing **`activeServerProvider` path** (no separate default-server active state).

### Offline/error UX
- **D-16:** If fetch fails but cache exists, show cached list with explicit **"Offline data"** label.
- **D-17:** If fetch fails and no cache exists, show empty-state message; retry remains via header button.
- **D-18:** Snackbar errors are specific by failure type: timeout, offline, unauthorized, server error.
- **D-19:** On unauthorized, perform one silent re-auth attempt, then show auth error if still failing.

### the agent's Discretion
- Exact copywriting text for section title, empty-state text, and snackbar phrasing (must remain concise/localized).
- Exact animation style for progress bar and refresh spinner transitions.

</decisions>

<specifics>
## Specific Ideas

- Keep visual consistency with existing server experience by reusing ServerCard style.
- Dashboard should stay responsive; no blocking loaders replacing section on refresh.
- Error transparency matters: explicit failure type messaging, but no noisy success toasts.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product/phase requirements
- `.planning/ROADMAP.md` — Phase 9 goal, dependencies, and success criteria.
- `.planning/REQUIREMENTS.md` — API-02, API-03, UI-01, UI-02, REL-01 details.

### Upstream phase decisions and API integration constraints
- `.planning/phases/08-api-client-device-auth/08-CONTEXT.md` — locked auth/token/HWID/error decisions inherited by Phase 09.
- `.planning/phases/08-api-client-device-auth/08-VERIFICATION.md` — confirmed Phase 08 behavior and gap closures.

### Existing code integration points
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — target home-screen composition point.
- `lib/features/api/presentation/providers/default_server_keys_provider.dart` — default key fetch provider contract.
- `lib/features/api/presentation/providers/auth_provider.dart` — token/auth state provider graph.
- `lib/features/server/presentation/providers/active_server_provider.dart` — canonical active-server selection state.
- `lib/features/server/presentation/widgets/server_card.dart` — visual component pattern to reuse.
- `lib/features/server/presentation/screens/server_list_screen.dart` — existing list loading/error/retry interaction patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ServerCard` can be reused for default server preview items (D-04).
- `defaultServerKeysProvider` already exposes AsyncValue fetch contract for key list.
- `activeServerProvider` already drives selected server state and must remain canonical.

### Established Patterns
- Dashboard currently uses centered column sections and card-based widgets.
- Existing server flows use Riverpod AsyncValue loading/error/data patterns with retry actions.
- App-level auth bootstrap already exists in `ArmaApp` and should not be duplicated.

### Integration Points
- Insert Default Servers section in `DashboardScreen` below existing connection/traffic blocks.
- Wire tap actions to existing connection/selection providers, not a parallel state model.
- Use phase-08 API/auth providers for fetch/re-auth paths and error categorization.

</code_context>

<deferred>
## Deferred Ideas

- Auto-update interval UI and background refresh scheduling (Phase 10).
- Multi-device/account linking and richer auth/account UX (post-Phase 10).

</deferred>

---

*Phase: 09-default-servers-home-screen-display*  
*Context gathered: 2026-05-24*
