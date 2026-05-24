# Roadmap: Arma Proxy & VPN Client

## Milestones

- ✅ **v1.3 Telegram Account Linking** — archived in `.planning/milestones/` (shipped 2026-05-24)
- 🚧 **v1.4 Telegram Link Status & Dashboard Announcements** — active milestone (clean phase restart)

## v1.4 Phases

### Scope

Milestone v1.4 uses fresh numbering and does not depend on legacy phase chains.

## Phases

- [x] **Phase 1: Telegram Link Status Refresh** - Users can run Step 3 status checks using the correct app-version payload source.
- [ ] **Phase 2: Link Status Feedback & Retry UX** - Users get clear loading/success/failure outcomes with in-flow retry.
- [ ] **Phase 3: Dashboard Telegram CTA & Announcements** - Dashboard adapts CTA by guest status and shows conditional announcements with read-more.

## Phase Details

### Phase 1: Telegram Link Status Refresh
**Goal**: Users can trigger Telegram link-status refresh from Step 3 with a valid, up-to-date device auth payload.
**Depends on**: Nothing (first phase)
**Requirements**: TGSTAT-01, TGVER-01
**Success Criteria** (what must be TRUE):
  1. User can tap **Check Link Status** in Telegram Link Step 3 and trigger a device refresh request.
  2. Status refresh requests use the same app-version source displayed in Settings, avoiding stale auth-flow version mismatches.
  3. After triggering the check, user sees refreshed link-status result data in the Telegram link flow.
**Plans**: 1 plan
Plans:
- [x] 01-01-PLAN.md — Add Step 3 status refresh via auth provider flow and unify `/auth/device/` app version source with Settings
**UI hint**: yes

### Phase 2: Link Status Feedback & Retry UX
**Goal**: Users can understand status-check progress and recover from transient failures without leaving the flow.
**Depends on**: Phase 1
**Requirements**: TGSTAT-02
**Success Criteria** (what must be TRUE):
  1. User sees a loading state while link-status check is in progress.
  2. User sees a clear success state when status check completes successfully.
  3. User sees a clear failure state when status check fails and can retry directly from the same screen.
**Plans**: 1 plan
Plans:
- [ ] 02-01-PLAN.md — Harden and verify Step 3 loading/success/failure + immediate retry UX against locked Phase 1 defaults
**UI hint**: yes

### Phase 3: Dashboard Telegram CTA & Announcements
**Goal**: Dashboard presents role-aware Telegram actions and conditionally displays announcements with full-text access.
**Depends on**: Phase 1
**Requirements**: TGCTA-01, TGCTA-02, TGANN-01, TGANN-02
**Success Criteria** (what must be TRUE):
  1. When `is_guest=true`, user sees the dashboard Link CTA.
  2. When `is_guest=false`, user sees a Telegram bot CTA instead of Link CTA, and tapping it opens the bot link.
  3. Dashboard announcement block appears between statistics and default servers only when announcement title/text has non-empty content.
  4. User can tap **Read more** and view full announcement text in a bottom sheet.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Telegram Link Status Refresh | 1/1 | Complete | 2026-05-24 |
| 2. Link Status Feedback & Retry UX | 0/1 | Planned | - |
| 3. Dashboard Telegram CTA & Announcements | 0/0 | Not started | - |
