# Project Research Summary

**Project:** Arma Proxy & VPN Client (v1.5 milestone)
**Domain:** Flutter mobile VPN dashboard + server selection UX
**Researched:** 2026-05-25
**Confidence:** HIGH

## Executive Summary

v1.5 should be delivered as a **presentation-layer refactor**, not a behavior rewrite: keep existing Flutter + Riverpod + go_router + Hive foundations, preserve connection/auth logic, and focus on the dashboard 35/65 layout + default servers surfaced on the Servers screen.

The safest path is to extract shared default-server card rendering and shared selection/reconnect action flow first, then apply it to Servers screen defaults, then recompose Dashboard layout. This sequence minimizes regression risk while shipping visible UX wins.

Primary risks are selected-server state drift, server-switch race conditions while connected, and accidental action leakage between default and imported servers. Mitigate via single-source state (`activeServerProvider`), one shared tap controller, clear section boundaries, and targeted widget/integration tests.

## Key Findings

### 1) Stack additions

- **No new dependencies for v1.5.**
- Keep: Flutter + Riverpod + go_router + Hive.
- Implement through existing screens/providers and shared widgets only.

### 2) Feature table stakes for milestone scope

- Dashboard top area must prioritize connect/disconnect state + primary CTA.
- Selected/current server must be visible without opening full server list.
- Servers browsing hierarchy/search remains intact (country → city → server).
- Defaults/recents must be surfaced at top (not hidden).
- Connected/disconnected state signaling must stay clear and high-contrast.
- Announcements remain contextual, inline, and non-blocking.

### 3) Watch out for (top pitfalls)

1. Selected-server identity drift between cards and persisted active server state.
2. Reconnect race conditions when selecting servers while already connected.
3. 35/65 dashboard relayout breaking CTA/announcement visibility behavior.
4. Default-server cards accidentally exposing imported-server destructive actions.
5. Repeating validation debt (missing verification artifacts at phase close).

### 4) Suggested implementation order

1. **Extract shared default-server card list + selection controller**
   - Delivers common renderer + single action path; no layout risk yet.
2. **Add default-servers section to Servers screen**
   - Delivers milestone feature in isolation while imported-server flow stays unchanged.
3. **Refactor Dashboard into 35/65 composition**
   - Reuses shared components and keeps existing business logic untouched.
4. **Apply selected “parked/highlighted” visuals**
   - UI-only state clarity driven by `activeServerProvider`.
5. **Regression/verification pass**
   - Widget tests for CTA branches, announcement behavior, defaults rendering/interactions.

### 5) Scope guardrails (what to avoid)

- No connection/auth/business-logic changes in this milestone.
- No `defaultServersProvider` contract/retry/cache behavior changes.
- No merging of defaults with imported-server data models.
- No auto-reordering defaults on refresh (keep deterministic ordering).
- No heavy animations/maps/new telemetry polling/personalization ranking.

## Implications for Roadmap

### Phase 1: Shared defaults foundation
**Rationale:** Removes duplication and state drift risk first.  
**Delivers:** Shared cards + shared selection controller.  
**Avoids:** Pitfalls #1, #2.

### Phase 2: Servers screen defaults integration
**Rationale:** Isolated feature addition with low coupling.  
**Delivers:** Defaults section above imported servers (normal mode only).  
**Avoids:** Pitfall #4.

### Phase 3: Dashboard 35/65 layout refresh
**Rationale:** Highest visible change after safer foundations are in place.  
**Delivers:** Top connect/status area, bottom announcements + default cards.  
**Avoids:** Pitfall #3.

### Phase 4: Validation + milestone closeout hardening
**Rationale:** Prevent repeat audit debt and regressions.  
**Delivers:** Test coverage + verification artifacts + UAT checks.  
**Avoids:** Pitfall #5.

### Research Flags

- **Likely needs deeper phase research:** Phase 3 (responsive layout edge cases across device sizes).
- **Can use standard patterns (skip extra research):** Phases 1, 2, and most of 4 (well-defined in current code + docs).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Clear “no new dependencies” guidance and direct integration points. |
| Features | HIGH | Table stakes are consistent with Proton/Mullvad/OpenVPN UX patterns. |
| Architecture | HIGH | Grounded in current codebase touchpoints and provider flows. |
| Pitfalls | HIGH | Specific, code-relevant failure modes with concrete prevention steps. |

**Overall confidence:** HIGH

### Gaps to Address

- Exact responsive breakpoints/min-max constraints for 35/65 split should be validated on small and large devices during implementation.
- Confirm interaction policy for defaults section in special server screen modes (e.g., multi-select/edit contexts) before phase finalization.

## Sources

- `.planning/research/STACK.md`
- `.planning/research/FEATURES.md`
- `.planning/research/ARCHITECTURE.md`
- `.planning/research/PITFALLS.md`
- Proton VPN support docs (server lists, connection profiles)
- Mullvad usage guides (connection state + location selection UX)
- OpenVPN Connect docs (profile-centric mobile behavior)

---
*Research completed: 2026-05-25*  
*Ready for roadmap: yes*
