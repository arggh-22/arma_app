# Phase 03 Validation Strategy

**Generated:** 2026-05-24
**Phase:** 03-dashboard-telegram-cta-announcements

## Validation dimensions

1. **CTA correctness by guest state**
   - Guest users see extended Link FAB and route to `/telegram-link`.
   - Linked users see icon-only Telegram FAB and external bot open action.

2. **Announcement visibility correctness**
   - Hidden when both fields are null/empty/whitespace.
   - Visible when title-only, text-only, or both are present.
   - Missing fields are omitted cleanly.

3. **Read-more behavior correctness**
   - Read more shown only when announcement text exists.
   - Tapping opens bottom sheet with full text.

4. **Regression safety**
   - Dashboard scroll hide/show FAB behavior remains unchanged.
   - Existing Phase 1/2 Telegram flow behavior remains unaffected.

## Required automated checks

- `flutter test test/features/api/data/models/device_auth_response_test.dart`
- `flutter test test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart`
- `flutter test test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart`
- `flutter test`

## Minimum acceptance gate

- TGCTA-01/02 and TGANN-01/02 each have explicit widget/unit assertions.
- New announcement data mapping is covered at DTO/domain level.
- No regressions in existing dashboard FAB scroll behavior.
