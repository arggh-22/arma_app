# Milestones

## v1.4 Telegram Link Status & Dashboard Announcements (Active)

**Phase numbering:** reset for clean milestone restart (Phase 1+).
**Roadmap:** `.planning/ROADMAP.md` (v1.4 section)

**Scope requirements:**
- TGSTAT-01, TGSTAT-02
- TGCTA-01, TGCTA-02
- TGVER-01
- TGANN-01, TGANN-02

---

## v1.3 Telegram Account Linking (Shipped: 2026-05-24)

**Phases completed:** 11, 12, 13, 14, 15  
**Plans completed:** 10  
**Archive:** `.planning/milestones/v1.3-ROADMAP.md`, `.planning/milestones/v1.3-REQUIREMENTS.md`, `.planning/milestones/v1.3-MILESTONE-AUDIT.md`

**Key accomplishments:**

- Added Telegram link endpoint integration and auth-retry-backed typed outcome mapping.
- Wired Riverpod Telegram submit flow with strict ID validation and duplicate submit suppression.
- Added dashboard Link entrypoint and full guided Telegram linking UI flow.
- Hardened Telegram UX with loading/success/error/retry behavior and expanded widget/provider/repository reliability coverage.
- Backfilled missing phase verification artifacts (`12-VERIFICATION.md`, `13-VERIFICATION.md`) and reconciled v1.3 audit blockers.
- Archived v1.3 with one accepted known gap: TGAPI-01 `Bearer` header regression tracked in milestone audit.

---
