---
phase: 04-routing-dns-advanced-settings
plan: 05
subsystem: ui
tags: [routing, riverpod, filter-chips, domain-rules, per-app-proxy, expansion-tile]

requires:
  - phase: 04-01
    provides: SettingsLocalDatasource, RoutingLocalDatasource, DomainRule entity, DomainRuleModel
  - phase: 04-03
    provides: VpnPlatformService.getInstalledApps() MethodChannel

provides:
  - RoutingSettingsNotifier Riverpod provider for all routing state
  - InstalledApps FutureProvider fetching apps from native PackageManager
  - Complete routing screen with 3 collapsible sections (region presets, domain rules, per-app proxy)
  - RegionPresetsSection widget with Iran/China/Russia filter chips
  - DomainRuleRow widget with color-coded action dropdown
  - AddDomainRuleDialog with domain validation and action SegmentedButton
  - AppPickerList with searchable checkbox list and base64 app icons

affects: [xray-config-builder, vpn-service]

tech-stack:
  added: []
  patterns:
    - "Riverpod keepAlive notifier for compound routing state (bypass LAN + regions + rules + per-app)"
    - "FilterChip row for multi-select region presets"
    - "SegmentedButton<String> for modal selection (proxy/direct/block and blacklist/whitelist)"
    - "AnimatedSize for smooth expand/collapse of per-app section"
    - "ConstrainedBox + ListView.builder for efficient app list rendering"

key-files:
  created:
    - lib/features/routing/presentation/providers/routing_settings_provider.dart
    - lib/features/routing/presentation/providers/routing_settings_provider.g.dart
    - lib/features/routing/presentation/providers/installed_apps_provider.dart
    - lib/features/routing/presentation/providers/installed_apps_provider.g.dart
    - lib/features/routing/presentation/widgets/region_presets_section.dart
    - lib/features/routing/presentation/widgets/domain_rule_row.dart
    - lib/features/routing/presentation/widgets/add_domain_rule_dialog.dart
    - lib/features/routing/presentation/widgets/app_picker_list.dart
  modified:
    - lib/features/routing/presentation/screens/routing_screen.dart

key-decisions:
  - "RoutingSettings compound state class (not separate providers) to keep all routing state in one notifier"
  - "Apps sorted alphabetically by name in installedAppsProvider for consistent UX"
  - "Domain input validation strips http/https prefix and requires dot for basic format check"
  - "Mode switch clears app selection (per UI-SPEC interaction contract)"

patterns-established:
  - "Compound state with copyWith for multi-field Riverpod notifiers"
  - "FilterChip row for region presets — horizontally scrollable"
  - "SnackBar undo pattern for destructive actions (domain rule delete)"

requirements-completed: [ROUTE-03, ROUTE-04, ROUTE-05]

duration: 7min
completed: 2026-04-05
---

# Phase 04 Plan 05: Routing Screen UI Summary

**Full routing configuration UI with region presets (Iran/China/Russia filter chips), domain rules (add/edit/delete with undo), and per-app proxy (searchable app picker with blacklist/whitelist toggle)**

## Performance

- **Duration:** 7 min
- **Started:** 2026-04-05T20:15:59Z
- **Completed:** 2026-04-05T20:23:42Z
- **Tasks:** 2/2
- **Files modified:** 9

## Accomplishments

### Task 1: Routing provider + Region Presets + Domain Rules
- Created `RoutingSettingsNotifier` — keepAlive Riverpod notifier managing bypass LAN, region presets, custom domain rules, and per-app proxy state with persistence to SharedPreferences and Hive
- Created `RegionPresetsSection` — FilterChip row for Iran/China/Russia region bypass with bundled rules note and update button
- Created `DomainRuleRow` — color-coded action dot (proxy=primary, direct=green, block=red), action dropdown, and delete button
- Created `AddDomainRuleDialog` — TextField with URL keyboard type, SegmentedButton for proxy/direct/block, domain validation that strips http/https prefixes
- Replaced routing_screen.dart StatefulWidget with ConsumerStatefulWidget using Riverpod for all state (no more setState for bypass LAN)
- Added ExpansionTile sections for Region Presets (initially expanded) and Domain Rules with add rule button and undo on delete

### Task 2: Per-App Proxy section
- Created `InstalledApp` model and `installedAppsProvider` FutureProvider that fetches apps from Android PackageManager via VpnPlatformService MethodChannel
- Created `AppPickerList` — searchable checkbox list with base64-decoded app icons, error fallback to Android icon, and ConstrainedBox (maxHeight 400) for efficient lazy rendering
- Added Per-App Proxy ExpansionTile with enable toggle, blacklist/whitelist SegmentedButton, mode description text, and AnimatedSize for smooth show/hide transition

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| TODO: Download community rules from GitHub | region_presets_section.dart | 70 | Update Rules button shows SnackBar placeholder — community rule download is a future feature beyond current plan scope |

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 51101bd | feat(04-05): routing provider, region presets, and domain rules UI |
| 2 | f66bed8 | feat(04-05): per-app proxy section with installed apps provider and app picker |

## Self-Check: PASSED

All 9 created/modified files verified on disk. Both commit hashes (51101bd, f66bed8) found in git log.
