# Roadmap: Arma Proxy & VPN Client

## Milestones

- ✅ **v1.3 Telegram Account Linking** — archived in `.planning/milestones/` (shipped 2026-05-24)
- ✅ **v1.4 Telegram Link Status & Dashboard Announcements** — archived (`.planning/milestones/v1.4-ROADMAP.md`, shipped 2026-05-24, audit debt accepted)
- 🚧 **v1.5 Dashboard Layout Refresh + Servers Screen Defaults** — active milestone

## v1.5 Phases

### Scope

Milestone v1.5 is a visual/layout milestone: keep existing behavior while redesigning dashboard composition and exposing default servers in Servers screen.

## Phases

- [x] **Phase 16: Servers Screen Defaults Integration** - Show default servers as a dedicated collapsible section with existing server interaction behavior. (gap closure in progress) (completed 2026-05-24)
- [x] **Phase 17: Dashboard 35/65 Layout Refresh** - Apply 35/65 dashboard composition and selected-server parked visual state while preserving logic. (gap closure in progress) (completed 2026-05-24)

## Phase Details

### Phase 16: Servers Screen Defaults Integration
**Goal**: Users can discover and use default servers directly from the Servers screen without breaking imported-server flows.
**Depends on**: None (first phase in milestone)
**Requirements**: SRVD-01, SRVD-02, SRVD-03, SRVD-04
**Success Criteria** (what must be TRUE):
  1. Default servers appear in a dedicated section above imported/custom servers.
  2. Default-servers section supports collapse/expand.
  3. Tapping a default-server card follows existing server select/connect behavior.
  4. Existing imported-server collapsible group behavior remains unchanged.
**Plans**: 3 plans
Plans:
- [x] 16-01-PLAN.md — Implement default-servers section in Servers screen with collapsible behavior parity
- [x] 16-02-PLAN.md — Close UAT Test 1 gaps for defaults visibility and sub-link expansion
- [x] 16-03-PLAN.md — Close UAT subscription_url grouped defaults gap
**UI hint**: yes

### Phase 17: Dashboard 35/65 Layout Refresh
**Goal**: Dashboard presents the requested 35/65 visual structure with explicit selected-server visibility while keeping current behavior.
**Depends on**: Phase 16
**Requirements**: DLAY-01, DLAY-02, DLAY-03, DLAY-04
**Success Criteria** (what must be TRUE):
  1. Dashboard renders fixed 35% top / 65% bottom composition.
  2. Top panel shows connect button, selected server, and statistics.
  3. Bottom panel shows announcements and default-server cards.
  4. Selected server is clearly parked/highlighted in UI.
**Plans**: 2 plans
Plans:
- [x] 17-01-PLAN.md — Implement dashboard layout split and selected-server parked visual state
- [x] 17-02-PLAN.md — Close UAT gap for selected highlight parity in default servers list
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 16. Servers Screen Defaults Integration | 3/3 | Complete   | 2026-05-24 |
| 17. Dashboard 35/65 Layout Refresh | 2/2 | Complete   | 2026-05-24 |
