# Plan 03-01 Summary — Phase 03 Dashboard Telegram CTA & Announcements

## Outcome

Completed TGCTA-01, TGCTA-02, TGANN-01, and TGANN-02 by wiring announcement data through auth state, adding guest/linked dashboard CTA branching, and implementing conditional announcement + read-more bottom sheet behavior with test coverage.

## Delivered changes

- `lib/features/api/data/models/device_auth_response.dart`
  - Added optional `announcement_title` / `announcement_text` parsing and mapping to domain.
- `lib/features/api/domain/entities/auth_state.dart` (+ generated files)
  - Added nullable `announcementTitle` / `announcementText` fields for persisted auth state.
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
  - Added auth-driven CTA branch:
    - guest: existing extended **Link** FAB to `/telegram-link`
    - linked: icon-only Telegram FAB opening `https://t.me/devarmabot`
  - Added conditional announcement card between statistics and default servers.
  - Added **Read more** action (only when text exists) opening bottom sheet with full announcement text.
- `test/features/api/data/models/device_auth_response_test.dart`
  - Added announcement field mapping coverage and malformed-type validation.
- `test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart`
  - Added linked-user icon-only Telegram FAB behavior test.
- `test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart`
  - Added announcement visibility/read-more/placement matrix coverage.
- Localization updates:
  - Added dashboard announcement + Telegram CTA labels across ARB/localization generated files.

## Verification

- ✅ `flutter test test/features/api/data/models/device_auth_response_test.dart`
- ✅ `flutter test test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart`
- ✅ `flutter test test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart`
- ⚠️ `flutter test` still reports existing unrelated baseline failure in `test/widget_test.dart` (`No ProviderScope found` smoke test path).

## Requirement coverage

- ✅ `TGCTA-01`
- ✅ `TGCTA-02`
- ✅ `TGANN-01`
- ✅ `TGANN-02`
