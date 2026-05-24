# Phase 03 Research — Dashboard Telegram CTA & Announcements

**Researched:** 2026-05-24
**Confidence:** High

## Current-state findings

- `DashboardScreen` currently always renders an extended Link FAB (`dashboard-telegram-link-fab`) and already has scroll hide/show behavior via `_showLinkFab` + `_onScroll`.
- `/auth/device/` docs include `is_guest`, `announcement_title`, `announcement_text`, but `DeviceAuthResponse` currently maps only `token`, `is_guest`, `user_id`.
- `AuthState` currently has no announcement fields; dashboard currently does not read auth state for CTA/announcement behavior.
- Existing test baseline for dashboard FAB behavior is in `dashboard_screen_telegram_link_fab_test.dart`.

## Recommended implementation approach

1. **Single source of truth**
   - Extend existing auth flow (`DeviceAuthResponse` -> `AuthState` -> persisted auth state -> `authStateProvider`).
   - Do not introduce a separate dashboard announcement store/path.

2. **CTA behavior**
   - Keep existing FAB position and scroll behavior unchanged.
   - Branch by `isGuest`:
     - `true`: existing extended Link FAB to `/telegram-link`
     - `false`: icon-only Telegram FAB opening fixed `https://t.me/devarmabot` externally

3. **Announcement behavior**
   - Insert announcement card between statistics block and `DefaultServersSection`.
   - Show if either trimmed `announcementTitle` or trimmed `announcementText` is non-empty.
   - Render available parts only (no placeholders).
   - Show **Read more** only when announcement text exists; open bottom sheet with full text.

## File-by-file change map

- `lib/features/api/data/models/device_auth_response.dart`
  - Parse optional `announcement_title` / `announcement_text`
  - Pass mapped values to domain
- `lib/features/api/domain/entities/auth_state.dart`
  - Add nullable `announcementTitle` / `announcementText`
  - Regenerate freezed/json outputs
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
  - Watch auth state
  - Apply guest/linked FAB branch (D-01..D-03)
  - Add announcement card + read-more bottom sheet (D-04..D-09)
- Tests:
  - `test/features/api/data/models/device_auth_response_test.dart`
  - `test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart`
  - new announcement-focused dashboard widget test file

## Risks / pitfalls

- Regressing scroll/FAB behavior by changing key/visibility logic.
- Rendering empty announcement card if whitespace-only values are not trimmed.
- State desync if announcement data is routed outside existing auth state path.
- Linked CTA opening dynamic/untrusted URLs (must stay fixed bot URL).

## Verification focus

- Guest vs linked CTA branch behavior.
- Announcement visibility matrix (none/title/text/both, trimmed content).
- Read-more visibility and bottom-sheet full text rendering.
- Existing dashboard scroll hide/show behavior remains intact.

## Sources

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/phases/03-dashboard-telegram-cta-announcements/03-CONTEXT.md`
- `docs/api_documentation.md`
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/api/data/models/device_auth_response.dart`
- `lib/features/api/domain/entities/auth_state.dart`
- `lib/features/api/presentation/providers/auth_provider.dart`
- `test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart`
