# Requirements: Arma Proxy & VPN Client

**Defined:** 2026-05-24
**Core Value:** Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.

## v1.4 Requirements

Requirements for Telegram link-status visibility and dashboard announcement UX.

### Telegram Link Status

- [ ] **TGSTAT-01**: User can tap Step 3 **Check Link Status** in Telegram link screen and trigger `/auth/device/` refresh.
- [ ] **TGSTAT-02**: User sees clear status-check feedback states (loading/success/failure with retry).

### Dashboard CTA Behavior

- [ ] **TGCTA-01**: Dashboard shows Link CTA while `is_guest=true`.
- [ ] **TGCTA-02**: Dashboard replaces Link CTA with Telegram bot CTA when `is_guest=false`, and tap opens bot link.

### Device Auth Payload Version

- [ ] **TGVER-01**: `/auth/device/` sends app version from the shared Settings app-version source (no stale hardcoded auth-flow value).

### Announcements

- [ ] **TGANN-01**: Dashboard shows announcement block between statistics and default servers only when `announcement_title` and/or `announcement_text` contains non-empty content.
- [ ] **TGANN-02**: User can tap **Read more** and view full `announcement_text` in a bottom sheet.

## Future Requirements

Deferred to future milestones.

### Telegram UX Enhancements

- **TGFUT-01**: Advanced Telegram troubleshooting diagnostics.
- **TGFUT-02**: Rich notification/announcement targeting controls.

## Out of Scope

| Feature | Reason |
|---------|--------|
| New backend endpoints | Milestone uses existing `/auth/device/` and Telegram link endpoints |
| Full Telegram flow redesign | Scope is incremental status/CTA/announcement enhancement |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TGSTAT-01 | Phase TBD | Pending |
| TGSTAT-02 | Phase TBD | Pending |
| TGCTA-01 | Phase TBD | Pending |
| TGCTA-02 | Phase TBD | Pending |
| TGVER-01 | Phase TBD | Pending |
| TGANN-01 | Phase TBD | Pending |
| TGANN-02 | Phase TBD | Pending |

**Coverage:**
- v1.4 requirements: 7 total
- Mapped to phases: 0
- Unmapped: 7 ⚠️

---
*Requirements defined: 2026-05-24*
*Last updated: 2026-05-24 after v1.4 scope confirmation*
