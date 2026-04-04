# Technology Stack

**Project:** Arma Proxy & VPN Client
**Researched:** 2026-04-05
**Overall Confidence:** HIGH — verified via pub.dev API, GitHub source analysis of V2rayNG/AndroidLibXrayLite/Hiddify

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Flutter | 3.x (SDK ^3.11.4) | Cross-platform UI framework | Already scaffolded. Future iOS/desktop expansion with single codebase. Hiddify (57k+ stars) proves Flutter works for this domain. | HIGH |
| Dart | ^3.11.4 | Application language | Comes with Flutter. Current SDK constraint already set in pubspec.yaml. | HIGH |
| Kotlin | 2.x | Android native layer | Required for VpnService, MethodChannel bridge, and Xray-core AAR integration. V2rayNG uses Kotlin 2.3.0. | HIGH |

### State Management

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| flutter_riverpod | ^3.3.1 | Reactive state management | Spec requirement. Better testability than BLoC, less boilerplate. Code-gen approach with `@riverpod` annotation is the modern standard. Hiddify also uses hooks_riverpod. | HIGH |
| riverpod_annotation | ^4.0.2 | Code-gen annotations | Enables declarative provider definitions with `@riverpod`. Eliminates manual provider boilerplate. | HIGH |
| riverpod_generator | ^4.0.3 | Code generation (dev) | Generates provider code from annotations. Required companion to riverpod_annotation. | HIGH |
| riverpod_lint | ^3.1.3 | Linting rules (dev) | Catches common Riverpod mistakes at compile time. Essential for maintaining proper provider patterns. | HIGH |

### Navigation

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| go_router | ^17.2.0 | Declarative routing | Spec requirement. Official Flutter team package. Supports deep linking, shell routes for bottom nav, and redirect guards (for VPN permission flows). Hiddify uses ^16.2.4. | HIGH |

### Local Storage

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| hive_ce_flutter | ^2.3.4 | Lightweight NoSQL local DB | **Use hive_ce (Community Edition), NOT original hive.** Original hive last published 2022-06-30 — effectively abandoned. hive_ce is actively maintained (v2.19.3, published 2026-02-03), API-compatible drop-in replacement. Stores configs, subscriptions, routing rules. | HIGH |
| hive_ce | ^2.19.3 | Core Hive CE library | Base library for hive_ce_flutter. | HIGH |
| hive_ce_generator | ^1.11.1 | TypeAdapter code gen (dev) | Generates Hive TypeAdapters for data models. | HIGH |

### Data Modeling & Serialization

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| freezed_annotation | ^3.1.0 | Immutable data classes | Generates immutable models with copyWith, equality, and JSON serialization. Essential for Xray config models (VLESS, VMess, Trojan, etc.). | HIGH |
| freezed | ^3.2.5 | Code generation (dev) | Generates freezed model implementations. | HIGH |
| json_annotation | ^4.11.0 | JSON serialization annotations | Marks fields for JSON serialization. Used with json_serializable. | HIGH |
| json_serializable | ^6.13.1 | JSON code gen (dev) | Generates toJson/fromJson. Critical for converting Dart config models to Xray JSON format. | HIGH |
| build_runner | ^2.13.1 | Code gen runner (dev) | Runs all code generators (freezed, json_serializable, riverpod_generator, hive_ce_generator). | HIGH |

### Xray-core Engine (Native / Go)

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Xray-core | v26.3.27 (latest) | Proxy engine | The core protocol engine. Supports VLESS/Reality/XTLS, VMess, Trojan, Shadowsocks, Hysteria2. No alternatives — this IS the standard for this domain. | HIGH |
| AndroidLibXrayLite | HEAD (tracks xray-core) | Go-Mobile AAR wrapper | 2dust's official Go wrapper that compiles Xray-core into an Android AAR using gomobile. Used by V2rayNG (53k stars). This is THE reference implementation. | HIGH |
| golang.org/x/mobile | v0.0.0-20260312 | Go-Mobile toolchain | Compiles Go code into Android AAR (Java/Kotlin bindings). Required for AndroidLibXrayLite build. | HIGH |
| Go | 1.26+ | Build language for AAR | Required to compile AndroidLibXrayLite. Must match go.mod version constraint. | HIGH |

