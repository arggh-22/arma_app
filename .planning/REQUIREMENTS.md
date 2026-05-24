# Requirements: Arma Proxy & VPN Client

**Defined:** 2026-05-24
**Core Value:** Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.

## v1.4 Requirements

Requirements for Telegram reliability hardening after v1.3 archival.

### Telegram API Contract

- [ ] **TGFIX-01**: Telegram link API call sends `Authorization: Bearer <token>` for `POST /auth/telegram/link/`.
- [ ] **TGFIX-02**: Existing `/keys/` API auth-header behavior remains unchanged to avoid regressions in default-server flows.

### Verification & Audit Closure

- [ ] **TGAUD-01**: Telegram API contract has focused automated coverage that fails on auth-header regressions.
- [ ] **TGAUD-02**: Milestone audit evidence is regenerated and marks TGAPI-01 regression as resolved.

## Future Requirements

Deferred to later milestones.

### Telegram Enhancements

- **TGFUT-01**: Improve Telegram link UX copy and contextual troubleshooting guidance.
- **TGFUT-02**: Add proactive diagnostics surface for Telegram linking errors.

## Out of Scope

Explicitly excluded for this milestone.

| Feature | Reason |
|---------|--------|
| New Telegram UI flows | Scope is reliability hardening and closure, not UX expansion |
| New backend endpoints | Milestone targets existing API contract compliance only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TGFIX-01 | Phase 1 | Pending |
| TGFIX-02 | Phase 1 | Pending |
| TGAUD-01 | Phase 2 | Pending |
| TGAUD-02 | Phase 2 | Pending |

**Coverage:**
- v1.4 requirements: 4 total
- Mapped to phases: 4
- Unmapped: 0 ✅

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after v1.4 roadmap mapping*
