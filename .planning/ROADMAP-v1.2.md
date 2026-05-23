# Roadmap: v1.2 Default VPN Servers Integration

**Milestone:** v1.2  
**Status:** Planning  
**Created:** 2026-05-24  

---

## Overview

Integrate your VPN server API to display default servers in the app's home screen, enabling users to connect to pre-configured servers with one tap, without manual setup.

**Key Features:**
- Device authentication with your VPN API
- Fetch and display user's VPN keys in home screen bottom half
- Manual refresh button + automatic periodic updates
- Graceful error handling and offline support
- User-configurable auto-update intervals

**Dependencies:**
- Requires v1.1 (sing-box engine) to be completed and functional
- Depends on your VPN server API (docs/api_documentation.md)

---

## Phase Breakdown

### Phase 08: API Client & Device Authentication

**Goal:** Build the API client library and implement device authentication flow.

**Scope:**
- Create HTTP client wrapper for your VPN API
- Implement device auth endpoint (`POST /auth/device/`)
- Generate and persist device HWID (UUID)
- Store and refresh API tokens securely
- Handle auth errors and token expiry

**Requirements Mapped:**
- API-01: Device authentication
- SEC-01: Credentials storage (partial)
- REL-01: Token management

**Deliverables:**
- APIClient class with device auth method
- HWID generation and storage in Hive
- Token refresh logic
- Auth error handling

**Depends on:** v1.1 completed

---

### Phase 09: Default Servers Home Screen Display

**Goal:** Display default servers in home screen bottom half with UI controls.

**Scope:**
- Fetch VPN keys endpoint (`GET /keys/`)
- Parse server data (name, status, traffic info)
- Build default servers widget for home screen
- Add manual refresh button
- Loading/error states
- Display cached servers when offline

**Requirements Mapped:**
- API-02: Fetch user's VPN keys
- API-03: Error handling
- UI-01: Default servers display
- UI-02: Manual refresh button
- REL-01: Offline support

**Deliverables:**
- ServerRepository class to fetch and cache servers
- DefaultServersWidget component
- Loading and error UI states
- Cached server display logic

**Depends on:** Phase 08 completed

---

### Phase 10: Settings & Auto-Update Configuration

**Goal:** Add user settings for auto-update and implement periodic refresh background task.

**Scope:**
- Add "Default Servers Auto-Update" setting to settings screen
- Options: Disabled, Every 12 Hours, Every 24 Hours, Every 7 Days
- Implement background task to refresh servers periodically
- Auto-retry failed fetches with exponential backoff
- Verify servers work with existing connection logic

**Requirements Mapped:**
- DATA-01: Fetch on first launch
- DATA-02: Auto-update functionality
- DATA-03: Server storage
- COMPAT-01: Connection compatibility
- COMPAT-02: Settings integration

**Deliverables:**
- Settings UI for auto-update configuration
- BackgroundTask or scheduled refresh logic
- Hive storage schema for default servers
- Integration with existing VPN connection flow

**Depends on:** Phase 09 completed

---

## Success Criteria

- [ ] Users can authenticate with VPN API on first app open
- [ ] Default servers from API appear in home screen bottom half
- [ ] Users can tap a default server and connect via existing VPN service
- [ ] Manual refresh button fetches latest servers
- [ ] Auto-update setting is configurable with multiple intervals
- [ ] App gracefully handles API errors (offline, timeout, auth failures)
- [ ] Cached servers display when offline
- [ ] All v1.0 and v1.1 features continue to work
- [ ] Default servers display in < 2 seconds

---

## Phase Distribution

| Phase | Focus | Requirements | Complexity |
|-------|-------|--------------|-----------|
| 08 | API Client & Auth | API-01, SEC-01 | Medium |
| 09 | Home Screen Display | API-02, API-03, UI-01, UI-02, REL-01 | Medium |
| 10 | Settings & Auto-Update | DATA-01, DATA-02, DATA-03, COMPAT-01, COMPAT-02 | Medium |

**Total Phases:** 3  
**Total Requirements:** 14  
**Estimated Complexity:** Low-Medium (no architectural changes, mostly new feature)

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| API server downtime | Users can't fetch new servers | Show cached servers, graceful error messages |
| Network timeouts | App hangs on slow connections | 5-second timeout, async fetch, loading UI |
| Token expiry | Auth failures mid-session | Auto-refresh tokens, retry failed requests |
| Large server lists | Performance degradation | Pagination or virtualized list widget |
| Storage quota exceeded | Can't cache servers | Implement cache eviction (oldest first) |

---

## Notes

- This is a feature addition, not a major architectural change
- Builds entirely on top of v1.1 foundation
- No impact on existing VPN connection logic
- Can be developed in parallel with v1.1 work if desired

---

*Roadmap created: 2026-05-24*  
*Next step: Proceed to Phase 08 planning with `/gsd-plan-phase 08`*