### Android Platform

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Android VpnService | API 21+ | Traffic capture | Android's official VPN API. Captures all device traffic through TUN interface. Requires user permission consent dialog. | HIGH |
| hev-socks5-tunnel | native lib | tun2socks alternative | V2rayNG uses this JNI library for TUN→SOCKS5 bridging. Alternative to the older tun2socks approach. Lightweight, performant. | HIGH |
| Foreground Service | API 26+ | Keep-alive | Android requires foreground service with persistent notification for long-running VPN connections. Mandatory for Android 8+. | HIGH |

### Networking & HTTP

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| dio | ^5.9.2 | HTTP client | For subscription URL fetching, latency testing, update checks. More capable than `http` package — interceptors, custom adapters, timeout control. Hiddify uses dio. | HIGH |
| http | ^1.6.0 | Simple HTTP (optional) | Lighter alternative for simple GET requests. Consider dio as single HTTP solution instead. | MEDIUM |

### QR Code & Camera

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| mobile_scanner | ^7.2.0 | QR code scanning | Spec requirement. MLKit-based, actively maintained. Hiddify uses ^7.2.0. Replaces deprecated qr_code_scanner. | HIGH |

### UI & UX

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| flutter_animate | ^4.5.2 | UI animations | Smooth connection state transitions, button animations. Declarative animation API. Hiddify uses this. | MEDIUM |
| gap | ^3.0.1 | Layout spacing | Cleaner than SizedBox for gaps. Used by Hiddify. Small utility, big DX improvement. | MEDIUM |
| flutter_svg | — | SVG rendering | If using SVG assets for logos/icons. Optional — evaluate if needed based on design assets. | LOW |

### Utilities

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| path_provider | ^2.1.5 | App directory paths | Required for Xray asset path (geoip.dat, geosite.dat) and log file storage. | HIGH |
| package_info_plus | ^9.0.1 | App version info | Display version in settings, check for updates. | HIGH |
| uuid | ^4.5.3 | UUID generation | Generate unique IDs for config entries. | HIGH |
| share_plus | ^12.0.2 | Share config links | Share server configs or export logs. | MEDIUM |
| url_launcher | ^6.3.2 | Open URLs | Open links in browser (Telegram, GitHub, etc.). | MEDIUM |
| permission_handler | ^12.0.1 | Runtime permissions | Camera (QR scan), notification permissions on Android 13+. | HIGH |
| connectivity_plus | ^7.1.0 | Network status | Detect network changes, auto-reconnect logic. | MEDIUM |
| flutter_local_notifications | ^21.0.0 | Foreground notification | VPN connection status notification. Required for Android foreground service. | HIGH |
| shared_preferences | ^2.5.5 | Simple key-value prefs | Theme preference, language selection, simple toggles. Lighter than Hive for trivial settings. | MEDIUM |

### Testing

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| flutter_test | SDK | Widget & unit testing | Built-in. Test config parsing, UI components. | HIGH |
| mockito | ^5.6.4 | Mocking | Mock platform channels, repositories, services. | HIGH |
| integration_test | SDK | Integration testing | Test VPN connect/disconnect flows. | MEDIUM |

### Code Quality

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| flutter_lints | ^6.0.0 | Lint rules | Already in project. Standard Flutter lint set. | HIGH |
| custom_lint | ^0.8.1 | Custom lint runner | Required for riverpod_lint. | HIGH |

---

## Xray-core Integration: Go-Mobile AAR Build Process

This is the most critical and non-trivial part of the stack. Verified from AndroidLibXrayLite source code and V2rayNG integration patterns.

### Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│ Flutter (Dart)                                      │
│  ┌─────────────────────────────────────────────┐    │
│  │ MethodChannel('com.arma.vpn/xray')          │    │
│  │  - startVpn(configJson)                     │    │
│  │  - stopVpn()                                │    │
│  │  - getStats() → {uplink, downlink}          │    │
│  │  - measureDelay(configJson, url) → ms       │    │
│  └──────────────┬──────────────────────────────┘    │
│                 │ Platform Channel                   │
├─────────────────┼───────────────────────────────────┤
│ Kotlin (Android)│                                    │
│  ┌──────────────┴──────────────────────────────┐    │
│  │ XrayMethodCallHandler                       │    │
│  │  - Receives Flutter commands                │    │
│  │  - Manages VpnService lifecycle             │    │
│  │  - Bridges to Go AAR via libv2ray bindings  │    │
│  └──────────────┬──────────────────────────────┘    │
│  ┌──────────────┴──────────────────────────────┐    │
│  │ ArmaVpnService extends VpnService           │    │
│  │  - Builder: MTU, routes, DNS, per-app proxy │    │
│  │  - TUN fd → passed to Go core               │    │
│  │  - Foreground notification                  │    │
│  └──────────────┬──────────────────────────────┘    │
├─────────────────┼───────────────────────────────────┤
│ Go (AAR)        │                                    │
│  ┌──────────────┴──────────────────────────────┐    │
│  │ libv2ray (AndroidLibXrayLite)               │    │
│  │  - CoreController: start/stop Xray instance │    │
│  │  - Accepts JSON config + TUN fd             │    │
│  │  - QueryStats: traffic counters             │    │
│  │  - MeasureDelay: latency testing            │    │
│  │  - InitCoreEnv: asset paths, XUDP key       │    │
│  └─────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────┐    │
│  │ geoip.dat + geosite.dat (routing assets)    │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### AAR Build Steps (Verified from AndroidLibXrayLite repo)

