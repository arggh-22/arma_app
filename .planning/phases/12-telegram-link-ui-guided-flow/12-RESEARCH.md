# Phase 12: Telegram Link UI & Guided Flow - Research

**Researched:** 2026-05-24  
**Status:** Ready for planning

## Scope alignment

Phase 12 focuses on UI flow only (home entry + guided screen) and consumes the existing Telegram linking API/provider contract from Phase 11.

## Key implementation guidance

1. **Navigation shape**
   - Add a dedicated route (e.g. `/telegram-link`) in `lib/core/router/app_router.dart`.
   - Navigate from Dashboard via `context.push(...)`, matching existing detail-screen routing style.

2. **Dashboard Link entry**
   - Implement as `FloatingActionButton.extended` with `Link` label and Telegram icon.
   - Use scroll-direction visibility behavior: hide on down scroll, show on up scroll.
   - Current `DashboardScreen` already uses `SingleChildScrollView`, so this can be wired with scroll notifications or a scroll controller.

3. **Guided screen composition**
   - Build a dedicated screen with:
     - top `Open Telegram Bot` CTA for `https://t.me/devarmabot`
     - step cards that explicitly include `Get Telegram ID` and `/my_id`
     - Telegram ID input + `Paste` action + primary `Link` button
   - Use existing app theming and feedback style (`ScaffoldMessenger`).

4. **Submit and outcomes**
   - Reuse `telegramLinkProvider` for submit; do not reimplement validation/network logic in UI.
   - Map `TelegramLinkOutcome` to UX:
     - `linked` → success feedback + pop back to Dashboard
     - `unauthorized` → stay on screen + explicit re-login prompt
     - others (`already_linked`, `invalid_id`, `network`, `server`, `unknown`) → stay + specific message

5. **URL and clipboard behavior**
   - Use `url_launcher` for opening the bot URL.
   - For launch failure, show actionable error feedback.
   - Use existing clipboard helper/utilities for paste flow.

## Recommended file map

- `lib/core/router/app_router.dart` (new route)
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` (FAB + scroll visibility)
- `lib/features/dashboard/presentation/screens/telegram_link_guide_screen.dart` (new screen)
- optional small reusable guide-card widget under `features/dashboard/presentation/widgets/`
- localization files for new strings

## Test strategy

- Add widget tests for Dashboard FAB presence, hide/show on scroll, and route navigation.
- Add widget tests for guided screen steps, bot CTA, paste behavior, and submit button states.
- Add/extend provider interaction tests only where UI integration needs extra outcome assertions (provider core behavior already covered in Phase 11 tests).

## Risks and mitigations

- **Risk:** URL launch fails on some devices.  
  **Mitigation:** user-visible failure feedback; keep flow recoverable.

- **Risk:** empty/invalid clipboard content.  
  **Mitigation:** validate pasted value and show clear message before submit.

- **Risk:** duplicate rapid submit taps.  
  **Mitigation:** disable submit while in-flight and rely on provider in-flight guard.

## Validation Architecture

- Requirement `TGUI-01` validation: Dashboard shows `Link` action (Telegram icon), launches guide screen, and respects hide/show-on-scroll behavior.
- Requirement `TGUI-02` validation: Guide screen contains full step sequence, bot link action, ID retrieval instructions, paste action, and link submit flow with actionable controls.
- Verification should include widget-level coverage for navigation and interaction states, plus outcome-driven messaging behavior.

---

*Phase: 12-telegram-link-ui-guided-flow*  
*Research gathered: 2026-05-24*
