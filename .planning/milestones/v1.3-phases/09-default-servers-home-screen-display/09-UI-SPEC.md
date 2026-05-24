---
phase: 09
slug: default-servers-home-screen-display
status: approved
shadcn_initialized: false
preset: none
created: 2026-05-24
reviewed_at: 2026-05-24T00:00:00Z
---

# Phase 09 — UI Design Contract

> Visual and interaction contract for frontend phases.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (Flutter Material 3) |
| Preset | not applicable |
| Component library | Flutter Material widgets |
| Icon library | Material Icons |
| Font | Platform default sans-serif (Roboto on Android) |

Primary visual anchor: the **Default Servers section header + first active server card** should be the first scan target after connection/traffic block.

---

## Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Inline micro gaps, badge padding |
| sm | 8px | Row gaps, compact spacing |
| md | 16px | Standard card/content padding |
| lg | 24px | Section spacing on dashboard |
| xl | 32px | Larger section separation |
| 2xl | 48px | Major break between dashboard groups |
| 3xl | 64px | Page-level breathing room |

Exceptions: Header refresh action keeps Material minimum 48x48dp tap target.

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | 14px | 400 | 1.5 |
| Label | 16px | 600 | 1.3 |
| Heading | 20px | 600 | 1.2 |
| Display | 28px | 600 | 1.2 |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | `colorScheme.surface` | Dashboard background and main surface |
| Secondary (30%) | `colorScheme.surfaceContainerLow` | Cards/section containers |
| Accent (10%) | `#00897B` (`colorScheme.primary`) | Refresh spinner, active status emphasis, selected/active server highlight |
| Destructive | `colorScheme.error` | Error/destructive semantics only |

Accent is reserved for refresh-in-progress state and active/default-server emphasis, not all interactive elements.

---

## Copywriting Contract

| Element | Copy |
|---------|------|
| Primary CTA | **Show all servers** |
| Empty state heading | **No default servers available** |
| Empty state body | **Pull latest servers with Refresh.** |
| Error state | Timeout: **Request timed out. Tap Refresh to try again.** / Offline+cache: **You’re offline. Showing offline data.** / Offline no cache: **No connection and no cached servers yet. Tap Refresh when online.** / Unauthorized after silent retry: **Session expired. Please retry authentication.** / Server error: **Server error. Please try again shortly.** |
| Destructive confirmation | none in this phase |

Accessibility requirement for icon-only controls: refresh icon must include semantic label **"Refresh default servers"**.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none | not applicable |
| third-party | none | not applicable |

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
