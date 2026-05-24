# FEATURES.md — v1.4 Telegram Link Status & Announcement

## Table stakes

- Add Step 3 **Check Link Status** action on Telegram link screen that refreshes `/auth/device/` state.
- Dashboard CTA switches by backend `is_guest`:
  - `true` → keep Link flow entry.
  - `false` → show Telegram bot button.
- `/auth/device/` sends real runtime `app_version` (no hardcoded version).
- Announcement block appears between statistics and default servers only when title/text is present.
- `Read more` opens bottom sheet with `announcement_text`.

## Key edge cases

- Null/empty `announcement_title` or `announcement_text` must hide announcement UI.
- Status refresh, link submit, and auth retry flows must avoid stale/overwritten `is_guest`.
- Announcement text length and localization should not break layout.

## Anti-features

- No aggressive polling for status checks.
- No blocking modal announcements.
- No client-side assumptions overriding backend `is_guest`.
