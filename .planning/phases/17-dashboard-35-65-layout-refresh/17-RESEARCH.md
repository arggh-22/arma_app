# Phase 17: dashboard-35-65-layout-refresh - Research

**Researched:** 2026-05-24  
**Domain:** Flutter dashboard UI composition refresh (behavior-preserving)  
**Confidence:** HIGH

## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-17-01:** Keep current scroll-based dashboard structure and emulate 35/65 visually (not a strict fixed-height split container). [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- **D-17-02:** Apply top/bottom visual grouping so top area reads as 35% and bottom area reads as 65% in normal viewport conditions. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- **D-17-03:** Keep existing `ActiveServerCard` component as the selected-server surface. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- **D-17-04:** Add clear parked/highlight treatment to `ActiveServerCard` rather than replacing component structure. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- **D-17-05:** In bottom panel, render announcements first, then default-server cards. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- **D-17-06:** If announcement content is absent, hide announcement block entirely and let default servers move up. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- **D-17-07:** Preserve existing connect/disconnect behavior, default-server tap behavior, and provider wiring. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- **D-17-08:** Preserve existing announcement read-more behavior and sheet interaction. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]

### the agent's Discretion
- Exact visual affordance for parked highlight (border/accent/background), provided it is clearly distinguishable. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- Final spacing tokens used to communicate 35/65 visual balance in scroll layout. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- Minor typography emphasis adjustments within existing design language. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]

### Deferred Ideas (OUT OF SCOPE)
- Device-class adaptive ratio tuning (e.g., tablet-specific 35/65 variation). [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- New data contracts for announcements or default servers. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]
- Reworking core connection/auth/server-selection behavior. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DLAY-01 | Fixed 35% top / 65% bottom visual composition | Visual grouping wrappers + min-height budget strategy in existing `SingleChildScrollView` |
| DLAY-02 | Top panel shows connect, selected server, stats | Reuse existing top widgets and provider wiring in `dashboard_screen.dart` |
| DLAY-03 | Bottom panel shows announcements + default servers | Preserve existing content gating; enforce announcement-before-default order |
| DLAY-04 | Selected server clearly parked/highlighted | Add accent border/tint treatment in `ActiveServerCard` without structural replacement |
</phase_requirements>

## Summary

Phase 17 is a **presentation-only refactor** on top of already-correct behavior paths in `DashboardScreen`, `ActiveServerCard`, and `DefaultServersSection`. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] [VERIFIED: lib/features/dashboard/presentation/widgets/active_server_card.dart] [VERIFIED: lib/features/dashboard/presentation/widgets/default_servers_section.dart]  
The lowest-risk strategy is to keep the current `SingleChildScrollView` composition and add two visual group containers (“top panel”, “bottom panel”) with spacing and min-height cues that read as 35/65 without forcing strict viewport math. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md] [CITED: https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html] [ASSUMED]

For parked selected-server emphasis, keep `ActiveServerCard` as the interaction shell and apply accent treatment through card border/background tint when a server is selected. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md] [VERIFIED: lib/features/dashboard/presentation/widgets/active_server_card.dart]  
Ordering/visibility must remain content-driven: announcement card appears only when title or text exists, and defaults follow it. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] [VERIFIED: test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart]

**Primary recommendation:** Implement a **grouped-scroll layout refactor** in `dashboard_screen.dart` plus **non-invasive parked styling** in `active_server_card.dart`, then extend existing widget tests for panel grouping and highlight regressions. [VERIFIED: .planning/REQUIREMENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| 35/65 dashboard visual grouping | Browser / Client | — | Pure Flutter widget composition concern. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] |
| Selected-server parked highlight | Browser / Client | — | Card styling change only; no domain/data changes. [VERIFIED: lib/features/dashboard/presentation/widgets/active_server_card.dart] |
| Announcement visibility/order | Browser / Client | API / Backend | UI decides visibility/order; data originates from auth state provider payload. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] |
| Default-server display in bottom panel | Browser / Client | API / Backend | Section already consumes provider state and renders cards. [VERIFIED: lib/features/dashboard/presentation/widgets/default_servers_section.dart] |
| Tap/connect parity guardrail | Browser / Client | API / Backend | Existing notifier flow must remain untouched. [VERIFIED: lib/features/dashboard/presentation/widgets/default_servers_section.dart] |

## Project Constraints (from copilot-instructions.md)

