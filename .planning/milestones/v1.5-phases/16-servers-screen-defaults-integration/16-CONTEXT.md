# Phase 16: Servers Screen Defaults Integration - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Add default servers to the Servers screen as a dedicated collapsible section above imported/custom groups, while preserving existing server interaction behavior and existing imported-group behavior.

</domain>

<decisions>
## Implementation Decisions

### Section placement and visibility
- **D-01:** Render a dedicated default-servers section above imported/custom server groups.
- **D-02:** Show default-servers section only in normal mode; hide it in multi-select mode.

### Section collapse behavior
- **D-03:** Default-servers section is collapsible.
- **D-04:** Section always starts expanded (no persisted collapse state).

### Item presentation
- **D-05:** In Servers screen, default servers use the same compact row style as imported server rows (replaces prior card-style assumption for this phase).
- **D-06:** Selected default server must remain visibly identifiable in row UI.

### Tap behavior parity
- **D-07:** Tapping a default server follows existing behavior parity: select it; if currently connected to a different server, disconnect then reconnect to tapped server.

### the agent's Discretion
- Exact iconography/spacing for compact default rows.
- Whether selected-state emphasis is badge-first, border-first, or text-weight-first (as long as it is clearly visible).
- Microcopy for empty/default-state messaging if defaults list is unavailable.

</decisions>

<specifics>
## Specific Ideas

- User explicitly requested collapsible behavior parity with existing key/sub-link group interactions.
- User explicitly changed Servers-screen default-server visual preference from cards to compact rows.
- Preserve behavior parity with existing Servers flow instead of adding new confirmation steps.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement contract
- `.planning/ROADMAP.md` — Phase 16 goal, requirements, and success criteria.
- `.planning/REQUIREMENTS.md` — SRVD-01..SRVD-04 requirement definitions and traceability mapping.
- `.planning/PROJECT.md` — milestone objective and scope boundary.

### Existing UI and behavior patterns to reuse
- `lib/features/server/presentation/screens/server_list_screen.dart` — existing grouped/collapsible imported-server UX, multi-select behavior, and row interaction pattern.
- `lib/features/dashboard/presentation/widgets/default_servers_section.dart` — existing default-server data rendering and tap-to-switch behavior used on dashboard.
- `lib/features/server/presentation/providers/active_server_provider.dart` — selected-server source of truth.
- `lib/features/connection/presentation/providers/connection_provider.dart` — disconnect/reconnect behavior used for server switching.
- `lib/features/dashboard/presentation/providers/default_servers_provider.dart` — default-server state source (refresh/offline/failure handling).

### Research guidance
- `.planning/research/SUMMARY.md` — milestone-level sequence, risks, and guardrails for v1.5.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ServerListScreen` already supports collapsible groups, server-row selection, and multi-select mode boundaries.
- `DefaultServersSection` already encapsulates default-server loading/failure states and tap behavior.
- `activeServerProvider` + `connectionProvider` already encode the server-switch behavior to preserve.

### Established Patterns
- Imported servers are rendered as compact rows grouped by `groupName`; this pattern should anchor default-server row visuals for Phase 16.
- Multi-select mode changes interaction affordances; new default section must respect this mode.

### Integration Points
- Insert default-servers section into `ServerListScreen` list composition before imported groups.
- Reuse default-server data from existing provider instead of adding new datasource/state contracts.
- Route default-row tap through the existing active-server + connection switch path.

</code_context>

<deferred>
## Deferred Ideas

- Persisting collapse state for default section across app restarts.
- Reintroducing card-based UI for default servers in Servers screen.
- Any connection-flow confirmation dialog or behavior changes (kept out of scope for Phase 16).

</deferred>

---

*Phase: 16-servers-screen-defaults-integration*
*Context gathered: 2026-05-25*
