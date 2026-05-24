# Phase 1: Telegram Link Status Refresh — Research

**Researched:** 2026-05-24  
**Confidence:** High

## Key findings

1. Step 3 status-check can reuse existing Telegram guide screen patterns (disabled in-flight button, inline spinner, snackbar feedback, `maybePop` on success).
2. `/auth/device/` refresh should run through existing auth repository flow, not direct screen-level API calls.
3. `auth_provider.dart` currently hardcodes `appVersion: '1.0.0'`, while Settings displays `AppConstants.appVersion` (`1.0.2`); Phase 1 should unify auth payload to the shared Settings source.
4. Existing `DeviceAuthResponse` already parses `is_guest`, so no new endpoint is needed for link-status determination.

## Recommended implementation path

- Add Step 3 **Check Link Status** action in `telegram_link_guide_screen.dart`.
- Add/extend auth provider method to force `/auth/device/` refresh and update auth state.
- Replace stale hardcoded auth app-version value with shared source used by Settings (`AppConstants.appVersion` currently).
- Apply locked UX decisions from `01-CONTEXT.md` for loading/success/failure behavior.

## Affected files (expected)

- `lib/features/dashboard/presentation/screens/telegram_link_guide_screen.dart`
- `lib/features/api/presentation/providers/auth_provider.dart`
- `lib/core/constants/app_constants.dart` (or shared version source wiring)
- `lib/features/api/data/repositories/auth_repository_impl.dart` (if refresh method path needs expansion)
- `test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart`
- `test/features/api/presentation/providers/auth_provider_test.dart`

## Risks / pitfalls

- Status check using cached token path without a fresh `/auth/device/` call can leave stale `is_guest`.
- Version source drift can return stale app version in auth payload.
- Screen-level direct API usage can bypass existing auth retry/state persistence patterns.

## Validation Architecture

### Test infrastructure

| Property | Value |
|----------|-------|
| Framework | flutter_test |
| Config file | none |
| Quick run command | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart` |
| Full suite command | `flutter test` |

### Requirement → verification map

| Requirement | Verification target | Type |
|-------------|---------------------|------|
| TGSTAT-01 | Step 3 check triggers refresh call + UI state transitions | widget/provider |
| TGVER-01 | Auth payload app version uses shared Settings source | provider/unit |

### Wave 0 gaps

- Add/extend tests for Step 3 button loading/retry/success flows.
- Add provider test for auth version source wiring.