**Prerequisites:**
- Go 1.26+ installed
- Android SDK + NDK installed
- JDK installed
- `gomobile` tool installed

```bash
# 1. Install gomobile
go install golang.org/x/mobile/cmd/gomobile@latest
go install golang.org/x/mobile/cmd/gobind@latest

# 2. Initialize gomobile (downloads NDK toolchains)
gomobile init

# 3. Clone AndroidLibXrayLite
git clone https://github.com/2dust/AndroidLibXrayLite.git
cd AndroidLibXrayLite

# 4. Download dependencies
go mod tidy -v

# 5. Build AAR (outputs libv2ray.aar and libv2ray-sources.jar)
gomobile bind -v -androidapi 21 -ldflags='-s -w' ./

# 6. Copy AAR to Flutter project
cp libv2ray.aar /path/to/flutter_project/android/app/libs/
```

**Build output:** `libv2ray.aar` (~30-50MB depending on architectures)

**Target architectures:** arm64-v8a, armeabi-v7a, x86_64, x86

### Go-to-Kotlin API Surface (from libv2ray_main.go)

The AAR exposes these key APIs (verified from source):

```kotlin
import libv2ray.CoreController
import libv2ray.CoreCallbackHandler
import libv2ray.Libv2ray

// Initialize environment (call once at app start)
Libv2ray.initCoreEnv(assetPath: String, xudpKey: String)

// Create controller with callback handler
val controller = Libv2ray.newCoreController(callbackHandler)

// Start Xray with JSON config and TUN file descriptor
controller.startLoop(configJson: String, tunFd: Int)  // tunFd=0 for proxy-only mode

// Stop Xray
controller.stopLoop()

// Query traffic stats (returns bytes, resets counter)
controller.queryStats(tag: String, direction: String): Long  // direction: "uplink" | "downlink"

// Measure latency
controller.measureDelay(url: String): Long  // returns milliseconds

// Check if running
controller.isRunning: Boolean

// Static: measure delay without running instance
Libv2ray.measureOutboundDelay(configJson: String, url: String): Long

// Version check
Libv2ray.checkVersionX(): String
```

### Kotlin VpnService Pattern (from V2rayNG, adapted for Flutter)

```kotlin
// Key implementation pattern from V2rayNG v2.0.18
class ArmaVpnService : VpnService() {
    // 1. Builder configuration
    private fun configureVpn(): ParcelFileDescriptor {
        val builder = Builder()
        builder.setMtu(9000)  // V2rayNG default
        builder.addAddress("26.26.26.1", 30)  // Private TUN IP
        builder.addRoute("0.0.0.0", 0)  // Route all traffic
        builder.addDnsServer("1.1.1.1")
        builder.setSession("Arma VPN")
        // Per-app: builder.addDisallowedApplication(packageName) to exclude self
        return builder.establish()!!
    }

    // 2. Pass TUN fd to Go core
    private fun startCore(config: String) {
        val fd = configureVpn()
        coreController.startLoop(config, fd.fd)
    }
}
```

### Required Android Manifest Permissions

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### Geo-Data Assets

Xray-core requires routing data files:
- `geoip.dat` (~18MB) — IP geolocation database for routing rules
- `geosite.dat` (~8.6MB) — Domain categorization database

**Source:** https://github.com/Loyalsoldier/v2ray-rules-dat (enhanced version, used by V2rayNG)

