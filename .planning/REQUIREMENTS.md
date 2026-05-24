# Requirements: Arma Proxy & VPN Client

**Defined:** 2026-05-25
**Core Value:** Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.

## v1.5 Requirements

Requirements for dashboard visual redesign and default-servers integration in Servers screen.

### Dashboard Layout

- [ ] **DLAY-01**: User sees dashboard split into fixed 35% top panel and 65% bottom panel.
- [ ] **DLAY-02**: User sees connect button, selected server, and statistics in the top panel.
- [ ] **DLAY-03**: User sees announcements and default server cards in the bottom panel.
- [ ] **DLAY-04**: User can clearly identify the selected server via parked/highlighted card UI.

### Servers Screen Defaults

- [x] **SRVD-01**: User sees a dedicated default-servers section above imported/custom servers.
- [x] **SRVD-02**: User can collapse/expand the default-servers section.
- [x] **SRVD-03**: User can tap a default-server card and get the same select/connect behavior as existing servers flow.
- [x] **SRVD-04**: Existing collapsible imported-server group behavior remains unchanged.

## Future Requirements

Deferred to future milestones.

### Visual + UX Enhancements

- **DLAY-05**: Adaptive ratio tuning per device class (small/large screen optimization).
- **SRVD-05**: User can pin favorite default servers and customize order.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Connection/auth business-logic rewrite | Milestone is visual/layout refresh with behavior parity |
| New default-server backend contracts | Existing API/provider contracts are sufficient |
| Servers data-model merge (default + imported) | Keep low-risk incremental integration and preserve current flows |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DLAY-01 | Phase 17 | Pending |
| DLAY-02 | Phase 17 | Pending |
| DLAY-03 | Phase 17 | Pending |
| DLAY-04 | Phase 17 | Pending |
| SRVD-01 | Phase 16 | Complete |
| SRVD-02 | Phase 16 | Complete |
| SRVD-03 | Phase 16 | Complete |
| SRVD-04 | Phase 16 | Complete |

**Coverage:**
- v1.5 requirements: 8 total
- Mapped to phases: 8 ✅
- Unmapped: 0

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 after roadmap mapping*
