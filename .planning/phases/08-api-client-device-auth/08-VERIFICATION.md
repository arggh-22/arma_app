---
phase: 08-api-client-device-auth
verified: 2026-05-23T23:27:53Z
status: gaps_found
score: 6/8 must-haves verified
overrides_applied: 0
gaps:
  - truth: "User can authenticate their device with your VPN API on first app launch using HWID + device info"
    status: failed
    reason: "Device auth flow is implemented but never triggered from app startup or any currently wired screen/provider consumer."
    artifacts:
      - path: "lib/features/api/presentation/providers/auth_provider.dart"
        issue: "Provides authToken/authState providers but no app-level consumer triggers authenticateDevice on first launch."
      - path: "lib/features/api/presentation/providers/default_server_keys_provider.dart"
        issue: "Provider exists but has no usage site outside generated files."
    missing:
      - "Wire first-launch bootstrap path to read authTokenProvider or call AuthRepository.authenticateDevice."
      - "Connect provider flow into an app entry/home initialization path."
  - truth: "Device HWID persists across app updates and reinstalls"
    status: failed
    reason: "Persistence is app-local Hive + fallback to DeviceInfoPlugin.androidInfo.id (Build.ID), which is not a per-device stable ID contract across updates/reinstalls."
    artifacts:
      - path: "lib/features/api/data/services/device_id_service.dart"
        issue: "Uses androidInfo.id instead of a stronger stable device identifier strategy; reinstall persistence is not guaranteed by local Hive storage alone."
    missing:
      - "Use a stable Android identifier strategy aligned with requirement semantics and documented platform constraints."
      - "Add tests/documentation proving behavior across update/reinstall scenarios."
---

# Phase 8: API Client & Device Authentication Verification Report

**Phase Goal:** Build the API client library and implement device authentication flow.  
**Verified:** 2026-05-23T23:27:53Z  
**Status:** gaps_found  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | User can authenticate their device with your VPN API on first app launch using HWID + device info | ✗ FAILED | `ApiClient.authenticateDevice` + repository exist, but grep across `lib/` shows no startup/UI consumer of `authTokenProvider` / `defaultServerKeysProvider`; flow is not launched automatically. |
| 2 | API token is stored securely in Hive (encrypted) and automatically refreshed on expiry | ✓ VERIFIED | `AuthLocalDatasource.openEncryptedBox(...)` uses `HiveAesCipher` with secure-storage key; `AuthRepositoryImpl.getValidToken()` checks expiry threshold and re-authenticates. |
| 3 | APIClient class provides methods for device auth and token management | ✓ VERIFIED | `ApiClient.authenticateDevice()` and `ApiClient.getKeys()` implemented; token lifecycle managed by `AuthRepositoryImpl` in the same API client layer. |
| 4 | Auth errors are handled gracefully with retry logic | ✓ VERIFIED | `ApiClient._sendWithRetry()` retries transient failures once; does not retry 401/4xx; repository handles one-shot 401 re-auth replay. |
| 5 | Device HWID persists across app updates and reinstalls | ✗ FAILED | `DeviceIdService` persists to Hive but falls back to `androidInfo.id` (`Build.ID`), which is not a guaranteed stable reinstall/update identity contract. |
| 6 | Device-auth and key API payloads decode into stable typed entities for downstream providers | ✓ VERIFIED | `DeviceAuthResponse.fromJson()/toDomain()` and `DefaultServerKeyModel.fromJson()/toDomain()` are strict and typed. |
| 7 | Phase 08 API calls read base URL, API-key header, and timeout values from one shared config source | ✓ VERIFIED | `ApiClient` defaults to `AppConfig.apiBaseUrl/apiKeyHeaderValue/connectTimeout/readTimeout/transientRetryDelay`. |
| 8 | Build dependencies include packages required for platform device ID lookup and UUID fallback generation | ✓ VERIFIED | `pubspec.yaml` includes `device_info_plus`, `flutter_secure_storage`, and `uuid`. |

