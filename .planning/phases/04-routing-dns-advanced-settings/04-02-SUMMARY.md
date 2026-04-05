---
phase: 04-routing-dns-advanced-settings
plan: 02
subsystem: xray-config-builder
tags: [xray, config, dns, routing, mux, fragment, hysteria2, vpn-settings]
dependency_graph:
  requires:
    - 04-01 (VpnSettings entity, SettingsLocalDatasource, RoutingLocalDatasource)
  provides:
    - Extended XrayConfigBuilder with VpnSettings parameter
    - ConnectionNotifier wired to read Phase 4 settings
  affects:
    - lib/xray/xray_config_builder.dart
    - lib/features/connection/presentation/providers/connection_provider.dart
    - lib/features/connection/data/datasources/vpn_platform_service.dart
tech_stack:
  added: []
  patterns:
    - Named optional parameter pattern for backward-compatible API extension
    - Settings snapshot pattern (VpnSettings.fromDatasource) for connect-time reads
key_files:
  created: []
  modified:
    - lib/xray/xray_config_builder.dart
    - lib/features/connection/presentation/providers/connection_provider.dart
    - lib/features/connection/presentation/providers/connection_provider.g.dart
    - lib/features/connection/data/datasources/vpn_platform_service.dart
decisions:
  - "VpnSettings passed as optional named parameter for backward compatibility"
  - "Mux excluded from Hysteria2 outbound (QUIC has built-in multiplexing)"
  - "Fragment sockopt uses tlshello packet targeting for anti-censorship"
  - "Region presets use geosite/geoip matching (category-ir, cn, category-ru)"
  - "setPerAppConfig stub added to VpnPlatformService (Rule 3 deviation)"
metrics:
  duration: 3min
  completed: 2026-04-05T19:48:40Z
  tasks: 2
  files: 4
---

# Phase 04 Plan 02: Config Builder VpnSettings Integration Summary

Extended XrayConfigBuilder with full VpnSettings integration — user-configurable DNS (DoH/DoT/plain), routing rules with region presets (Iran/China/Russia) and custom domain rules, mux multiplexing, TLS fragment anti-censorship, Hysteria2 stream settings, and sniffing toggle — all wired through ConnectionNotifier at connect time.

## What Was Done

### Task 1: Extend XrayConfigBuilder with VpnSettings parameter
- Modified `build()` to accept optional `VpnSettings? settings` parameter with sensible defaults
- `_buildDns()` now accepts `remoteDns` and `directDns` parameters (DoH/DoT/plain format)
- `_buildTunInbound()` accepts `sniffingEnabled` parameter and adds `routeOnly: false` field
- `_buildProxyOutbound()` adds mux config when enabled (excluded for Hysteria2)
- `_buildStreamSettings()` adds Hysteria2 early return with `network: hysteria2` + TLS settings
- Fragment sockopt with `packets: tlshello` added when `fragmentEnabled` is true
- `_buildRouting()` supports conditional LAN bypass, region presets (iran/china/russia with geosite/geoip), and custom domain rules (proxy/direct/block per domain)
- Hysteria2 `_buildProtocolSettings()` now includes conditional `up_mbps`/`down_mbps` bandwidth hints
- All changes are backward compatible — `build(server)` without settings uses VpnSettings defaults

### Task 2: Wire ConnectionNotifier to read VpnSettings at connect time
- Added imports for SharedPreferences, Hive, VpnSettings, SettingsLocalDatasource, RoutingLocalDatasource
- In `connect()`, reads VpnSettings from SharedPreferences + Hive domain_rules box before building config
- Passes `settings: vpnSettings` to `XrayConfigBuilder.build()`
- Adds per-app proxy config call wrapped in try-catch (safe for Plan 03 integration)
- Regenerated `connection_provider.g.dart` with updated hash

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added setPerAppConfig stub to VpnPlatformService**
- **Found during:** Task 2
- **Issue:** Plan calls `_platformService.setPerAppConfig()` but the method doesn't exist on VpnPlatformService yet (Plan 03 scope). Dart is statically typed — try-catch alone won't prevent compile error.
- **Fix:** Added stub `setPerAppConfig({required String? mode, required List<String> selectedApps})` to VpnPlatformService with debugPrint logging and TODO comment for Plan 03
- **Files modified:** lib/features/connection/data/datasources/vpn_platform_service.dart
- **Commit:** 5e7ad63

## Verification

- ✅ `VpnSettings` imported and used in xray_config_builder.dart
- ✅ `enabledRegions`, `muxEnabled`, `sniffingEnabled`, `fragmentEnabled` all present
- ✅ `hysteria2` branch with dedicated stream settings
- ✅ `up_mbps`/`down_mbps` conditional keys in Hysteria2 protocol settings
- ✅ `VpnSettings.fromDatasource` called in connection_provider.dart
- ✅ `XrayConfigBuilder.build(server, settings: vpnSettings)` wired correctly
- ✅ `setPerAppConfig` call wrapped in try-catch
- ✅ `build_runner build --delete-conflicting-outputs` exits 0
- ✅ Backward compatibility: `build(server)` still works without settings parameter

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| `setPerAppConfig` no-op | `vpn_platform_service.dart:102` | Plan 03 will implement native MethodChannel forwarding |

## Self-Check: PASSED

All 4 files verified present. Both commits (218f9e3, 5e7ad63) confirmed in git log.
