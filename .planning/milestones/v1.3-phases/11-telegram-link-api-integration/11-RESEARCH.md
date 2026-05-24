# Phase 11: telegram-link-api-integration - Research

**Researched:** 2026-05-24  
**Status:** Ready for planning

## Scope

Implement Telegram linking API integration without adding UI screens in this phase:
- validate Telegram ID input (trim + digits-only + length 5–20)
- call `POST /auth/telegram/link/` with bearer token
- map API/auth failures to typed outcomes for later UI phases

## Recommended Approach

1. Add endpoint method in `ApiClient`:
   - `linkTelegram({required String token, required String telegramId})`
   - `path: '/auth/telegram/link/'`
   - body: `{ "telegram_id": telegramId }`
   - keep existing `_sendWithRetry`, `_decodeJsonMap`, and diagnostics redaction.

2. Add domain outcome model for UI-facing result states:
   - `linked`, `alreadyLinked`, `invalidId`, `unauthorized`, `network`, `server`, `unknown`.

3. Route endpoint through existing auth lifecycle:
   - call endpoint via `AuthRepository.executeWithAuthRetry(...)`
   - preserve one silent re-auth retry on unauthorized.

4. Centralize Telegram ID validation in non-UI layer:
   - trim
   - numeric-only
   - length range 5..20
   - reject before network call.

5. Expose a provider-level submit entrypoint for Phase 12:
   - include duplicate in-flight submit guard.

## File Touchpoints

- `lib/features/api/data/datasources/api_client.dart` (extend)
- `lib/features/api/data/models/telegram_link_response.dart` (new)
- `lib/features/api/domain/entities/telegram_link_outcome.dart` (new)
- `lib/features/api/domain/repositories/telegram_link_repository.dart` (new)
- `lib/features/api/data/repositories/telegram_link_repository_impl.dart` (new)
- `lib/features/api/presentation/providers/telegram_link_provider.dart` (new)
- tests for datasource, repository, provider paths

## Risks / Unknowns

- Backend signal for `already_linked` is not fully specified in current docs (status/body code needs final confirmation).

## Sources

- `.planning/phases/11-telegram-link-api-integration/11-CONTEXT.md`
- `.planning/REQUIREMENTS.md` (v1.3 TGAPI/TGCOMP requirements)
- `docs/api_documentation.md`
- `lib/features/api/data/datasources/api_client.dart`
- `lib/features/api/data/repositories/auth_repository_impl.dart`
- `lib/features/api/domain/repositories/auth_repository.dart`
- `lib/features/api/presentation/providers/auth_provider.dart`
