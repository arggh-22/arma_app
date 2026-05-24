# Feature Landscape — v1.5 Dashboard Layout Refresh + Servers Screen Defaults

**Domain:** Mobile VPN dashboard + server selection UX  
**Researched:** 2026-05-24

## Table Stakes (must-have for this milestone)

| Feature | Why Expected (ecosystem signal) | Complexity | Notes for v1.5 |
|---|---|---|---|
| Primary connect/disconnect action dominates top area | Mullvad and Proton both center connection status/action on main connection screen, not buried in lists | Low | Keep CTA in top 35% block and preserve existing logic behavior |
| Current/selected server is always visible before opening full list | Mullvad: selected location shown on connection screen; Proton: profile/default connection surfacing and recents | Low | “Park” selected server card visually in dashboard and mirror this state on Servers screen |
| Server list supports hierarchy + drilldown (country → city → server) with search | Mullvad and Proton both expose country/city/server browsing and search/filtering | Medium | Don’t remove depth navigation when adding default servers section |
| Recency/defaults are surfaced (not hidden behind full list) | Proton explicitly promotes Recents/default profile; Mullvad remembers latest selected location | Medium | Servers screen should expose defaults at top, then full list below |
| Clear connected/disconnected visual state | Mullvad documents explicit connected/disconnected indicators and color/state cues | Low | Dashboard refresh must retain strong state contrast (not purely decorative) |
| Announcements/status info is contextual and non-blocking | VPN apps commonly place notices inside main screen flow; blocking flows are avoided | Low | Keep announcement block inline in bottom 65%, optional by content presence |

## Useful Differentiators (good for this milestone without logic rewrite)

| Feature | Value Proposition | Complexity | Notes |
|---|---|---|---|
| Stable 35/65 visual split with responsive bounds | Gives predictable scan pattern: action/status first, discovery/content second | Medium | Add min/max height clamps to avoid cramped top area on short screens |
| Selected-server “parked” card style (e.g., pinned first + highlight) | Reduces user confusion about active route when many defaults exist | Low | Must reflect actual selected state from existing logic, no client-side guesswork |
| Shared card component across Dashboard and Servers screen defaults | Improves UX consistency and reduces maintenance drift | Medium | One reusable server card variant with state tokens (selected/default/disabled) |
| Lightweight status chips on server cards (latency/load/availability if already available) | Helps faster server choice without opening details | Medium | Only use already-available data; do not add new polling/backend work in this milestone |
| Announcement card with progressive disclosure (Read more sheet) | Keeps dashboard compact while preserving full message accessibility | Low | Already proven in v1.4; keep as visual refinement not behavior change |

## Anti-Features (explicitly avoid in v1.5)

| Anti-Feature | Why Avoid | What to Do Instead |
|---|---|---|
| Changing connection/business logic during layout refresh | Scope creep + regression risk for role-aware CTA and auth-derived states | Freeze behavior; change presentation only |
| Auto-reordering default servers on each refresh | Breaks user muscle memory and makes “parked selected” state feel unstable | Keep deterministic ordering; selected item highlighted/pinned predictably |
| Adding heavy map/animation-first dashboard interactions | Competes with primary connect action and hurts low-end device responsiveness | Prefer static hierarchy + subtle transitions only |
| Blocking modal announcements/popups on entry | Interrupts one-tap connect flow and increases dismissal friction | Keep announcements inline with optional “Read more” |
| Duplicating default server logic separately on Dashboard vs Servers screen | Causes drift and inconsistent state bugs | Single source of truth for default server dataset + shared renderer |
| Overloading server cards with advanced controls in MVP | Increases cognitive load and tap errors | Keep cards focused: name, location, selected/default badge, optional simple metrics |

## Complexity Notes (implementation planning lens)

- **Low:** visual hierarchy, spacing split, card highlight states, inline announcement styling.
- **Medium:** shared card component adoption across two screens; default/selected ordering rules; responsive constraints for 35/65 split.
- **High (defer):** new backend fields, live health polling, personalized recommendation ranking, major IA changes to server taxonomy.

## MVP Recommendation for this milestone

Prioritize:
1. Top 35% dashboard block: connect CTA + selected server + existing stats (no behavior changes).
2. Bottom 65% block: announcement card + default server cards with selected highlight.
3. Servers screen: expose default servers section first, then existing full server navigation.

Defer:
- Smart recommendations, dynamic ranking, new server telemetry, richer personalization logic.

## Sources

- Proton VPN support sitemap + app UX docs (lastmod 2026-05-20): https://protonvpn.com/support/sitemap-articles.xml  
- Proton: Streamlined server lists (recents/pinning/list performance): https://protonvpn.com/support/streamlined-server-lists  
- Proton: Connection profiles and default connection behavior: https://protonvpn.com/support/connection-profiles  
- Mullvad Android usage guide (connection screen, remembered location, server drilldown/search): https://mullvad.net/en/help/using-mullvad-vpn-on-android  
- Mullvad app usage guide (connected/disconnected state signaling, location/server list behavior): https://mullvad.net/en/help/using-mullvad-vpn-app  
- OpenVPN Connect docs sitemap + connection profiles (profile-centric mobile connection model): https://openvpn.net/connect-docs/sitemap.xml, https://openvpn.net/connect-docs/connection-profiles.html
