# Phase 08: API Client & Device Authentication — Design Context

## Objective
Build the API client layer that enables the app to authenticate devices with the custom VPN server backend and fetch server lists. This phase establishes the foundation for server display (Phase 09) and auto-update mechanisms (Phase 10).

## Requirements Covered
- **API-01:** RESTful client for device auth + key fetching
- **API-02:** Automatic token management and refresh
- **API-03:** Persistent device identification across app sessions
- **SEC-01:** Encrypted token storage at rest
- Integration layer for Phase 09 (home screen display)

---

## Locked Design Decisions

### 1. HTTP Client Pattern
**Decision:** Riverpod `FutureProvider` / `AsyncValue` pattern (not service-based singleton)

**Rationale:**
- Automatic caching managed by Riverpod eliminates manual cache invalidation
- Built-in `AsyncValue<T>` handles loading/error/data states seamlessly
- Integrates cleanly with existing Riverpod architecture (aligns with subscription_provider pattern)
- Testability: Mock providers trivially by overriding in tests
- No manual Future/Stream plumbing needed

**Implementation Pattern:**
```dart
@riverpod
Future<List<ServerKey>> fetchServerKeys(FetchServerKeysRef ref) async {
  final token = await ref.watch(authTokenProvider.future);
  return apiClient.getKeys(token);
}
```

**Why NOT service-based:**
- Would duplicate Riverpod caching (Riverpod layer + service layer = 2× memory)
- Hides loading/error states from UI (AsyncValue provides them out-of-box)
- Adds ceremony without benefit in a Riverpod-first codebase

---

### 2. Token Storage & Lifecycle Management
**Decision:** Riverpod `StateNotifier<AuthState>` synced to Hive

**Rationale:**
- Keeps auth state as a single source of truth (AuthState object: token, expiresAt, isAuthenticated, isGuest, userId)
- Testable: No hidden state in Hive; state object is immutable during tests
- Extensible: Easy to add refresh_token, device_id, expiry tracking, retry count without changing storage API
- Initialization: App loads token from Hive on startup, StateNotifier wraps it in structured object
- Async-safe: Riverpod handles async initialization of Hive before providers run

**Storage Layer (Hive):**
- Encrypted with AES (platform-provided, available on all API levels)
- Box name: `auth_state`
- Key: Single entry `current` → JSON serialized `AuthState`
- No manual encryption plumbing (Hive handles it)

**Token Refresh Strategy (Lazy, NOT Time-based):**
- Check expiry before each API call (in FutureProvider)
- Only refresh if `expiresAt < now() + 5 min` buffer
- DO NOT use Timer/periodic refresh (wasteful, runs even if app backgrounded)
- Refresh endpoint: Assume token endpoint if/when API provides one (currently not documented)

**AuthState Structure:**
```dart
class AuthState {
  final String? token;
  final DateTime? expiresAt;
  final bool isAuthenticated;
  final bool isGuest;
  final String? userId;
  final String? deviceId;
}
```

---

### 3. Device Hardware ID (HWID) Generation & Persistence
**Decision:** Android `Build.ID` + iOS UUID fallback, persisted to Hive

**Rationale:**
- **Android ID (preferred):** Device-specific, survives app reinstalls (persists in OS-level partition), minimal privacy impact
- **iOS:** Hardware identification is restricted; use UUIDv4 generated once and stored
- Persistent across app updates (same device = same ID)
- API expects device_id in auth request, so it must survive app lifecycle

**Factory Reset Behavior (KNOWN LIMITATION):**
- If user factory resets device, HWID changes → API treats as new device
- This is acceptable for v1.2 (user re-authenticates, gets new keys)
- Future: If API supports device linking, could bind multiple IDs to same user account (Phase 10+)

**Implementation Approach:**
- On first app launch: Read platform HWID, save to Hive
- Subsequent launches: Load from Hive (no platform calls needed)
- `device_info_plus` package: Planned for Phase 08 (add to pubspec.yaml)

---

### 4. Error Handling & Retry Strategy
**Decision:** Hybrid auto-retry + manual fallback with structured error feedback

**Retry Logic:**
1. **Auto-retry (silent):** 1 automatic retry on transient errors (timeout, connection refused, 5xx) with exponential backoff
   - First attempt: immediate
   - Second attempt: 1-second delay (backoff exponent = 1)
   - Do NOT retry on 401 (invalid token) or 400 (client error)

2. **Manual retry (if still failing):** Show error snackbar/dialog with "Retry" button
   - User controls recovery
   - Error message distinguishes transient (network) vs auth (401) vs server (500) errors
   - "Retry" button retriggers the FutureProvider (via ref.refresh())

**Timeout Values (from research):**
- Connection timeout: 5 seconds
- Read timeout: 10 seconds
- Total request timeout: 10 seconds

**401 Handler (Token Expired):**
- Catch in FutureProvider, attempt token refresh
- If refresh succeeds: retry request
- If refresh fails (401 on refresh endpoint): Route user to login screen

**Error States in UI:**
- AsyncValue.loading → Loading indicator
- AsyncValue.error → Error message + "Retry" button (if retryable)
- AsyncValue.data → Display servers

