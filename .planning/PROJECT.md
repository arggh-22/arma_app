# Arma Proxy & VPN Client

## Current State

- **Last shipped milestone:** v1.3 Telegram Account Linking (archived 2026-05-24)
- **Archive files:** `.planning/milestones/v1.3-ROADMAP.md`, `.planning/milestones/v1.3-REQUIREMENTS.md`, `.planning/milestones/v1.3-MILESTONE-AUDIT.md`
- **Milestone note:** archived with accepted known gap `TGAPI-01` (`Token` vs `Bearer` auth-header regression in Telegram link API call)

## Current Milestone: v1.4 Telegram Link Status & Dashboard Announcements

**Goal:** Extend Telegram linking feedback and dashboard API-driven UX by adding link-status checks, role-aware CTA behavior, correct app-version payloading, and conditional announcements.

**Target features:**
- Add Step 3 **Check Link Status** button in Telegram link screen using `/auth/device/`.
- Replace dashboard Link CTA with Telegram bot CTA when `is_guest=false`.
- Use the same app-version source shown in Settings for `/auth/device/` payloads (no hardcoded stale version in auth flow).
- Show announcement area between statistics and default servers with read-more bottom sheet, hidden when title/text is null or empty.

## Previous Snapshot

<details>
<summary>Pre-archive project narrative (v1.3 planning snapshot)</summary>

This project is an Android-first privacy VPN/proxy client focused on one-tap usability, clean UX, and resilience in hostile networks. v1.0 is shipped and validated, v1.1+ roadmap items remain in planning, and milestone details are now tracked in milestone archive files to keep active planning docs compact.

</details>
