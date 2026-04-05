---
phase: 04-routing-dns-advanced-settings
plan: 03
subsystem: native-per-app-proxy
tags: [android, vpn-service, method-channel, split-tunneling, per-app-routing]
dependency_graph:
  requires: [04-01]
  provides: [per-app-proxy-native-pipeline]
  affects: [connection-flow, vpn-service]
tech_stack:
  added: []
  patterns: [SharedPreferences cross-process config, whitelist/blacklist split-tunneling]
key_files:
  created: []
  modified:
    - android/app/src/main/kotlin/com/arma/vpn/MainActivity.kt
    - android/app/src/main/kotlin/com/arma/vpn/service/ArmaVpnService.kt
    - lib/features/connection/data/datasources/vpn_platform_service.dart
decisions:
  - "SharedPreferences (per_app_config) for cross-process VPN service config rather than Intent extras — persists across service restarts"
  - "Whitelist mode uses ONLY addAllowedApplication; blacklist uses ONLY addDisallowedApplication — Android VpnService.Builder cannot mix them (Pitfall 3)"
  - "Self-exclusion implicit in whitelist (app not in allowed list), explicit in blacklist (addDisallowedApplication(packageName))"
  - "App icons rendered to 48x48 Bitmap then base64 PNG for MethodChannel transport"
metrics:
  duration: 6min
  completed: "2026-04-05T19:56:00Z"
  tasks: 2
  files: 3
---

# Phase 04 Plan 03: Native Per-App Proxy (Split Tunneling) Summary

Full Dart→Kotlin→VpnService per-app proxy pipeline: getInstalledApps enumerates user apps with base64 icons, setPerAppConfig persists whitelist/blacklist to SharedPreferences, and ArmaVpnService applies addAllowedApplication/addDisallowedApplication in TUN builder.

## What Was Built

### Task 1: getInstalledApps + setPerAppConfig MethodChannel Handlers
- **MainActivity.kt**: Added `getInstalledApps` handler that queries PackageManager, filters system apps (FLAG_SYSTEM), renders icons to 48x48 base64 PNG, and returns sorted list of `{packageName, appName, icon}` maps on IO dispatcher
- **MainActivity.kt**: Added `setPerAppConfig` handler that writes mode (blacklist/whitelist/null) and selected app package names to `per_app_config` SharedPreferences
- **vpn_platform_service.dart**: Added `getInstalledApps()` method returning `List<Map<String, dynamic>>` from MethodChannel
- **vpn_platform_service.dart**: Replaced stub `setPerAppConfig` with real MethodChannel invocation to native

### Task 2: Per-App Routing in ArmaVpnService
- **ArmaVpnService.kt**: Rewrote `configureTunInterface()` to read from `per_app_config` SharedPreferences
- **Whitelist mode**: Only selected apps route through VPN via `addAllowedApplication()` — self-exclusion implicit (our app not in allowed list)
- **Blacklist mode**: Selected apps bypasses VPN via `addDisallowedApplication()` — self always excluded explicitly
- **Default mode (null/no apps)**: Preserves Phase 2 behavior — self-exclusion only
- **Error resilience**: Each `addAllowedApplication`/`addDisallowedApplication` wrapped in try-catch for graceful handling of uninstalled package names

## Deviations from Plan

None — plan executed exactly as written.

## Decisions Made

1. **SharedPreferences for cross-process config** — VPN service runs in `:vpn_process`, can't access Flutter SharedPreferences. Using Android native SharedPreferences with `MODE_PRIVATE` allows the separate VPN process to read per-app configuration set by MainActivity.

2. **No mixing of allowed/disallowed** — Android VpnService.Builder throws IllegalStateException if both `addAllowedApplication` and `addDisallowedApplication` are called. Whitelist mode uses exclusively `addAllowedApplication`; blacklist mode uses exclusively `addDisallowedApplication`.

3. **48x48 icon bitmaps** — Balances quality vs. MethodChannel payload size. Non-BitmapDrawable icons (vector/adaptive) are rendered to a Canvas at this resolution.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | c47c05c | feat(04-03): add getInstalledApps + setPerAppConfig MethodChannel handlers |
| 2 | ed2730c | feat(04-03): add per-app routing to ArmaVpnService configureTunInterface |

## Self-Check: PASSED

All 3 modified files exist. Both task commits (c47c05c, ed2730c) verified in git log.
