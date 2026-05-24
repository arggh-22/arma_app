# Phase 12: Telegram Link UI & Guided Flow - Context

**Gathered:** 2026-05-24  
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement the Telegram linking UI flow on the home dashboard: add a `Link` entry with Telegram icon and build a guided screen that takes users through opening the bot, getting Telegram ID, pasting it, and submitting link.

</domain>

<decisions>
## Implementation Decisions

### Home screen Link entry
- **D-01:** Use a Dashboard floating action button, not AppBar action or inline card/button.
- **D-02:** FAB label is `Link` and includes a small Telegram icon.
- **D-03:** FAB hides on scroll down and reappears on scroll up.

### Guided screen structure
- **D-04:** Use step cards for instructions (not wizard pages, not a single long paragraph).
- **D-05:** Put a top `Open Telegram Bot` CTA that launches `https://t.me/devarmabot`.
- **D-06:** Show both ID retrieval options explicitly: menu command `Get Telegram ID` and fallback `/my_id`.
- **D-07:** Bottom of screen includes Telegram ID input and primary `Link` submit button.
- **D-08:** Include a dedicated `Paste` action for fast clipboard paste.

### Post-submit behavior
- **D-09:** On successful linking, show success feedback and automatically return to Dashboard.
- **D-10:** On non-success outcomes, stay on guide screen and show outcome-specific feedback.
- **D-11:** For unauthorized outcome, keep user on screen and explicitly prompt re-login.

### the agent's Discretion
- Exact visual styling tokens (spacing, border radius, typography) while matching existing app theme.
- Whether Telegram icon is sourced from available icon packs or a bundled asset, as long as style remains consistent.
- Exact message phrasing per outcome while preserving the behavior contract above.

</decisions>

<specifics>
## Specific Ideas

- User-provided flow to preserve: tap `Link` on home → open Telegram bot → tap `Start` in bot → get ID via `Get Telegram ID` (or `/my_id`) → copy/paste ID in app → tap `Link`.
- Telegram bot URL is fixed: `https://t.me/devarmabot`.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and requirement sources
- `.planning/ROADMAP.md` — Phase 12 goal/success criteria and dependency on Phase 11.
- `.planning/REQUIREMENTS.md` — v1.3 requirement IDs `TGUI-01`, `TGUI-02`.
- `.planning/PROJECT.md` — active milestone context for Telegram linking rollout.

### Upstream Telegram link contracts
- `.planning/phases/11-telegram-link-api-integration/11-CONTEXT.md` — locked API and outcome decisions consumed by UI flow.
- `lib/features/api/presentation/providers/telegram_link_provider.dart` — submit contract and outcome mapping exposed to UI.
- `lib/features/api/domain/entities/telegram_link_outcome.dart` — canonical outcome set for UI state handling.

### Existing UI/navigation patterns to reuse
- `lib/core/router/app_router.dart` — route registration pattern and navigation topology.
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — home-screen layout and scroll container where FAB behavior is integrated.
- `lib/features/dashboard/presentation/widgets/default_servers_section.dart` — existing in-screen feedback pattern via `ScaffoldMessenger`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Dashboard already uses a `SingleChildScrollView`, making scroll-direction-based FAB visibility straightforward to wire.
- Existing Telegram linking provider in API feature exposes a direct `submit(...)` API with typed outcomes for the screen.

### Established Patterns
- GoRouter route additions are centralized in `app_router.dart`.
- Dashboard and feature screens rely on Riverpod + `ConsumerWidget`/`ConsumerStatefulWidget` patterns.
- User feedback is surfaced with `ScaffoldMessenger` snackbars in dashboard-related components.

### Integration Points
- Add new route and Telegram link guide screen widget.
- Add dashboard FAB entry that navigates into the new screen.
- Consume `telegramLinkProvider` submit flow from screen and map outcomes to UI feedback/return behavior.

</code_context>

<deferred>
## Deferred Ideas

- Advanced UX polish and broader reliability hardening targeted for Phase 13.
- Additional analytics/telemetry around link conversion funnel (not in current phase scope).

</deferred>

---

*Phase: 12-telegram-link-ui-guided-flow*  
*Context gathered: 2026-05-24*
