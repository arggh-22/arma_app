---
phase: 02-vpn-engine-core-connection
plan: 02
subsystem: engine
tags: [xray-core, xray-json, config-builder, vless, vmess, trojan, shadowsocks, split-dns, lan-bypass, speed-formatter]

# Dependency graph
requires:
  - phase: 02-01
    provides: "Xray-core AAR integrated, AndroidManifest VpnService declared, geo-routing data bundled"
provides:
  - "XrayConfigBuilder.build(ServerConfig) → complete Xray JSON config string"
  - "formatSpeed(int) → human-readable speed string (B/s, KB/s, MB/s, GB/s)"
  - "Split DNS configuration (Cloudflare 1.1.1.1 + localhost)"
  - "LAN bypass routing via geoip:private + geosite:private rules"
  - "Stats + policy sections enabling QueryStats traffic monitoring"
affects: [02-03, 02-04, 02-05]

# Tech tracking
tech-stack:
  added: []
  patterns: [Dart 3 switch expression for protocol dispatch, Pure-Dart Xray JSON config generation (D-02)]

key-files:
  created:
    - lib/xray/xray_config_builder.dart
    - lib/xray/formatters/speed_formatter.dart
    - test/xray/xray_config_builder_test.dart
    - test/xray/speed_formatter_test.dart
  modified: []

key-decisions:
  - "Config builder uses Dart 3 switch expressions for protocol dispatch — exhaustive pattern matching"
  - "VMess encryption 'none' maps to security 'auto' (Xray-core chooses optimal encryption)"
  - "H2 transport always forces TLS regardless of security field value"
  - "DNS simplified to 1.1.1.1 + localhost (not CN-specific like V2rayNG) since target is general censored regions"

patterns-established:
  - "XrayConfigBuilder: static build() method returns JSON string, private helpers return Map<String,dynamic>"
  - "Protocol settings dispatch: VLESS/VMess → vnext[], Trojan/SS → servers[] (per Xray spec)"
  - "Flow field gating: _resolveFlow() enforces VLESS+TCP+(TLS|Reality) only"
  - "TDD: tests written first, implementation follows (RED→GREEN flow)"

requirements-completed: [ENG-02, PROTO-01, PROTO-02, PROTO-03, PROTO-04, PROTO-06, ROUTE-01, ROUTE-06]

# Metrics
duration: 3min
completed: 2026-04-05
---

# Phase 02 Plan 02: Xray JSON Config Builder + Speed Formatter Summary

**Pure-Dart XrayConfigBuilder producing valid Xray JSON for 4 protocols × 4 transports × 3 TLS modes, with split DNS, LAN bypass routing, and traffic stats sections — 21 unit tests passing**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-05T10:51:19Z
- **Completed:** 2026-04-05T10:54:29Z
- **Tasks:** 2 (TDD: RED + GREEN cycle)
- **Files modified:** 4

## Accomplishments
- XrayConfigBuilder.build(ServerConfig) generates complete, valid Xray-core JSON config strings
- Handles all 4 protocols: VLESS (with Reality + XTLS-Vision), VMess, Trojan, Shadowsocks
- Correct outbound structures: vnext[] for VLESS/VMess, servers[] for Trojan/SS (per Xray spec)
- VLESS flow field only set for TCP + TLS/Reality — cleared for WS/gRPC/H2 (prevents connection failure)
- Reality uses realitySettings, TLS uses tlsSettings — never mixed (per research pitfalls)
- H2 transport always forces TLS security mode
- Stats + policy sections included for QueryStats traffic monitoring
- Split DNS (Cloudflare 1.1.1.1 + localhost) for DNS leak prevention (D-11)
- LAN bypass via geoip:private + geosite:private routing rules (D-12)
- formatSpeed utility converts bytes/sec to human-readable B/s, KB/s, MB/s, GB/s
- 21 unit tests covering all protocol/transport combinations, config structure, edge cases

## Task Commits

Each task was committed atomically (TDD: RED → GREEN):

1. **Task 1 (RED): Failing tests for config builder + speed formatter** - `3c5c050` (test)
2. **Task 1 (GREEN): XrayConfigBuilder + formatSpeed implementation** - `30ff6ae` (feat)

_Note: Task 2 (unit tests) merged into Task 1's TDD cycle — tests written first as RED phase, then implementation as GREEN._

## Files Created/Modified
- `lib/xray/xray_config_builder.dart` - ServerConfig → complete Xray JSON config builder (307 lines)
- `lib/xray/formatters/speed_formatter.dart` - Bytes/sec to human-readable speed string formatter
- `test/xray/xray_config_builder_test.dart` - 15 test cases across 6 groups for config builder
- `test/xray/speed_formatter_test.dart` - 6 test cases for speed formatting tiers

## Decisions Made
- **VMess security mapping:** `encryption: 'none'` → `security: 'auto'` (lets Xray-core choose optimal encryption per research)
- **DNS simplification:** Used 1.1.1.1 + localhost (not CN-specific DoH + fallback like V2rayNG) since Arma targets general censored regions
- **TDD merge:** Tasks 1 and 2 executed as single TDD cycle since tests and implementation are inherently coupled
- **Dart 3 switch expressions:** Used exhaustive pattern matching on ProtocolType enum for protocol dispatch

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- XrayConfigBuilder ready to be called by connection provider (Plan 03/04)
- JSON output ready to be passed via MethodChannel to native ArmaVpnService
- formatSpeed ready for traffic stats display widgets (Plan 04/05)
- Stats + policy sections ensure QueryStats will return traffic data when connected
- Note: Builder handles Hysteria2 protocol settings (placeholder for Phase 4)

---
*Phase: 02-vpn-engine-core-connection*
*Completed: 2026-04-05*

## Self-Check: PASSED

All 4 created files verified present. Both task commits (3c5c050, 30ff6ae) verified in git log.
