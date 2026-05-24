# Phase 3: Dashboard Telegram CTA & Announcements - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Update dashboard behavior so CTA adapts by guest/link status and announcements render conditionally with a Read more bottom-sheet flow.

</domain>

<decisions>
## Implementation Decisions

### Dashboard CTA behavior
- **D-01:** Keep current floating CTA position and scroll hide/show behavior.
- **D-02:** When `is_guest=true`, keep current extended **Link** FAB routing to `/telegram-link`.
- **D-03:** When `is_guest=false`, replace CTA with an icon-only Telegram FAB (no text label) that opens `@devarmabot` externally.

### Announcement rendering
- **D-04:** Render announcement block when either `announcement_title` OR `announcement_text` is non-empty after trimming.
- **D-05:** If one field is missing/empty, render only the available part (no placeholder text).
- **D-06:** Place announcement block between dashboard statistics section and default servers section.
- **D-07:** Style announcement block using existing dashboard card/surface visual language (no warning/banner redesign).

### Read more behavior
- **D-08:** Show **Read more** only when `announcement_text` is non-empty.
- **D-09:** Tapping **Read more** opens a bottom sheet containing full `announcement_text`.

### the agent's Discretion
- Exact line-clamp values for inline preview text.
- Final icon sizing and spacing details as long as D-01..D-09 are preserved.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and mapping
- `.planning/ROADMAP.md` — v1.4 Phase 3 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `TGCTA-01`, `TGCTA-02`, `TGANN-01`, `TGANN-02`.

### API/auth source for dashboard decisioning
- `docs/api_documentation.md` — `/auth/device/` response contract, including announcement fields.
- `lib/features/api/data/models/device_auth_response.dart` — current DTO parse surface for `/auth/device/`.
- `lib/features/api/domain/entities/auth_state.dart` — persisted auth state contract used by UI.
- `lib/features/api/presentation/providers/auth_provider.dart` — provider access path for auth state.

### Dashboard implementation surface
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — current FAB behavior and content ordering.
- `test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart` — current FAB behavior tests.
- `lib/features/dashboard/presentation/screens/telegram_link_guide_screen.dart` — existing Telegram bot URI/open pattern to keep consistent.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing dashboard already has scroll-aware FAB visibility toggling in `_onScroll`.
- Existing Telegram guide flow includes reusable bot-open URL pattern (`https://t.me/devarmabot`).
- Existing dashboard screen composition has clear insertion point between statistics and default servers.

### Established Patterns
- Dashboard content uses card/surface widgets and gap-based vertical spacing.
- Navigation and external actions are already key-based and test-driven in dashboard tests.
- Auth-driven behavior should flow through provider state rather than ad-hoc API calls in UI.

### Integration Points
- `DashboardScreen` build method (FAB branch + content list) is the primary integration point.
- Auth state source for `is_guest` + announcement payload fields must be available to dashboard state/read path.
- Dashboard screen tests need expansion for guest/linked CTA variants and announcement visibility/read-more behavior.

</code_context>

<specifics>
## Specific Ideas

- User explicitly chose icon-only Telegram CTA for linked users, while preserving current guest **Link** CTA.
- User explicitly chose announcement visibility when either title or text exists, with graceful partial rendering.
- User explicitly chose Read more visibility only when full text exists, opened in bottom sheet.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 3 scope.

</deferred>

---

*Phase: 03-dashboard-telegram-cta-announcements*
*Context gathered: 2026-05-24*
