# Phase 2: Link Status Feedback & Retry UX - Context

**Gathered:** 2026-05-24
**Status:** Ready for planning

<domain>
## Phase Boundary

Finalize the Telegram status-check feedback UX so users clearly understand loading, success, and failure states and can retry immediately when needed.

</domain>

<decisions>
## Implementation Decisions

### Feedback loop behavior (carried forward)
- **D-01:** Keep loading behavior from Phase 1: disable the Step 3 action while request is in flight and show inline spinner in the same button.
- **D-02:** Keep success behavior from Phase 1: show success snackbar and return to dashboard when refreshed state reports `is_guest=false`.
- **D-03:** Keep failure behavior from Phase 1: show error snackbar, stay on the screen, and allow immediate retry from the same Step 3 action.

### the agent's Discretion
- Minor copy tweaks to existing snackbar wording only if needed for consistency.
- Test granularity for edge timing cases, as long as D-01..D-03 remain unchanged.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and mapping
- `.planning/ROADMAP.md` — v1.4 Phase 2 goal and success criteria.
- `.planning/REQUIREMENTS.md` — `TGSTAT-02`.

### Upstream locked decisions
- `.planning/phases/01-telegram-link-status-refresh/01-CONTEXT.md` — locked Step 3 UX defaults being carried forward.
- `.planning/phases/01-telegram-link-status-refresh/01-01-SUMMARY.md` — implemented baseline behavior and test coverage.

### Current implementation surface
- `lib/features/dashboard/presentation/screens/telegram_link_guide_screen.dart` — Step 3 action/loading/success/failure behavior.
- `test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart` — current widget assertions for status-check feedback loop.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Existing `telegram-check-status-button` flow already handles loading lock, success pop, and failure retry.
- Existing widget test harness supports overriding status checker and asserting UI outcomes.

### Established Patterns
- User feedback via `ScaffoldMessenger` snackbars.
- Action-level in-button spinner for short async interactions.
- Retry behavior implemented by re-enabling same action after error.

### Integration Points
- `TelegramLinkGuideScreen._checkLinkStatus()` is the single interaction point for Phase 2 UX adjustments.
- `telegram_link_guide_screen_test.dart` is the canonical verification surface for TGSTAT-02.

</code_context>

<specifics>
## Specific Ideas

- User explicitly chose to keep Phase 1 defaults for loading/success/failure UX in this phase discussion.
- Planning should focus on consistency hardening and verification completeness, not UX redesign.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within Phase 2 scope.

</deferred>

---

*Phase: 02-link-status-feedback-retry-ux*
*Context gathered: 2026-05-24*