These must be bundled in `android/app/src/main/assets/` or downloaded on first launch.

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| State Management | Riverpod 3.x | BLoC | Spec requirement (Riverpod). Less boilerplate, better testability. BLoC's stream-based approach adds unnecessary complexity for this app's state shape. |
| Local Storage | hive_ce | Original Hive | Original hive abandoned since June 2022. hive_ce is actively maintained, API-compatible. |
| Local Storage | hive_ce | Isar | Isar last published April 2023 — also appears abandoned. Over-engineered for config/subscription storage. hive_ce is simpler and sufficient. |
| Local Storage | hive_ce | Drift (SQLite) | Drift is great for relational data but overkill here. Config data is key-value/document-shaped, not relational. Hive is faster for this use case. |
| Local Storage | hive_ce | shared_preferences | shared_preferences is too simple for structured config objects. Use it only for trivial preferences (theme, language). |
| HTTP Client | dio | http package | dio provides interceptors (for custom User-Agent on subscription fetches), better error handling, request cancellation. Worth the dependency for subscription management. |
| QR Scanner | mobile_scanner | qr_code_scanner | qr_code_scanner is deprecated. mobile_scanner uses MLKit, is actively maintained, and is used by Hiddify. |
| Navigation | go_router | auto_route | Spec requirement (go_router). go_router is official Flutter team package with better maintenance guarantees. |
| Core Engine | Xray-core via Go-Mobile AAR | sing-box | Xray-core has wider protocol support (VLESS Reality, XTLS). sing-box is Hiddify's choice but requires different config format. AndroidLibXrayLite provides proven AAR build path. |
| Core Engine | AndroidLibXrayLite | Custom Go FFI | AndroidLibXrayLite is battle-tested in V2rayNG (53k stars). Custom FFI bindings would be reinventing the wheel with high risk. |
| TUN Bridge | Core TUN fd pass-through | External tun2socks binary | V2rayNG's modern approach passes TUN fd directly to Go core or uses hev-socks5-tunnel JNI. Avoids spawning separate processes. Simpler, more reliable. |

---

## minSdk Decision

| Option | Rationale | Recommendation |
|--------|-----------|----------------|
| API 21 (Android 5.0) | Spec says API 21+. AndroidLibXrayLite compiles with `-androidapi 21`. Maximum device coverage. | **NOT recommended** — too old |
| API 24 (Android 7.0) | V2rayNG uses API 24 as minimum. Covers 99%+ of active Android devices in 2026. Enables Java 8+ features natively. | **Recommended** |
| API 26 (Android 8.0) | Would simplify foreground service code but excludes some older devices in target regions. | Acceptable fallback |

**Recommendation: API 24.** Target regions (Iran, China, Russia) have many older devices. API 24 gives near-universal coverage while keeping code modern. V2rayNG made the same choice.

---

## Installation

```bash
# Core dependencies
flutter pub add flutter_riverpod riverpod_annotation go_router \
  hive_ce hive_ce_flutter dio mobile_scanner \
  freezed_annotation json_annotation \
  path_provider package_info_plus uuid share_plus url_launcher \
  permission_handler connectivity_plus \
  flutter_local_notifications shared_preferences \
  flutter_animate gap equatable

# Dev dependencies
flutter pub add --dev riverpod_generator riverpod_lint custom_lint \
  freezed json_serializable hive_ce_generator \
  build_runner mockito

# Code generation (run after defining models)
dart run build_runner build --delete-conflicting-outputs
```

### Android-specific setup

```kotlin
// android/app/build.gradle.kts additions:
android {
    defaultConfig {
        minSdk = 24
        // ... existing config
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("libs")  // For AAR native libs
        }
    }
}

dependencies {
    // Include the Xray AAR
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
}
```

---

## Version Pinning Strategy

Pin major versions with caret (`^`) to allow patch/minor updates while preventing breaking changes. All versions verified against pub.dev as of 2026-04-05.

**Do NOT use:**
- `any` version constraints
- Git dependencies for core packages
- Pre-release versions for production dependencies

---

## Sources

- pub.dev API — package versions verified directly (all HIGH confidence)
- [2dust/AndroidLibXrayLite](https://github.com/2dust/AndroidLibXrayLite) — Go-Mobile AAR source, go.mod, build instructions (cloned and verified)
- [2dust/v2rayNG](https://github.com/2dust/v2rayNG) — Reference VpnService implementation, Kotlin bridge patterns (cloned and verified, v2.0.18)
- [hiddify/hiddify-app](https://github.com/hiddify/hiddify-app) — Flutter VPN client reference, pubspec.yaml dependencies (verified via GitHub raw)
- [XTLS/Xray-core](https://github.com/XTLS/Xray-core) — Xray-core releases (v26.3.27 verified via GitHub API)
- [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat) — Geo-data assets (referenced by V2rayNG)
