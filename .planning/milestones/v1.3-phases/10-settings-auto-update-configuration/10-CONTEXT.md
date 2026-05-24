# Phase 10: Settings & Auto-Update Configuration - Context

**Gathered:** 2026-05-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Add user-facing auto-update settings and periodic refresh behavior for default servers, including retry policy, cleanup behavior, and persistence across sessions.

</domain>

<decisions>
## Implementation Decisions

### Scheduling strategy
- **D-01:** Auto-update uses background scheduler plus fallback app-open check.
- **D-02:** If background execution is blocked by OS restrictions, run missed refresh immediately on next app open and show subtle updated state.

### Settings UX
- **D-03:** Rename “Default Servers” label context to **“Arma VPN”** for this settings feature.
- **D-04:** Add a new **“Arma VPN settings”** section at the top of Settings screen.
- **D-05:** Auto-update interval selector uses **radio list** with 4 options:
  - Disabled
  - Every 12 Hours
  - Every 24 Hours
  - Every 7 Days
- **D-06:** Default selected interval is **Disabled**.

### Retry/backoff policy
- **D-07:** Background refresh retries use exponential backoff: **1m, 5m, 15m**, then stop until next scheduled cycle.
- **D-08:** Unauthorized/auth failures do **one silent re-auth attempt**, then stop and wait for next schedule (no full retry ladder).

### Expired server cleanup
- **D-09:** Remove expired default servers immediately after each successful fetch sync.
- **D-10:** If currently connected to a now-expired default server, keep connection until user disconnects; hide/disable it for future selection.

### the agent's Discretion
- Exact subtle “updated” indicator style and microcopy.
- Radio-item subtext formatting and spacing details.

</decisions>

<specifics>
## Specific Ideas

- Settings should expose this feature clearly at top-level under “Arma VPN settings”.
- Refresh reliability should not depend solely on background job availability.
- Cleanup must be safe for active connection continuity.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Product requirements and roadmap
- `.planning/ROADMAP.md` — Phase 10 goal, requirements, success criteria.
- `.planning/REQUIREMENTS.md` — DATA-01, DATA-02, DATA-03, COMPAT-01, COMPAT-02 definitions.

### Upstream implementation context
- `.planning/phases/09-default-servers-home-screen-display/09-CONTEXT.md` — dashboard/server display decisions inherited by auto-update behavior.
- `.planning/phases/09-default-servers-home-screen-display/09-VERIFICATION.md` — phase completion and runtime verification notes.
- `.planning/phases/09-default-servers-home-screen-display/09-SECURITY.md` — security constraints relevant to refresh/storage paths.

### Existing code integration points
- `lib/features/settings/presentation/screens/settings_screen.dart` — target for new settings section.
- `lib/features/settings/presentation/providers/*` — settings persistence patterns.
- `lib/features/dashboard/presentation/providers/default_servers_provider.dart` — refresh/retry provider behavior from Phase 09.
- `lib/features/api/data/datasources/default_server_cache_datasource.dart` — cache read/write and cleanup integration point.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing settings persistence/provider patterns should be reused for interval option state.
- Existing default-server provider and cache layer from Phase 09 should remain single source of truth for refresh results.

### Established Patterns
- Riverpod-based AsyncValue/provider orchestration is already used for default server fetching.
- Typed failure mapping already exists for timeout/offline/unauthorized/server paths.

### Integration Points
- Add interval setting into Settings UI + persisted value.
- Background scheduler and app-open fallback should call the same refresh path to avoid duplicated logic.
- Expiry cleanup runs after successful sync, before writing final cache state.

</code_context>

<deferred>
## Deferred Ideas

- Full account/device management UX beyond silent re-auth handling.
- Rich in-app sync history/audit timeline UI.

</deferred>

---

*Phase: 10-settings-auto-update-configuration*  
*Context gathered: 2026-05-24*
