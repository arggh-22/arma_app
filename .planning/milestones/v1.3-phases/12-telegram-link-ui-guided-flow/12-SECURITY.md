---
phase: 12
slug: telegram-link-ui-guided-flow
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
---

# Phase 12 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| dashboard scroll/tap input → navigation | Untrusted user gestures drive UI visibility and route transitions | UI events, route intents |
| app → external Telegram link | Opening Telegram bot URL leaves app boundary | External URL (`https://t.me/devarmabot`) |
| UI submit → API-backed provider | User-provided Telegram ID flows into provider/repository call | Telegram ID input (untrusted text) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-12-01 | DoS | `dashboard_screen.dart` scroll listener | mitigate | FAB visibility uses lightweight local state, updated only on direction transitions | closed |
| T-12-02 | Tampering | `app_router.dart` route mapping | mitigate | Explicit static `/telegram-link` route plus route-resolution widget test | closed |
| T-12-03 | Tampering | `telegram_link_guide_screen.dart` submit path | mitigate | Submit goes only through `telegramLinkProvider.notifier.submit(...)` validation path | closed |
| T-12-04 | DoS | guide screen submit actions | mitigate | Input/paste/submit controls are guarded/disabled while `isSubmitting` | closed |
| T-12-05 | Info disclosure | outcome feedback surface | mitigate | UI feedback is mapped from typed outcomes only; no raw backend/auth/token data surfaced | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 5 | 5 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
