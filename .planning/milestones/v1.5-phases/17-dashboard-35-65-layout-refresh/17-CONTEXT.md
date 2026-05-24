# Phase 17: Dashboard 35/65 Layout Refresh - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Refresh dashboard composition to a 35/65 visual split while preserving existing behavior, provider contracts, and interaction logic.

</domain>

<decisions>
## Implementation Decisions

### Layout strategy
- **D-17-01:** Keep current scroll-based dashboard structure and emulate 35/65 visually (not a strict fixed-height split container).
- **D-17-02:** Apply top/bottom visual grouping so top area reads as 35% and bottom area reads as 65% in normal viewport conditions.

### Selected-server parked treatment
- **D-17-03:** Keep existing `ActiveServerCard` component as the selected-server surface.
- **D-17-04:** Add clear parked/highlight treatment to `ActiveServerCard` rather than replacing component structure.

### Bottom panel composition
- **D-17-05:** In bottom panel, render announcements first, then default-server cards.
- **D-17-06:** If announcement content is absent, hide announcement block entirely and let default servers move up.

### Behavior guardrails
- **D-17-07:** Preserve existing connect/disconnect behavior, default-server tap behavior, and provider wiring.
- **D-17-08:** Preserve existing announcement read-more behavior and sheet interaction.

### the agent's Discretion
- Exact visual affordance for parked highlight (border/accent/background), provided it is clearly distinguishable.
- Final spacing tokens used to communicate 35/65 visual balance in scroll layout.
- Minor typography emphasis adjustments within existing design language.

</decisions>

<specifics>
## Specific Ideas

- User wants a dashboard visual refresh, not behavior rewrites.
- 35/65 should be achieved as a visual composition in current scrolling layout.
- Selected server should stay in current card paradigm, just visually "parked"/highlighted.
- Announcements should appear above defaults when present.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone and requirement contract
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`

### Existing dashboard implementation
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/dashboard/presentation/widgets/active_server_card.dart`
- `lib/features/dashboard/presentation/widgets/default_servers_section.dart`
- `lib/features/dashboard/presentation/widgets/connect_button.dart`

### Existing tests/patterns to preserve
- `test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart`
- `test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart`
- `test/features/dashboard/presentation/widgets/default_servers_section_test.dart`

### Upstream phase context
- `.planning/phases/16-servers-screen-defaults-integration/16-CONTEXT.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DashboardScreen` already contains all phase-relevant sections (connect button, status, timer, active server, stats, announcements, defaults).
- `ActiveServerCard` provides existing selected-server UI and navigation affordance.
- `DefaultServersSection` and announcement card logic already support current data/interaction behavior.

### Established Patterns
- Dashboard layout is currently linear in a `SingleChildScrollView`; visual grouping should layer on top of this pattern.
- Announcement card visibility is already content-driven (`hasAnnouncement`).

### Integration Points
- Primary composition updates happen in `dashboard_screen.dart`.
- Parked visual treatment likely belongs in `active_server_card.dart`.
- Regression coverage should extend dashboard screen widget tests for ordering/visibility and top/bottom composition cues.

</code_context>

<deferred>
## Deferred Ideas

- Device-class adaptive ratio tuning (e.g., tablet-specific 35/65 variation).
- New data contracts for announcements or default servers.
- Reworking core connection/auth/server-selection behavior.

</deferred>

---

*Phase: 17-dashboard-35-65-layout-refresh*
*Context gathered: 2026-05-25*
