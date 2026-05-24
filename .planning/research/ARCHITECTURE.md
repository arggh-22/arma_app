# Architecture Patterns — v1.5 Dashboard Layout Refresh + Servers Screen Defaults

**Domain:** Flutter + Riverpod UI integration (no backend contract changes)  
**Researched:** 2026-05-25  
**Confidence:** HIGH (grounded in current codebase state)

## Recommended Architecture

Keep all existing provider/repository behavior intact and do this as a **presentation-layer refactor**:

- Recompose `DashboardScreen` into top/bottom layout containers (35/65 split) using existing widgets/providers.
- Reuse the existing default-servers state (`defaultServersProvider`) in Servers screen via a dedicated defaults subsection.
- Centralize default-server tap/select/reconnect behavior so dashboard and servers use identical logic.

This minimizes risk because data sources, auth bootstrap, cache fallback, and connection flows remain unchanged.

## New vs Modified Components

### New Components (add)

| Component | Responsibility | Communicates With |
|---|---|---|
| `DashboardTopPanel` (widget) | Connect button + status/timer + active server + stats region (35%) | `connectionProvider`, `uiPreferencesProvider` |
| `DashboardBottomPanel` (widget) | Announcements + default server cards region (65%) | `authStateProvider`, `defaultServersProvider` |
| `DefaultServersCardsList` (shared widget) | Reusable card list renderer for default servers in dashboard + servers screen | `DefaultServerItem`, active-server id, callbacks |
| `DefaultServerSelectionController` (provider/controller) | Single source for “tap default server” behavior (select + conditional reconnect) | `activeServerProvider`, `connectionProvider` |
| `ServersDefaultSection` (widget) | Default servers block shown in `/servers` screen | `defaultServersProvider`, shared card list/controller |

### Modified Components (change)

| Component | Change |
|---|---|
| `dashboard_screen.dart` | Replace single-column flow with 35/65 split composition; keep FAB + announcement behavior unchanged |
| `default_servers_section.dart` | Extract private tile/list behavior into reusable shared widget; keep refresh/offline/error semantics |
| `server_list_screen.dart` | Insert defaults section above imported servers list (normal mode only; hidden in multi-select) |
| `default_servers_section_test.dart` + new server-screen tests | Add coverage for shared cards/selection + servers-screen rendering |

## Data-Flow Touchpoints (must remain stable)

1. **Announcement flow (unchanged):**  
   `auth_bootstrap_provider` → `authStateProvider` → dashboard announcement UI.
2. **Default server data flow (shared across two screens):**  
   `defaultServersProvider` (refresh/cache/retry) → dashboard default cards + servers defaults section.
3. **Selection + connection flow (shared action path):**  
   default card tap → `activeServerProvider.selectServer()` → if connected and changed: `connectionProvider.disconnect()` + `connect()`.
4. **Imported servers flow (unchanged):**  
   `serverListProvider` continues to power only user-imported servers list/groups.

## Build Order (minimal-risk sequence)

1. **Extract shared default-server card + tap controller first**  
   - No layout changes yet.  
   - Validate current dashboard behavior unchanged.
2. **Add defaults section to Servers screen (feature add, isolated)**  
   - Render from `defaultServersProvider`; do not touch imported-server pipeline.
3. **Refactor Dashboard to 35/65 container composition**  
   - Reuse extracted shared components.  
   - Keep existing FAB logic and announcement sheet logic.
4. **Apply selected-server “parked/highlighted” visuals in shared card renderer**  
   - Driven by `activeServerProvider` id; no new state.
5. **Regression pass + tests**  
   - Dashboard announcement/CTA tests  
   - Default servers section tests  
   - New servers-screen defaults rendering/interaction tests.

## Integration Guardrails

- **Do not modify** `defaultServersProvider` retry/cache/auth behavior for this milestone.
- Keep defaults and imported servers as **separate UI sections** (avoid merging data models).
- Avoid duplicate `ref.listen` snackbars across dashboard/servers defaults sections; listener ownership should be single-context.
- Preserve `activeServerProvider` as the only persisted selected-server source.

## Sources

- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `.planning/milestones/v1.4-phases/03-dashboard-telegram-cta-announcements/03-01-SUMMARY.md`
- `.planning/milestones/v1.4-phases/03-dashboard-telegram-cta-announcements/03-02-SUMMARY.md`
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/dashboard/presentation/widgets/default_servers_section.dart`
- `lib/features/server/presentation/screens/server_list_screen.dart`
- `lib/features/server/presentation/providers/active_server_provider.dart`
- `lib/features/dashboard/presentation/providers/default_servers_provider.dart`
