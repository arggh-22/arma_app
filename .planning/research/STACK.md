# Technology Stack — v1.5 Dashboard Layout Refresh + Servers Screen Defaults

## Recommended stack

- Keep existing Flutter + Riverpod + go_router + Hive stack.
- Add **no new dependencies** for this milestone.
- Implement via presentation-layer refactor and shared widgets/providers.

## Integration points

- `dashboard_screen.dart`: split into top/bottom layout sections (35/65).
- `server_list_screen.dart`: add default-servers section using existing default-server providers.
- Shared default-server card renderer for dashboard + servers screen.
- Reuse `activeServerProvider` for selected/parked server visual state.

## Explicitly avoid

- No state-management migration.
- No networking/storage contract changes.
- No heavy UI framework additions.
- No behavior changes to existing connection/auth flows.
