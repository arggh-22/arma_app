# Arma Proxy & VPN Client

## Current State

- **Last shipped milestone:** v1.4 Telegram Link Status & Dashboard Announcements (archived 2026-05-24)
- **Archive files:** `.planning/milestones/v1.4-ROADMAP.md`, `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-MILESTONE-AUDIT.md`
- **Milestone note:** archived with accepted audit debt (missing per-phase `VERIFICATION.md` artifacts in v1.4 audit gate)

## Current Milestone: v1.5 Dashboard Layout Refresh + Servers Screen Defaults

**Goal:** Redesign dashboard UI layout while keeping existing behavior and add default servers into the Servers screen.

**Target features:**
- Dashboard uses a 35%/65% layout split.
- Top 35% shows connect button, selected server, and statistics.
- Bottom 65% shows announcements and default servers.
- Default servers render as cards.
- Selected server is visually parked/highlighted.
- Servers screen includes default servers.

## Previous Snapshot

<details>
<summary>Milestone planning focus before v1.5 kickoff</summary>

- Re-establish full verification chain for new milestone phases (`VERIFICATION.md`, UAT, security, Nyquist).
- Address carried quality debt where prioritized (Phase 2 Nyquist backfill, Telegram Step 3 localization cleanup).

</details>

<details>
<summary>v1.4 milestone narrative (now archived)</summary>

**Goal:** Extend Telegram linking feedback and dashboard API-driven UX by adding link-status checks, role-aware CTA behavior, correct app-version payloading, and conditional announcements.

**Delivered features:**
- Added Step 3 **Check Link Status** using `/auth/device/`.
- Added role-aware dashboard CTA swap (`is_guest` Link CTA vs Telegram bot CTA).
- Unified `/auth/device/` app version with shared Settings source.
- Added conditional announcement section and read-more bottom sheet.
- Added app-open announcement freshness bootstrap refresh path.

</details>

<details>
<summary>Pre-archive project narrative (v1.3 planning snapshot)</summary>

This project is an Android-first privacy VPN/proxy client focused on one-tap usability, clean UX, and resilience in hostile networks. Milestones are tracked in `.planning/milestones/` to keep active planning docs compact.

</details>

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state
