# Roadmap: Arma Proxy & VPN Client

## Milestones

- ✅ **v1.3 Telegram Account Linking** — archived: `.planning/milestones/v1.3-ROADMAP.md` (shipped 2026-05-24, known gap TGAPI-01)
- 📦 **Legacy milestones (v1.0–v1.2)** — archived snapshot: `.planning/ROADMAP-v1.2.md`
- 🚧 **v1.4 Telegram Reliability Hardening** — active milestone (phase numbering reset for this milestone)

## v1.4 Telegram Reliability Hardening

**Milestone Goal:** Restore Telegram link API contract reliability and close verification/audit debt from TGAPI-01.  
**Milestone Independence:** v1.4 phase numbering restarts at Phase 1 and does not depend on historical phase-number chains.

## Phases

- [ ] **Phase 1: Telegram API Contract Hardening** - Fix Telegram Bearer auth contract and preserve existing `/keys/` auth behavior.
- [ ] **Phase 2: Verification & Audit Closure** - Lock in regression coverage and regenerate milestone evidence proving TGAPI-01 closure.

## Phase Details

### Phase 1: Telegram API Contract Hardening
**Goal**: Telegram linking works with the correct auth-header contract while existing default-server auth flows remain stable
**Depends on**: Nothing (first phase)
**Requirements**: TGFIX-01, TGFIX-02
**Success Criteria** (what must be TRUE):
  1. User can submit Telegram link data and the app sends `Authorization: Bearer <token>` on `POST /auth/telegram/link/`.
  2. User can still use default-server flows backed by `/keys/` without new auth-header failures.
  3. Telegram linking no longer fails because of `Token` vs `Bearer` auth-header mismatch.
**Plans**: TBD

### Phase 2: Verification & Audit Closure
**Goal**: Telegram auth-contract reliability is provable through automated checks and refreshed milestone audit evidence
**Depends on**: Phase 1
**Requirements**: TGAUD-01, TGAUD-02
**Success Criteria** (what must be TRUE):
  1. Maintainer can run focused automated checks that fail if Telegram link auth-header format regresses.
  2. Maintainer can run focused automated checks that fail if `/keys/` auth-header behavior is unintentionally changed.
  3. Updated milestone audit evidence explicitly marks TGAPI-01 as resolved with current verification results.
**Plans**: TBD

## Progress

**Execution Order:** 1 → 2

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Telegram API Contract Hardening | 0/TBD | Not started | - |
| 2. Verification & Audit Closure | 0/TBD | Not started | - |
