# Milestones

## v1.5 Dashboard Layout Refresh + Servers Screen Defaults (Shipped: 2026-05-24)

**Phases completed:** 2 phases, 5 plans, 15 tasks
**Archive:** `.planning/milestones/v1.5-ROADMAP.md`, `.planning/milestones/v1.5-REQUIREMENTS.md`
**Phase artifacts:** `.planning/milestones/v1.5-phases/`

**Key accomplishments:**

- Servers screen now ships a collapsible default-servers section with compact rows, parity-safe tap switching, and regression coverage that preserves imported-group UX.
- Closed UAT Test 1 by expanding default sub-link payloads into per-server rows and keeping defaults reachable when imported servers are absent.
- Default keys now resolve through each `subscription_url` and render as collapsible grouped default server lists while preserving imported-group and tap-parity behavior.
- Dashboard now reads as grouped 35/65 visual composition in a single scroll while preserving announcement/FAB/default-server parity and adding selected-server parked emphasis.
- Default server list now highlights the active server tile with the same parked border+tint semantics as ActiveServerCard while preserving tap/connect behavior.

### Known Gaps Accepted at Archive Time

- No `v1.5-MILESTONE-AUDIT.md` was present at archive time; milestone was completed with accepted audit debt.

---

## v1.4 Telegram Link Status & Dashboard Announcements (Shipped: 2026-05-24)

**Phases completed:** 3 phases, 4 plans, 9 tasks
**Archive:** `.planning/milestones/v1.4-ROADMAP.md`, `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-MILESTONE-AUDIT.md`
**Phase artifacts:** `.planning/milestones/v1.4-phases/`

**Key accomplishments:**

- Added Telegram Link Step 3 status refresh using `/auth/device/` with shared Settings app-version source.
- Hardened Step 3 feedback UX with loading/success/failure states and immediate retry behavior.
- Implemented role-aware dashboard CTA: guest Link CTA vs linked-user Telegram bot CTA.
- Added conditional dashboard announcement section with read-more bottom sheet behavior.
- Closed announcement freshness gap by forcing app-open bootstrap refresh via `authStatusRefreshProvider`.
- Completed UAT/security/validation artifacts for Phase 03 and locked bootstrap regression tests.

### Known Gaps Accepted at Archive Time

- Milestone audit status `gaps_found` due to missing per-phase `VERIFICATION.md` artifacts (requirements marked orphaned by audit gate).
- Nyquist backfill still pending for Phase 2 (`03` compliant, `01` partial, `02` missing in audit discovery).

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