- Use Flutter + Clean Architecture/MVVM conventions already established for this repo. [VERIFIED: copilot-instructions.md]
- Keep Dart style conventions (`snake_case` files, `PascalCase` classes, `camelCase` members). [VERIFIED: copilot-instructions.md]
- Prefer `const` constructors/immutables where possible. [VERIFIED: copilot-instructions.md]
- Do not use `print()`; use `debugPrint`/logging patterns. [VERIFIED: copilot-instructions.md]
- Preserve Riverpod provider patterns and existing wiring contracts. [VERIFIED: copilot-instructions.md]
- Avoid behavior rewrites beyond approved phase scope. [VERIFIED: .planning/REQUIREMENTS.md] [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK widgets (`SingleChildScrollView`, `Card`, `Column`) | Flutter 3.41.6 (env) | Layout and visual grouping | Already used in target screen; minimal risk path. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] [VERIFIED: bash: flutter --version] |
| flutter_riverpod | 3.3.1 | State wiring for auth/connection/settings/defaults | Existing providers already power dashboard behavior. [VERIFIED: pubspec.lock] [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] |
| gap | 3.0.1 | Spacing rhythm | Already used across dashboard screen and tests. [VERIFIED: pubspec.lock] [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| go_router | 17.2.0 | Existing navigation fallback paths | Keep unchanged for active card and FAB flows. [VERIFIED: pubspec.lock] [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] |
| font_awesome_flutter | 10.12.0 | Telegram FAB icon | Unchanged regression surface. [VERIFIED: pubspec.lock] [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] |
| url_launcher | 6.3.2 | Telegram bot external launch | Keep current behavior untouched. [VERIFIED: pubspec.lock] [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Scroll-group emulation | Strict viewport split with hard `SizedBox(height: MediaQuery.size.height * 0.35)` | Hard split is brittle with dynamic content and small screens; conflicts with locked decision D-17-01. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md] [ASSUMED] |
| Reusing `ActiveServerCard` | New dedicated parked widget | Higher regression risk and violates D-17-03. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md] |

**Installation:**
```bash
# No new packages required for Phase 17
```

## Architecture Patterns

### System Architecture Diagram

```text
[Riverpod providers: auth/connection/ui/defaults]
                    |
                    v
            DashboardScreen (scroll root)
                    |
      +-------------+-------------+
      |                           |
      v                           v
Top Visual Group (~35 cue)   Bottom Visual Group (~65 cue)
(connect/status/timer/        (announcement conditional,
 ActiveServerCard/stats)       then DefaultServersSection)
      |                           |
      v                           v
ActiveServerCard tap -> router   Announcement read-more -> bottom sheet
DefaultServersSection tap -> activeServerProvider -> connectionProvider
```
[VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] [VERIFIED: lib/features/dashboard/presentation/widgets/default_servers_section.dart]

### Recommended Project Structure
```text
lib/features/dashboard/presentation/screens/dashboard_screen.dart      # panel grouping composition
lib/features/dashboard/presentation/widgets/active_server_card.dart    # parked highlight styling
test/features/dashboard/presentation/screens/dashboard_screen_*.dart    # ordering/visibility/layout cues
test/features/dashboard/presentation/widgets/default_servers_section_test.dart # behavior parity guard
```
[VERIFIED: repository paths listed above]

### Pattern 1: Grouped Scroll Composition
**What:** Keep a single scroll root and wrap current sections into top/bottom visual containers with spacing/min-height cues. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]  
**When to use:** Visual ratio target with behavior-preserving constraint and variable content height. [VERIFIED: .planning/REQUIREMENTS.md] [ASSUMED]

### Pattern 2: Parked Highlight via Existing Card Shell
**What:** Add selected-state style (accent border + subtle tinted background) inside existing `ActiveServerCard`. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]  
**When to use:** Need stronger selection affordance without changing navigation/tap contracts. [VERIFIED: lib/features/dashboard/presentation/widgets/active_server_card.dart]

### Anti-Patterns to Avoid
- **Hard fixed-height split container:** Causes clipping/awkward scroll behavior on smaller devices. [ASSUMED]
- **Duplicating server-selection logic in UI layer:** Must keep provider flow as-is. [VERIFIED: lib/features/dashboard/presentation/widgets/default_servers_section.dart]
- **Changing announcement semantics/keys:** Existing tests depend on current behavior and keys. [VERIFIED: test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| 35/65 perception in scroll view | Custom render/layout delegate | Existing Flutter layout primitives + spacing/min-height hints | Lower risk and aligns with current architecture. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] [CITED: https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html] |
| Selected card identity | New dashboard-selected component tree | Existing `ActiveServerCard` with style extension | Preserves behavior parity by construction. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md] |
| Announcement/default ordering logic rewrite | New data transformation layer | Existing `hasAnnouncement` gate + current render order | Already tested and passing. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart] [VERIFIED: test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart] |

## Common Pitfalls

### Pitfall 1: “35/65” implemented as strict viewport math
**What goes wrong:** content overflows or visually breaks on small-height screens. [ASSUMED]  
**How to avoid:** use visual grouping cues, not hard non-scrollable slices, per D-17-01. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md]

### Pitfall 2: Parked style breaks existing card affordance
**What goes wrong:** reduced contrast or unclear tap affordance if color-only change is too subtle. [ASSUMED]  
**How to avoid:** combine border + tinted surface + optional “Selected” label semantics key for testability. [ASSUMED]

