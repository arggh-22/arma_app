# Arma Proxy & VPN Client

## Current State

- **Last shipped milestone:** v1.4 Telegram Link Status & Dashboard Announcements (archived 2026-05-24)
- **Archive files:** `.planning/milestones/v1.4-ROADMAP.md`, `.planning/milestones/v1.4-REQUIREMENTS.md`, `.planning/milestones/v1.4-MILESTONE-AUDIT.md`
- **Milestone note:** archived with accepted audit debt (missing per-phase `VERIFICATION.md` artifacts in v1.4 audit gate)

## Next Milestone Goals

- Re-establish full verification chain for new milestone phases (`VERIFICATION.md`, UAT, security, Nyquist).
- Address carried quality debt where prioritized (Phase 2 Nyquist backfill, Telegram Step 3 localization cleanup).
- Define next user-visible milestone scope via `/gsd-new-milestone`.

## Previous Snapshot

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
