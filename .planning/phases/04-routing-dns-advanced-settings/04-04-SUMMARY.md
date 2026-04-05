---
phase: 04-routing-dns-advanced-settings
plan: 04
subsystem: settings-ui
tags: [dns, engine-settings, anti-censorship, cache-management, riverpod, settings-screen]
dependency_graph:
  requires: [04-01]
  provides: [dns-settings-ui, engine-settings-ui, anti-censorship-ui, cache-clearing-ui]
  affects: [settings-screen, vpn-connection-config]
tech_stack:
  added: [path_provider]
  patterns: [riverpod-keepAlive-notifier, animated-size-toggle, radio-group-picker, segmented-button-selector, modal-bottom-sheet]
key_files:
  created:
    - lib/features/settings/presentation/providers/engine_settings_provider.dart
    - lib/features/settings/presentation/providers/engine_settings_provider.g.dart
    - lib/features/settings/presentation/providers/dns_settings_provider.dart
    - lib/features/settings/presentation/providers/dns_settings_provider.g.dart
    - lib/features/settings/presentation/providers/anti_censorship_provider.dart
    - lib/features/settings/presentation/providers/anti_censorship_provider.g.dart
    - lib/features/settings/presentation/widgets/dns_picker_sheet.dart
  modified:
    - lib/features/settings/presentation/screens/settings_screen.dart
    - lib/core/l10n/app_localizations.dart
    - lib/core/l10n/app_localizations_en.dart
    - lib/core/l10n/app_localizations_fa.dart
    - lib/core/l10n/app_localizations_ru.dart
    - lib/core/l10n/app_localizations_zh.dart
decisions:
  - RadioGroup used instead of deprecated RadioListTile groupValue/onChanged (Flutter 3.41.6+)
  - SettingsScreen kept as ConsumerWidget (no StatefulWidget needed since AnimatedSize handles animations)
  - DnsPickerSheet uses RadioGroup for preset selection with custom input fallback
  - Anti-censorship profiles use const constructors for predictable state reset
metrics:
  duration: 13min
  tasks_completed: 2
  tasks_total: 2
  files_created: 7
  files_modified: 6
  completed_date: "2026-04-05"
---

# Phase 04 Plan 04: Settings Screen Extensions Summary

DNS/engine/anti-censorship settings sections with 3 Riverpod providers, DNS picker sheet with 5 presets, AnimatedSize toggles, and cache clearing dialog — all auto-saving to SharedPreferences.

## What Was Built

### Task 1: DNS and Engine Settings Providers + UI Sections

**Providers created:**
- `EngineSettingsNotifier` — manages sniffing (default ON), mux (default OFF), and mux concurrency (1–8) with SharedPreferences auto-save
- `DnsSettingsNotifier` — manages DNS protocol (DoH/DoT/Plain), remote DNS, and direct DNS with SharedPreferences auto-save

**DNS Picker Sheet:**
- Bottom sheet with 5 DNS presets: Cloudflare, Google, Quad9, AdGuard, Electro
- URL display adapts to active protocol (DoH → HTTPS URL, DoT → TLS URL, Plain → IP)
- Custom input option with TextField and submit button
- Uses Flutter 3.41.6 `RadioGroup` widget (not deprecated `groupValue`)

**Settings Screen DNS Section:**
- SegmentedButton with DoH/DoT/Plain protocol selector
- Remote DNS and Direct DNS ListTiles that open DNS picker sheet
- DNS updated SnackBar feedback

**Settings Screen Engine Settings Section:**
- Sniffing SwitchListTile (default ON, D-09)
- Mux SwitchListTile (default OFF, D-09)
- AnimatedSize concurrency Slider (1–8, visible only when mux enabled)

### Task 2: Anti-Censorship + Data Sections

**Provider created:**
- `AntiCensorshipNotifier` — manages profile presets (none/light/moderate/aggressive), fragment, padding, mixed SNI, and individual field customization

**Profile Presets (D-11):**
- None: all off
- Light: fragment 10–50
- Moderate: fragment 10–100, sleep 1–10ms, padding on
- Aggressive: fragment 1–100, sleep 10–50ms, padding on, mixed SNI on

**Settings Screen Anti-Censorship Section:**
- SegmentedButton profile selector with 4 options
- AnimatedSize profile description text
- Fragment toggle + AnimatedSize fragment size/sleep range TextFormFields
- Padding and Mixed SNI toggle switches

**Settings Screen Data Section:**
- Clear Cached Data ListTile
- Confirmation AlertDialog with destructive (error-colored) action button
- Scoped deletion: .dat geo rule files + temp directory (D-15: configs/prefs untouched)

## Section Order (Final)

1. General (theme + language)
2. DNS (protocol, remote DNS, direct DNS)
3. Engine Settings (sniffing, mux, concurrency)
4. Anti-Censorship (profile, fragment, sleep, padding, mixed SNI)
5. Diagnostics (view logs)
6. Data (clear cache)
7. About (version, licenses)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Used RadioGroup instead of deprecated RadioListTile API**
- **Found during:** Task 1
- **Issue:** Flutter 3.41.6 deprecated `RadioListTile.groupValue` and `RadioListTile.onChanged` in favor of `RadioGroup` ancestor widget
- **Fix:** Wrapped RadioListTile items in `RadioGroup<String>` with `groupValue` and `onChanged`
- **Files modified:** `lib/features/settings/presentation/widgets/dns_picker_sheet.dart`
- **Commit:** 306a3f1

**2. [Rule 3 - Blocking] Regenerated l10n files**
- **Found during:** Task 1
- **Issue:** l10n keys existed in ARB files but `AppLocalizations` class hadn't been regenerated to include them (getters like `dnsSection`, `engineSettingsSection` etc. were missing)
- **Fix:** Ran `flutter gen-l10n` to regenerate the Dart localizations from ARB source files
- **Files modified:** `lib/core/l10n/app_localizations*.dart`
- **Commit:** 306a3f1

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 306a3f1 | feat(04-04): add DNS and engine settings providers, DNS picker sheet, settings screen sections |
| 2 | e0c0e7a | feat(04-04): add anti-censorship section with profiles and data section with cache clearing |

## Self-Check: PASSED
