# Phase 1: Foundation & Config Import - Context

**Gathered:** 2026-04-04
**Status:** Ready for planning

<domain>
## Phase Boundary

Project architecture setup, UI shell screens (Dashboard, Servers, Routing, Settings), theming with light/dark mode, multi-language support (EN, FA, RU, ZH with RTL for Persian), share link parsing for all 5 protocol types, clipboard import, manual JSON config entry, local storage persistence via hive_ce, and server list with selection capability. Connection logic and VpnService integration are Phase 2.

</domain>

<decisions>
## Implementation Decisions

### Design System
- **D-01:** Primary color palette is teal/cyan accent — modern feel, differentiated from competitors' blue/indigo schemes
- **D-02:** Use Material 3 defaults with custom ColorScheme — minimal custom components, ship faster. No custom design system build.
- **D-03:** The connect/disconnect button is a custom circular button with press animation — power-button style, satisfying feedback (Happ-inspired). This is the ONE custom UI element.
- **D-04:** Light and dark themes using Flutter ThemeData with teal/cyan seed color

### Navigation
- **D-05:** Bottom navigation bar with 4 tabs: Dashboard, Servers, Routing, Settings
- **D-06:** Navigation via go_router with shell route for bottom nav persistence
- **D-07:** Each tab is top-level — Routing is its own tab, not nested in Settings

### Server List Display
- **D-08:** Server items displayed as cards (not list tiles) — each server in a card with protocol badge, server name, and visual separation (Hiddify-style)
- **D-09:** Servers grouped by subscription source as sections; manually-added servers appear in a "Manual" section
- **D-10:** Tap to select as active node (highlighted/checked state)

### Share Link Parsing
- **D-11:** Parse all 5 protocol share link formats in Phase 1: vless://, vmess:// (both legacy base64-JSON and standard URI), trojan://, ss://, hysteria2://
- **D-12:** Parsers are pure Dart — no platform channels needed. Unit-testable.

### Agent's Discretion
- Exact spacing, typography, and card shadow/radius values
- Loading skeleton and empty state designs
- Error handling UI patterns (snackbar vs dialog)
- Exact hive_ce box structure and schema design
- go_router route naming conventions

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### UI/UX Specification
- `happ_clone_specs.md` §3 — UI/UX Specifications (Android App): Dashboard layout, Configurations/Nodes screen, Routing screen, Settings screen, Design System colors/typography
- `happ_clone_specs.md` §2 — Technical Capabilities: Supported protocols, subscription management, multi-selection

### Architecture & Stack
- `.planning/research/STACK.md` — Recommended Flutter packages with verified versions (Riverpod 3.3, go_router 17.2, hive_ce 2.19, freezed, json_serializable)
- `.planning/research/ARCHITECTURE.md` — Clean Architecture layers, feature-first module organization, platform channel contract
- `.planning/codebase/STACK.md` — Current codebase state (default Flutter scaffold)
- `.planning/codebase/STRUCTURE.md` — Current directory layout

### Feature Analysis
- `.planning/research/FEATURES.md` — Feature landscape with table stakes, dependency graph, and share link format details
- `.planning/research/PITFALLS.md` §Config Parsing — VMess dual format pitfall, share link edge cases

### Project Context
- `.planning/PROJECT.md` — Core value, constraints, key decisions
- `.planning/REQUIREMENTS.md` — STOR-01/02, UI-01/03/07, CONF-01/03/05/06, SERV-01/02

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — project is a default Flutter scaffold (`flutter create`). Only `lib/main.dart` exists with counter app.

### Established Patterns
- None — clean slate. Phase 1 establishes all patterns:
  - Clean Architecture + MVVM layer structure
  - Riverpod provider organization
  - Feature-first directory layout
  - hive_ce storage patterns

### Integration Points
- `lib/main.dart` — will be completely replaced with app initialization, Riverpod scope, go_router setup
- `android/app/build.gradle` — needs applicationId change from `com.example` to proper package name
- `pubspec.yaml` — needs all dependencies added

</code_context>

<specifics>
## Specific Ideas

- Connect button should feel like Happ's power button — circular, satisfying press animation, clear state feedback
- Server cards should have visual separation like Hiddify — not cramped V2rayNG list tiles
- Teal/cyan color scheme to stand out from the sea of blue VPN apps
- Protocol badges on server cards (small colored chips: VLESS, VMess, Trojan, SS, Hysteria2)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation-config-import*
*Context gathered: 2026-04-04*
