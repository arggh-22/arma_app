# STACK.md — v1.4 Telegram Link Status & Announcement

## Stack additions

- Reuse the existing app-version source displayed in Settings as the auth payload source.
- If that shared source is static today, make that same source runtime-resolved (do not introduce separate version constants per feature).

## Reuse existing stack

- Existing `http` + `ApiClient` flow.
- Existing Riverpod providers for state orchestration.
- Existing auth repository/device-auth pipeline.
- Material `showModalBottomSheet` for announcement details.

## Avoid

- No new network clients (Dio/Retrofit/etc.).
- No new state framework (Bloc/GetX/etc.).
- No extra announcement/CMS dependencies for this milestone.
