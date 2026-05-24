# SUMMARY.md — v1.4 Research Synthesis

## Stack additions

- Use the existing Settings app-version source for auth payloads.
- If needed, evolve that shared source to runtime-resolved version (single source of truth).

## Feature table stakes

- Step 3 **Check Link Status** button calls `/auth/device/`.
- Dashboard CTA switches from Link to Telegram bot based on `is_guest`.
- Announcement area appears only when title/text is non-empty and supports read-more bottom sheet.

## Watch out for

- Telegram auth-header contract regression.
- Stale `is_guest` state after linking.
- Hardcoded/stale app_version payload.
- Announcement null/empty handling and UI overflow.
