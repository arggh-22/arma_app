# Arma Proxy & VPN Client

## Current State

- **Last shipped milestone:** v1.3 Telegram Account Linking (archived 2026-05-24)
- **Archive files:** `.planning/milestones/v1.3-ROADMAP.md`, `.planning/milestones/v1.3-REQUIREMENTS.md`, `.planning/milestones/v1.3-MILESTONE-AUDIT.md`
- **Milestone note:** archived with accepted known gap `TGAPI-01` (`Token` vs `Bearer` auth-header regression in Telegram link API call)

## Current Milestone: v1.4 Telegram Reliability Hardening

**Goal:** Stabilize Telegram linking by fixing the TGAPI-01 contract regression and closing remaining verification/audit debt.

**Target features:**
- Fix Telegram link authorization header contract to `Bearer`.
- Keep existing `/keys/` token contract behavior unchanged while preventing cross-endpoint regressions.
- Regenerate verification + milestone audit evidence for a clean closure path.

## Previous Snapshot

<details>
<summary>Pre-archive project narrative (v1.3 planning snapshot)</summary>

This project is an Android-first privacy VPN/proxy client focused on one-tap usability, clean UX, and resilience in hostile networks. v1.0 is shipped and validated, v1.1+ roadmap items remain in planning, and milestone details are now tracked in milestone archive files to keep active planning docs compact.

</details>

---
*Last updated: 2026-05-24 after v1.4 milestone initialization*