**Why NOT full automatic exponential backoff:**
- Could mask authentication issues (user thinks it's working, token is silently invalid)
- UX benefit of showing error after 1 attempt outweighs false transparency

---

### 5. Token Request/Response Format
**Decision:** Opaque token string (as provided by API), no JWT parsing required

**Context from API spec:**
- Device auth endpoint (POST /auth/device/) returns: `token`, `is_guest`, `user_id`, `app_trial_enabled`, `announcement`
- No refresh token mentioned in spec (assumption: single long-lived token or 24h TTL)
- Response structure: Store in AuthState, validate on next API call

**Assumption (needs validation):**
- Token TTL: ~24 hours (not documented; inform backend team to clarify)
- If shorter TTL needed: Will require refresh endpoint (not yet in API spec)

---

### 6. API Credentials & Security
**Decision:** X-API-Key header (placeholder value), moved to native code in Phase 09

**Context:**
- Currently hardcoded: `X-API-Key: secret_app_key_123` (placeholder)
- Phase 08: Accept hardcoded value in Dart (allows testing integration)
- Phase 09: Move to native Kotlin constant in `android/app/src/main/java/com/arma/vpn/Config.kt`
- Phase 10: Add Keystore encryption for Phase 09 migration

**Base URL:**
- Placeholder: `https://your-domain.com/api/v1`
- Must be replaced with actual domain before production build
- Stored in: `lib/config/app_config.dart` (allow env override for testing)

---

### 7. Package Dependencies
**Additions for Phase 08:**
- `device_info_plus: ^10.0.0` — Reliable HWID on Android/iOS (already tested in Phase 08 research)
- `http: ^1.1.0` — Already in pubspec (REST-only, lighter than dio)
- `riverpod: ^2.5.1` — Already in pubspec (for @riverpod decorator)
- `uuid: ^4.0.0` — For iOS fallback device ID

**Build step (CRITICAL):**
- After adding `@riverpod` providers: Run `dart run build_runner build`
- Commit generated `.g.dart` files to version control
- This must run before Phase 08 execution can begin

---

### 8. Testing Strategy (Phase 08 scope)
**Unit Tests:**
- Token StateNotifier: Test expiry logic, serialization/deserialization
- AuthProvider: Test lazy refresh, 401 handling
- DeviceIdProvider: Test Hive persistence, platform fallback

**Integration Tests:**
- Mock API client using Riverpod overrides
- Test happy path: auth → fetch keys → cache hit
- Test error path: auth → timeout → retry → success
- Test 401 path: expired token → refresh → retry

**NO E2E tests in Phase 08:** Requires Phase 09 (home screen display) to be meaningful

---

## Deferred Decisions (Phase 09+)

1. **Multi-device linking** — API may support binding multiple device IDs to same user (needs confirmation)
2. **Announcement display** — `announcement` field returned by device auth; display location TBD in Phase 09
3. **Guest mode flow** — `is_guest` flag returned; needs UX design (guest servers vs full access)
4. **App version validation** — API may require minimum app version; implement in Phase 09 when Phase 08 endpoints are validated
5. **Native security hardening** — X-API-Key Keystore encryption deferred to Phase 09+ (Kotlin integration)

---

## Implementation Checklist (for planner)

- [ ] Create `lib/features/api/` directory structure (datasource → repository → provider layers)
- [ ] Generate HWID on first launch, persist to Hive
- [ ] Implement `ApiClient` class with http.Client, auto-retry logic, timeout handling
- [ ] Implement `AuthStateNotifier` with token management and lazy refresh
- [ ] Implement `authTokenProvider` (FutureProvider) with 401/refresh handling
- [ ] Implement `fetchServerKeysProvider` (FutureProvider) that calls API
- [ ] Add unit tests for token lifecycle, retry logic, HWID persistence
- [ ] Verify build_runner generates .g.dart files correctly
- [ ] Test happy path: auth → fetch → cache
- [ ] Commit all code with atomic commits per logical component
- [ ] Document API response structures in inline comments (spec is in Russian)

---

## Risk Mitigations

**Risk:** Hardcoded API key leaked in source code  
**Mitigation:** Phase 09 moves to native code; document placeholder in code comments

**Risk:** Device factory reset causes API authentication failure  
**Mitigation:** Documented limitation; user re-authenticates (acceptable for v1.2)

**Risk:** Token refresh endpoint doesn't exist in API  
**Mitigation:** Lazy refresh catches 401 and routes to login; escalate to backend team

**Risk:** Hive box not initialized before providers run  
**Mitigation:** Use Riverpod's `@riverpod` decorator with `keepAlive: true`; Hive initialization happens in main() before runApp()

---

## Canonical References

- **Phase 08 Research:** `.planning/phases/08-api-client-device-auth/08-RESEARCH.md`
  - HTTP patterns, token management, common pitfalls, validation architecture
  
- **v1.2 Requirements:** `.planning/REQUIREMENTS.md` (section: v1.2 Requirements)
  - API-01 through API-03, SEC-01, data management, integration requirements
  
- **API Specification:** `docs/api_documentation.md`
  - Device auth endpoint, keys endpoint, response structures
  - Note: Document in Russian; translations embedded in comments during implementation
  
- **Existing Patterns:** `lib/features/server/` (subscription_provider.dart, server_repository.dart)
  - Study existing Riverpod provider patterns, Hive integration, error handling
  
- **v1.2 Roadmap:** `.planning/ROADMAP-v1.2.md`
  - Phase 08-10 interdependencies, success criteria, timeline

---

## Questions for Stakeholders (Before Phase 08 Execution)

1. **X-API-Key actual value:** What is the real API key for backend authentication?
2. **API base URL:** What is the actual domain? (needs to replace `https://your-domain.com`)
3. **Token TTL:** Is token valid for 24 hours, or different duration?
4. **Refresh token support:** Does API provide a refresh endpoint, or single long-lived token?
5. **Multi-device linking:** Can a user link multiple devices to same account?
6. **App version validation:** Should API reject requests from old app versions? (min version enforcement)

---

**Phase 08 is ready for planning. Next step: `/gsd-plan-phase 08`**
