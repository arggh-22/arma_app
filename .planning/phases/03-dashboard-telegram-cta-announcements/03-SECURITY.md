---
phase: 03
slug: dashboard-telegram-cta-announcements
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
---

# Phase 03 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| `/auth/device/` API -> DTO/domain auth state | Remote payload drives guest/announcement UI behavior and startup freshness path | Auth token, guest/user identity, announcement title/text |
| Dashboard UI -> external Telegram app | User tap triggers external URI launch | Fixed public bot URI |
| Widget tree -> conditional announcement rendering | Content gating determines visibility and read-more behavior | User-facing announcement text |
| App startup bootstrap -> auth refresh | App-open bootstrap forces fresh device-auth before dashboard consumption | Refreshed auth state payload |
| Bootstrap provider -> default server key prewarm | Startup flow chains auth refresh to key prewarm | Server-key metadata |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-03-01 | S (Spoofing) | Linked CTA destination | mitigate | `dashboard_screen.dart` hardcodes `https://t.me/devarmabot`; no server-provided link accepted. | closed |
| T-03-02 | T (Tampering) | Announcement fields | mitigate | `device_auth_response.dart` validates announcement key types and `dashboard_screen.dart` trims/gates non-empty render path. | closed |
| T-03-03 | R (Repudiation) | CTA/Read-more interactions | accept | No audit-log requirement in this phase; interaction behavior enforced by widget/provider tests. | closed |
| T-03-04 | I (Information Disclosure) | Announcement bottom sheet | accept | Bottom sheet only renders announcement text already intended for user display. | closed |
| T-03-05 | D (Denial of Service) | FAB/announcement rendering | mitigate | Existing `_showLinkFab` scroll gating remains in place with lightweight conditional rendering. | closed |
| T-03-06 | E (Elevation of Privilege) | Guest/linked branch logic | mitigate | CTA branch derives from persisted `AuthState.isGuest` path. | closed |
| T-03-07 | T (Tampering) | Startup auth freshness path | mitigate | `auth_bootstrap_provider.dart` now invokes `authStatusRefreshProvider()` to force `/auth/device/` refresh on bootstrap. | closed |
| T-03-08 | D (Denial of Service) | Startup bootstrap sequencing | mitigate | `app.dart` keeps startup bootstrap single-trigger and non-blocking while preserving post-refresh key prewarm. | closed |
| T-03-09 | R (Repudiation) | Gap-regression detection | mitigate | `auth_bootstrap_provider_test.dart` asserts refresh/prewarm call counts across bootstrap and manual rerun. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-03-01 | T-03-03 | Phase scope has no interaction audit/log sink; user-facing correctness is validated by test coverage. | Product/Engineering | 2026-05-24 |
| AR-03-02 | T-03-04 | Announcement content is explicitly intended for on-screen user consumption; no extra sensitive channel introduced. | Product/Engineering | 2026-05-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 9 | 9 | 0 | Copilot (`/gsd-secure-phase 3`) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
