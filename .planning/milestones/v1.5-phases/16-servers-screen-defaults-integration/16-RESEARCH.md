# Phase 16: Servers Screen Defaults Integration - Research

**Researched:** 2026-05-25  
**Domain:** Flutter Servers screen UI integration (default servers + existing grouped list parity)  
**Confidence:** High

## Existing pattern map (reuse first)

- `server_list_screen.dart` already owns:
  - grouped imported servers
  - collapsible group headers
  - multi-select mode switching
  - active server row highlighting + selection taps
- `default_servers_section.dart` already owns:
  - default-server data loading/offline/failure states
  - tap-to-select and reconnect behavior parity path
- `active_server_provider.dart` and `connection_provider.dart` are the existing source of truth for selected server and switching behavior.

## Integration points

1. Insert a dedicated defaults section into `ServerListScreen` list composition before imported/custom groups.
2. Render defaults in compact row style aligned to imported rows (per locked decision D-05).
3. Hide defaults section during multi-select mode (D-02).
4. Keep defaults section collapsible and start expanded (D-03, D-04).
5. Route default-row taps through existing selection/switch behavior path (D-07).

## Risks and mitigations

- **Risk:** multi-select interactions leaking into defaults section.
  - **Mitigation:** gate section visibility on `multiSelectProvider.isEmpty`.
- **Risk:** selected-state inconsistency between defaults/imported rows.
  - **Mitigation:** always compare row identity against `activeServerProvider`.
- **Risk:** regressions in imported group behavior.
  - **Mitigation:** keep imported-group rendering path untouched and append defaults section as separate block.

## Recommended implementation order

1. Extract/reuse compact default-row renderer in server feature.
2. Add collapsible defaults section (expanded by default) above imported groups.
3. Wire tap behavior to active-server + connection parity path.
4. Add tests for visibility, collapse, and tap parity.
5. Regression pass against existing server-list behavior.

## Test strategy and edge cases

- Section visible in normal mode and hidden in multi-select mode.
- Section starts expanded each screen open.
- Collapse/expand toggles do not affect imported groups.
- Tapping default row selects server and reconnects when connected to different server.
- Imported group collapse/select/delete flows remain unchanged.

## Non-goals

- No changes to default-server provider network/cache contract.
- No backend/API contract updates.
- No behavior rewrite for connection/auth flows.
- No persisted collapse state for default section in this phase.
