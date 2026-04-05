---
phase: 02-vpn-engine-core-connection
plan: 01
subsystem: engine
tags: [xray-core, aar, vpnservice, android, go-mobile, geo-routing]

# Dependency graph
requires: []
provides:
  - "libv2ray.aar binary integrated as Gradle fileTree dependency"
  - "AndroidManifest with VpnService declaration in :vpn_process"
  - "geoip.dat and geosite.dat bundled in Android assets"
  - "ic_vpn_key.xml notification icon for foreground service"
  - "useLegacyPackaging=true for Go native JNI libs"
affects: [02-02, 02-03, 02-04, 02-05]

# Tech tracking
tech-stack:
  added: [libv2ray.aar (Xray-core via Go-Mobile), geoip.dat, geosite.dat]
  patterns: [AAR fileTree dependency, separate VPN process, Android 14+ foreground service permissions]

key-files:
  created:
    - android/app/libs/libv2ray.aar
    - android/app/src/main/assets/geoip.dat
    - android/app/src/main/assets/geosite.dat
    - android/app/src/main/res/drawable/ic_vpn_key.xml
  modified:
    - android/app/build.gradle.kts
    - android/app/src/main/AndroidManifest.xml

key-decisions:
  - "Used 2dust/AndroidLibXrayLite AAR (ArmavVPN fork returned 404)"
  - "Committed binary assets directly to git (no LFS configured)"

patterns-established:
  - "AAR integration: fileTree dependency in build.gradle.kts for libs/*.aar"
  - "VPN service isolation: :vpn_process separate process for crash safety"
  - "Android 14+ compliance: FOREGROUND_SERVICE_SPECIAL_USE + PROPERTY_SPECIAL_USE_FGS_SUBTYPE"

requirements-completed: [ENG-01, ENG-05]

# Metrics
duration: 5min
completed: 2026-04-05
---

# Phase 02 Plan 01: AAR + Manifest + Geo Assets Summary

**Xray-core AAR (53MB) integrated via Gradle fileTree with useLegacyPackaging, VpnService declared in :vpn_process with Android 14+ permissions, and geo-routing data bundled**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-05T10:43:35Z
- **Completed:** 2026-04-05T10:48:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Integrated Xray-core AAR binary (53MB) from 2dust/AndroidLibXrayLite as Gradle fileTree dependency
- Configured useLegacyPackaging=true for Go native JNI libraries in AAR
- Added all 6 required Android permissions including FOREGROUND_SERVICE_SPECIAL_USE for Android 14+
- Declared ArmaVpnService in separate :vpn_process with BIND_VPN_SERVICE, SUPPORTS_ALWAYS_ON, and foregroundServiceType=specialUse
- Bundled geoip.dat (~18.8MB) and geosite.dat (~10MB) for IP/domain-based traffic routing
- Created Material Design vpn_key notification icon for foreground service

## Task Commits

Each task was committed atomically:

1. **Task 1: Download AAR + geo assets, configure Gradle for Xray-core** - `c5b8e14` (feat)
2. **Task 2: AndroidManifest permissions + VpnService declaration + notification icon** - `843ffc0` (feat)

## Files Created/Modified
- `android/app/libs/libv2ray.aar` - Xray-core engine compiled as Android AAR (53MB)
- `android/app/build.gradle.kts` - Added packaging.jniLibs.useLegacyPackaging + fileTree AAR dependency
- `android/app/src/main/assets/geoip.dat` - IP-based routing database (~18.8MB)
- `android/app/src/main/assets/geosite.dat` - Domain-based routing database (~10MB)
- `android/app/src/main/AndroidManifest.xml` - 6 permissions + VpnService declaration with :vpn_process
- `android/app/src/main/res/drawable/ic_vpn_key.xml` - Material vpn_key vector drawable for notifications

## Decisions Made
- **AAR source:** Used 2dust/AndroidLibXrayLite (ArmavVPN fork returned 404). This is the canonical, widely-used source (53k+ stars).
- **Binary commits:** Committed AAR and geo data directly to git without LFS. Standard practice for Android projects of this type (V2rayNG does the same).

## Deviations from Plan

None - plan executed exactly as written (except AAR source fallback from ArmavVPN to 2dust, which was the planned fallback behavior).

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- AAR is integrated and Gradle recognizes it — ready for Kotlin wrapper code (Plan 02)
- AndroidManifest has VpnService declared — ready for ArmaVpnService implementation (Plan 03)
- Geo data is bundled — ready for routing rule configuration (Plan 04/05)
- Note: `flutter build apk` will show missing ArmaVpnService class error — expected, class created in Plan 03

---
*Phase: 02-vpn-engine-core-connection*
*Completed: 2026-04-05*

## Self-Check: PASSED

All 6 created/modified files verified present. Both task commits (c5b8e14, 843ffc0) verified in git log.