### Pitfall 3: Regression in announcement/default order
**What goes wrong:** defaults render before announcement or announcement remains when empty. [VERIFIED: test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart]  
**How to avoid:** keep existing conditional gate and explicit order in bottom group. [VERIFIED: lib/features/dashboard/presentation/screens/dashboard_screen.dart]

## Code Examples

### Bottom group ordering pattern (reuse)
```dart
if (hasAnnouncement) ...[
  Card(key: const Key('dashboard-announcement-card'), child: ...),
],
const DefaultServersSection(),
```
Source: `lib/features/dashboard/presentation/screens/dashboard_screen.dart` [VERIFIED]

### Behavior parity for default-server tap (must preserve)
```dart
await ref.read(activeServerProvider.notifier).selectServer(target);
if (connectionState is Connected && currentSelection?.id != target.id) {
  await connectionNotifier.disconnect();
  await connectionNotifier.connect(target);
}
```
Source: `lib/features/dashboard/presentation/widgets/default_servers_section.dart` [VERIFIED]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Linear ungrouped dashboard flow | Grouped visual top/bottom while preserving same scroll tree | Phase 17 target | Achieves visual refresh without behavior churn. [VERIFIED: .planning/ROADMAP.md] [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md] |

**Deprecated/outdated for this phase:**
- Strict fixed split containers for all devices: out of scope and higher-risk than visual emulation. [VERIFIED: .planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md] [ASSUMED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Visual spacing/min-height cues are sufficient for users to perceive 35/65 on most phones | Summary / Architecture Patterns | Medium: may require UAT tuning |
| A2 | Accent border+tint alone is enough for clear parked emphasis | Pattern 2 / Pitfalls | Medium: may need additional label/icon |

## Open Questions (RESOLVED)

1. Parked treatment will include a visible “Selected” label/chip plus accent border/tint to improve clarity and testability. [RESOLVED]
2. No hard viewport threshold will be introduced in this phase; spacing remains responsive within current scroll layout without device-class branching. [RESOLVED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter CLI | Widget tests + implementation verification | ✓ | 3.41.6 | — |
| Dart SDK | Analyzer/test runtime | ✓ | 3.10.7 | — |

[VERIFIED: bash environment checks]

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) [VERIFIED: pubspec.yaml] |
| Config file | none (default Flutter test conventions) [VERIFIED: repo scan] |
| Quick run command | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DLAY-01 | Top/bottom visual grouping present | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_layout_grouping_test.dart` | ❌ Wave 0 |
| DLAY-02 | Top panel contains connect + selected server + stats block (stats when pref true) | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_top_panel_test.dart` | ❌ Wave 0 |
| DLAY-03 | Announcement before defaults; announcement hidden when empty | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart` | ✅ |
| DLAY-04 | ActiveServerCard parked style visibly applied when selected | widget | `flutter test test/features/dashboard/presentation/widgets/active_server_card_parked_style_test.dart` | ❌ Wave 0 |

### Wave 0 Gaps
- [ ] `test/features/dashboard/presentation/screens/dashboard_screen_layout_grouping_test.dart`
- [ ] `test/features/dashboard/presentation/screens/dashboard_screen_top_panel_test.dart`
- [ ] `test/features/dashboard/presentation/widgets/active_server_card_parked_style_test.dart`

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Existing auth providers unchanged. [VERIFIED: D-17-07] |
| V3 Session Management | no | No session flow changes in this phase. [VERIFIED: D-17-07] |
| V4 Access Control | no | No permission model change. [VERIFIED: scope docs] |
| V5 Input Validation | no (UI-only) | No new user-input surface introduced. [VERIFIED: scope docs] |
| V6 Cryptography | no | No crypto/storage changes in scope. [VERIFIED: scope docs] |

### Known Threat Patterns for stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental behavior regression in connect/default tap flow | Tampering (logic integrity) | Keep provider contracts unchanged + regression tests on tap parity. [VERIFIED: default_servers_section.dart + tests] |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/17-dashboard-35-65-layout-refresh/17-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- `lib/features/dashboard/presentation/widgets/active_server_card.dart`
- `lib/features/dashboard/presentation/widgets/default_servers_section.dart`
- `test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart`
- `test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart`
- `test/features/dashboard/presentation/widgets/default_servers_section_test.dart`
- `copilot-instructions.md`
- `pubspec.yaml` / `pubspec.lock`

### Secondary (MEDIUM confidence)
- Flutter API docs:  
  - https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html  
  - https://api.flutter.dev/flutter/widgets/LayoutBuilder-class.html  
  - https://api.flutter.dev/flutter/widgets/FractionallySizedBox-class.html  
- Context7 CLI lookups for Flutter docs (`/websites/flutter_dev`, `/websites/api_flutter_dev_flutter`)

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all recommendations reuse installed, locked dependencies.
- Architecture: HIGH — directly constrained by approved context decisions.
- Pitfalls: MEDIUM — partly based on UI implementation heuristics.

**Research date:** 2026-05-24  
**Valid until:** 2026-06-23
