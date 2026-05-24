# ARCHITECTURE.md — v1.4 Telegram Link Status & Announcement

## Integration approach

- Reuse `/auth/device/` as the status snapshot source for:
  - `is_guest` (CTA switching)
  - `announcement_title`, `announcement_text` (announcement UI)
  - `app_version` request payload
- Keep `AuthState` as the single UI source for guest/link state and announcement data.

## Key wiring points

1. Telegram link screen adds Step 3 button that triggers auth-state refresh via existing auth repository/provider flow.
2. Dashboard CTA is derived from `is_guest`:
   - guest => Link CTA
   - linked => Telegram bot CTA
3. Announcement banner is rendered conditionally between statistics and default servers.
4. Read-more action opens bottom sheet with full `announcement_text`.
5. Auth payload app version comes from the same version source used in Settings.

## Layer boundaries

- API client: request/response transport only.
- Repository/providers: refresh orchestration + state updates.
- UI widgets: display based on provider state; no direct networking.
