# Technology Stack

**Analysis Date:** 2025-07-14

## Project Status

**Greenfield project.** The codebase is at the Flutter default counter-app template stage. No custom application code has been written yet. The spec document `happ_clone_specs.md` defines the planned architecture and dependencies. This document captures both the **current** state and clearly marks **planned** additions.

## Languages

**Primary:**
- Dart (SDK `^3.11.4`, resolved `>=3.11.4 <4.0.0`) — All application logic in `lib/`

**Secondary (platform runners — auto-generated, not yet customized):**
- Kotlin `2.2.20` — Android native layer (`android/app/src/main/kotlin/`)
- Swift — iOS/macOS native layer (`ios/Runner/`, `macos/Runner/`)
- C++ — Linux/Windows native runners (`linux/runner/`, `windows/runner/`)

## Runtime

**Environment:**
- Flutter SDK (stable channel, revision `db50e20168db8fee486b9abf32fc912de3bc5b6a`)
- Flutter `>=3.18.0-18.0.pre.54`
- Dart VM `>=3.11.4 <4.0.0`

**Package Manager:**
- `pub` (via `flutter pub`)
- Lockfile: `pubspec.lock` — present and committed

## Frameworks

**Core:**
- Flutter SDK — Cross-platform UI framework
- Material Design — UI component system (`uses-material-design: true` in `pubspec.yaml`)

**Testing:**
- `flutter_test` (SDK) — Widget and unit testing

**Build/Dev:**
- Flutter CLI — Build, run, hot-reload
- Gradle `8.11.1` — Android build system (`android/settings.gradle.kts`)
- Android Gradle Plugin (via `com.android.application`)
- Xcode / CocoaPods — iOS/macOS builds
- CMake — Linux/Windows builds

**Linting:**
- `flutter_lints` `6.0.0` — Lint rules (wraps `lints` `6.1.0`)
- Config: `analysis_options.yaml` (includes `package:flutter_lints/flutter.yaml`)

## Key Dependencies

### Current (in `pubspec.yaml`)

**Direct main:**
- `flutter` (SDK) — Framework core
- `cupertino_icons` `^1.0.8` (resolved `1.0.9`) — iOS-style icons

**Direct dev:**
- `flutter_test` (SDK) — Test framework
- `flutter_lints` `^6.0.0` (resolved `6.0.0`) — Static analysis rules

**Transitive (notable):**
- `meta` `1.17.0` — Annotations
- `collection` `1.19.1` — Collection utilities
- `vector_math` `2.2.0` — Math for rendering
- `material_color_utilities` `0.13.0` — Color system
- `leak_tracker` `11.0.2` — Memory leak detection (dev)

### Planned (from `happ_clone_specs.md` — NOT yet added)

These packages are specified in the project spec and will need to be added to `pubspec.yaml`:

- **`flutter_riverpod`** — State management (spec recommends Riverpod)
- **`go_router`** — Declarative routing
- **`hive`** or **`isar`** — Local NoSQL storage for configs, subscriptions, routing rules
- **`mobile_scanner`** — QR code scanning for importing proxy configs
- **Xray-core bindings** — Native VPN engine (via FFI or Android Platform Channels)
- **`tun2socks`** — Traffic tunneling (native, Android)

## Configuration

**Project Config:**
- `pubspec.yaml` — Dependencies, assets, app metadata (version `1.0.0+1`)
- `analysis_options.yaml` — Dart analyzer and lint rules
- `.metadata` — Flutter tool metadata (project type: `app`)

**Android Config:**
- `android/build.gradle.kts` — Root Gradle config
- `android/app/build.gradle.kts` — App-level build config
- `android/gradle.properties` — JVM args (`-Xmx8G`), AndroidX enabled
- `android/settings.gradle.kts` — Plugin management, Kotlin/AGP versions
- `android/app/src/main/AndroidManifest.xml` — App manifest
- Application ID: `com.example.arma_proxy_vpn_client` (placeholder — needs changing)
- Namespace: `com.example.arma_proxy_vpn_client`
- Java/Kotlin target: Java 17
- compileSdk / minSdk / targetSdk: Delegated to `flutter.compileSdkVersion` etc.
- **No VpnService permission declared yet** — will be required for proxy/VPN functionality

**iOS Config:**
- `ios/Runner/AppDelegate.swift` — Standard Flutter app delegate
- `ios/Runner.xcodeproj/` — Xcode project

**Environment:**
- No `.env` files detected
- No environment variable configuration present
- `android/local.properties` — Local SDK paths (gitignored)

**Build:**
- `android/gradlew` — Gradle wrapper
- Release signing: Currently uses debug keys (TODO in `android/app/build.gradle.kts`)

## Platform Targets

**Scaffolded (all from template, no customization):**
- Android (`android/`)
- iOS (`ios/`)
- macOS (`macos/`)
- Linux (`linux/`)
- Windows (`windows/`)

**Primary targets (per spec):**
- Android — Mobile app (main target)
- Web — Promotional/documentation site (planned)

**Development:**
- macOS (host for Flutter development)
- Requires: Flutter SDK, Android SDK, Xcode (for iOS)

**Production:**
- Android: APK / Play Store distribution
- No CI/CD pipeline configured yet

## Version Constraints

| Component | Version |
|-----------|---------|
| Dart SDK | `^3.11.4` |
| Flutter SDK | `>=3.18.0-18.0.pre.54` |
| Kotlin | `2.2.20` |
| Android Gradle Plugin | `8.11.1` |
| Java compatibility | `17` |
| Gradle JVM | `-Xmx8G -XX:MaxMetaspaceSize=4G` |

---

*Stack analysis: 2025-07-14*
