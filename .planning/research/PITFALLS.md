# PITFALLS.md — v1.4 Telegram Link Status & Announcement

## Critical pitfalls

1. **Auth header drift** (`Token` vs `Bearer`) reappears on Telegram link call.
   - Prevent with focused contract tests in API client/repository.
2. **Stale `is_guest` state** after successful linking.
   - Prevent by forcing auth-state refresh when Step 3 check runs and after link success.
3. **App version mismatch** between Settings display and `/auth/device/` payload.
   - Prevent by reusing one shared version source.
4. **Announcement parsing breaks auth path** when values are null/empty.
   - Keep announcement fields nullable and non-blocking.

## UX pitfalls

- Showing announcement block when title/text is empty.
- Repeated status checks causing duplicate requests.
- Read-more bottom sheet not handling long content safely.