**Score:** 6/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `lib/features/api/domain/entities/auth_state.dart` | Canonical auth contract | ✓ VERIFIED | Freezed/json entity with token/auth/device fields. |
| `lib/features/api/domain/entities/default_server_key.dart` | Canonical key contract | ✓ VERIFIED | Freezed/json key entity with API fields. |
| `lib/config/app_config.dart` | Shared API constants | ✓ VERIFIED | Base URL, API key header/value, timeouts, retry delay centralized. |
| `lib/features/api/data/datasources/auth_local_datasource.dart` | Encrypted auth/device persistence | ✓ VERIFIED | AES encrypted box open + read/write/clear auth + device ID read/write. |
| `lib/features/api/data/services/device_id_service.dart` | Stable device_id resolver | ⚠️ PARTIAL | Persistence and fallback implemented; identifier stability across update/reinstall not proven. |
| `lib/main.dart` | Auth box bootstrap wiring | ✓ VERIFIED | Opens encrypted `auth_state` box before `runApp()`. |
| `lib/features/api/data/datasources/api_client.dart` | HTTP client + retry policy | ✓ VERIFIED | Auth and keys endpoints + typed retry/error handling. |
| `lib/features/api/data/repositories/auth_repository_impl.dart` | Token lifecycle orchestration | ✓ VERIFIED | Expiry check, re-auth, one replay on 401, persistence update. |
| `lib/features/api/presentation/providers/auth_provider.dart` | Riverpod auth provider graph | ✓ VERIFIED | ApiClient/AuthRepository providers + authToken/authState providers compiled and tested. |
| `lib/features/api/presentation/providers/default_server_keys_provider.dart` | Keys FutureProvider with manual retry contract | ✓ VERIFIED | `defaultServerKeys` provider calls repository+api and supports `ref.refresh`. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `device_auth_response.dart` | `auth_state.dart` | `toDomain(...)` mapping | WIRED | `DeviceAuthResponse.toDomain()` returns `AuthState`. |
| `default_server_key_model.dart` | `default_server_key.dart` | model mapper | WIRED | `DefaultServerKeyModel.toDomain()` returns `DefaultServerKey`. |
| `main.dart` | `auth_state` Hive box | encrypted box on startup | WIRED | `AuthLocalDatasource.openEncryptedBox(...)` called before app run. |
| `device_id_service.dart` | `auth_local_datasource.dart` | persisted deviceId read/write | WIRED | `readDeviceId()`/`writeDeviceId(...)` used in `resolveDeviceId()`. |
| `auth_provider.dart` | `auth_repository_impl.dart` | provider dependency | WIRED | `authRepositoryProvider` returns `AuthRepositoryImpl(...)`. |
| `default_server_keys_provider.dart` | `api_client.dart` | tokenized key fetch | WIRED | Provider reads `apiClientProvider` and calls `apiClient.getKeys(token)`. |
| `auth_repository_impl.dart` | `auth_local_datasource.dart` | persist refreshed token state | WIRED | `writeAuthState(...)` on auth/re-auth path. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `auth_provider.dart` (`authToken`) | `token` | `AuthRepository.getValidToken()` -> local auth state or `ApiClient.authenticateDevice()` | Yes (repository/network-backed, not static) | ✓ FLOWING |
| `default_server_keys_provider.dart` | `models` | `ApiClient.getKeys(token)` | Yes (HTTP response decode to models) | ✓ FLOWING |
| Startup auth trigger path | N/A | No app bootstrap/provider consumer found | No | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| API client contract + retry behavior | `flutter test .../api_client_test.dart -r compact` | Passed | ✓ PASS |
| Token lifecycle + 401 re-auth replay | `flutter test .../auth_repository_impl_test.dart -r compact` | Passed | ✓ PASS |
| Encrypted auth storage + device ID persistence | `flutter test .../auth_local_datasource_test.dart .../device_id_service_test.dart -r compact` | Passed | ✓ PASS |
| Provider restore/token resolution behavior | `flutter test .../auth_provider_test.dart -r compact` | Passed | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| API-01 | 08-01/02/03 | Device auth flow with persisted HWID + token lifecycle | ✗ BLOCKED | Auth flow exists but no first-launch trigger wiring; HWID stability across updates/reinstalls not demonstrated. |
| SEC-01 (partial) | 08-01/02/03 | Encrypted credential storage and no plaintext logs | ✓ SATISFIED | Encrypted Hive auth box with secure-storage key; tests assert no plaintext print usage in device ID flow; no token/HWID logging found in phase files. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|
| `lib/features/api/data/services/device_id_service.dart` | 26-28 | Uses `androidInfo.id` (Build.ID) as hardware identity | ⚠️ Warning | Identifier stability/uniqueness guarantees are weaker than requirement intent. |

### Gaps Summary

Phase 08 successfully built most API/auth infrastructure (client, repository, encrypted storage, providers, tests), but goal achievement is blocked by two outcome gaps:
1) Device auth is not actually triggered on first launch in current app wiring.
2) HWID persistence contract across updates/reinstalls is not sufficiently satisfied/proven by current identifier strategy.

---

_Verified: 2026-05-23T23:27:53Z_  
_Verifier: the agent (gsd-verifier)_
