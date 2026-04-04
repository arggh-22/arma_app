<!-- GSD:project-start source:PROJECT.md -->
## Project

**Arma Proxy & VPN Client**

A privacy-first proxy and VPN client app for Android that lets users connect to their own proxy servers with a single tap. Built on Xray-core, it supports VLESS (including Reality/XTLS), VMess, Trojan, Shadowsocks, Socks/HTTP, and Hysteria2 protocols. Designed for users in censored regions who need reliable, easy access to the open internet.

**Core Value:** Users can import a server configuration and connect in one tap — it just works, every time, even in hostile network environments.

### Constraints

- **Tech stack**: Flutter (Dart) with Clean Architecture + MVVM, Riverpod for state management, Hive for local storage, go_router for navigation
- **Platform**: Android-only for v1 (API 21+ / Android 5.0+)
- **Engine**: Xray-core compiled via Go-Mobile, integrated through Kotlin platform channels and Android VpnService
- **No backend**: All data stored locally on device; no server-side components
- **Privacy**: No analytics, no tracking, no data collection — privacy-first by design
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Project Status
## Languages
- Dart (SDK `^3.11.4`, resolved `>=3.11.4 <4.0.0`) — All application logic in `lib/`
- Kotlin `2.2.20` — Android native layer (`android/app/src/main/kotlin/`)
- Swift — iOS/macOS native layer (`ios/Runner/`, `macos/Runner/`)
- C++ — Linux/Windows native runners (`linux/runner/`, `windows/runner/`)
## Runtime
- Flutter SDK (stable channel, revision `db50e20168db8fee486b9abf32fc912de3bc5b6a`)
- Flutter `>=3.18.0-18.0.pre.54`
- Dart VM `>=3.11.4 <4.0.0`
- `pub` (via `flutter pub`)
- Lockfile: `pubspec.lock` — present and committed
## Frameworks
- Flutter SDK — Cross-platform UI framework
- Material Design — UI component system (`uses-material-design: true` in `pubspec.yaml`)
- `flutter_test` (SDK) — Widget and unit testing
- Flutter CLI — Build, run, hot-reload
- Gradle `8.11.1` — Android build system (`android/settings.gradle.kts`)
- Android Gradle Plugin (via `com.android.application`)
- Xcode / CocoaPods — iOS/macOS builds
- CMake — Linux/Windows builds
- `flutter_lints` `6.0.0` — Lint rules (wraps `lints` `6.1.0`)
- Config: `analysis_options.yaml` (includes `package:flutter_lints/flutter.yaml`)
## Key Dependencies
### Current (in `pubspec.yaml`)
- `flutter` (SDK) — Framework core
- `cupertino_icons` `^1.0.8` (resolved `1.0.9`) — iOS-style icons
- `flutter_test` (SDK) — Test framework
- `flutter_lints` `^6.0.0` (resolved `6.0.0`) — Static analysis rules
- `meta` `1.17.0` — Annotations
- `collection` `1.19.1` — Collection utilities
- `vector_math` `2.2.0` — Math for rendering
- `material_color_utilities` `0.13.0` — Color system
- `leak_tracker` `11.0.2` — Memory leak detection (dev)
### Planned (from `happ_clone_specs.md` — NOT yet added)
- **`flutter_riverpod`** — State management (spec recommends Riverpod)
- **`go_router`** — Declarative routing
- **`hive`** or **`isar`** — Local NoSQL storage for configs, subscriptions, routing rules
- **`mobile_scanner`** — QR code scanning for importing proxy configs
- **Xray-core bindings** — Native VPN engine (via FFI or Android Platform Channels)
- **`tun2socks`** — Traffic tunneling (native, Android)
## Configuration
- `pubspec.yaml` — Dependencies, assets, app metadata (version `1.0.0+1`)
- `analysis_options.yaml` — Dart analyzer and lint rules
- `.metadata` — Flutter tool metadata (project type: `app`)
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
- `ios/Runner/AppDelegate.swift` — Standard Flutter app delegate
- `ios/Runner.xcodeproj/` — Xcode project
- No `.env` files detected
- No environment variable configuration present
- `android/local.properties` — Local SDK paths (gitignored)
- `android/gradlew` — Gradle wrapper
- Release signing: Currently uses debug keys (TODO in `android/app/build.gradle.kts`)
## Platform Targets
- Android (`android/`)
- iOS (`ios/`)
- macOS (`macos/`)
- Linux (`linux/`)
- Windows (`windows/`)
- Android — Mobile app (main target)
- Web — Promotional/documentation site (planned)
- macOS (host for Flutter development)
- Requires: Flutter SDK, Android SDK, Xcode (for iOS)
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
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Project Status
## Naming Patterns
- Use `snake_case.dart` for all Dart files (Flutter/Dart standard)
- Example: `lib/main.dart`
- Use `PascalCase` for classes, enums, typedefs, and extensions
- Widget classes: `MyHomePage`, `MyApp`
- State classes: `_MyHomePageState` (prefixed with underscore for private)
- Use `camelCase` for functions, methods, and named parameters
- Private methods prefixed with underscore: `_incrementCounter()`
- Example from `lib/main.dart`: `void _incrementCounter()`, `Widget build(BuildContext context)`
- Use `camelCase` for local variables and instance fields
- Private fields prefixed with underscore: `int _counter = 0`
- Constants use `camelCase` (Dart convention, not SCREAMING_SNAKE): `const MyApp({super.key})`
- Use `PascalCase` for type names
- Generic type parameters: single uppercase letter (`State<MyHomePage>`)
## Code Style
- Tool: `dart format` (built into Dart SDK)
- Line length: 80 characters (Dart default)
- Trailing commas on widget trees for clean diffs and auto-formatting
- Run: `dart format lib/ test/`
- Tool: `flutter_lints` v6.0.0 (via `package:flutter_lints/flutter.yaml`)
- Config: `analysis_options.yaml`
- No custom lint rules enabled or disabled — uses the default recommended set
- Run: `flutter analyze`
- `prefer_const_constructors` — use `const` wherever possible
- `avoid_print` — enabled (use proper logging, not `print()`)
- `prefer_final_fields` — mark fields `final` when not reassigned
- `use_key_in_widget_constructors` — always accept a `Key` parameter in widgets
- `sized_box_for_whitespace` — use `SizedBox` instead of `Container` for spacing
- `prefer_const_literals_to_create_immutables` — use `const` for immutable collection literals
## Widget Patterns
- Always use `const` constructors for stateless widgets and immutable widget instances
- Pattern from `lib/main.dart`:
- Use Dart 3 `super.key` syntax instead of `Key? key` + `super(key: key)`
- Separate widget class from state class
- Widget holds configuration (`final` fields), State holds mutable state
- Pattern from `lib/main.dart`:
- The codebase uses Dart 3 shorthand for enum/static member access:
## Import Organization
- Use `package:arma_proxy_vpn_client/` for cross-package imports
- Use relative imports within the same feature/directory
## Error Handling
- Use `try-catch` for async operations (network, file I/O)
- Use custom exception classes for domain errors
- Avoid catching generic `Exception` — catch specific types
- For Riverpod: use `AsyncValue` pattern for loading/error/data states
## Logging
- Do NOT use `print()` — the linter enforces `avoid_print`
- Use `debugPrint()` for development-only logging
- For production logging, use the `logging` package or a custom logger
## Comments
- Inline comments explaining Flutter framework behavior (tutorial-style)
- `// This widget is the root of your application.`
- `// TRY THIS:` comments are template boilerplate — remove when building real features
- Use `///` doc comments for public APIs (classes, methods, properties)
- Use `//` for implementation notes
- Remove all default template comments when replacing boilerplate
## Function Design
## Module Design
- Each feature directory should have a barrel file (e.g., `features/dashboard/dashboard.dart`)
- Export only the public API of each module
- Not yet used (single-file project)
- Prescribe: create barrel files per feature directory as the project grows
## Dart Version Features
- Pattern matching and switch expressions
- Records and destructuring
- Sealed classes for state modeling
- `super.key` shorthand in constructors
- Enhanced enums
- Static member shorthand (`.center`, `.fromSeed()`)
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- **Pattern:** Clean Architecture + MVVM
- **State Management:** Riverpod
- **Routing:** go_router
- **Local Storage:** Hive or Isar
- **VPN Engine:** Xray-core via Android Platform Channels / `VpnService`
- Single-file Dart application (`lib/main.dart`) with no separation of concerns
- No domain, data, or presentation layers exist
- No external dependencies beyond Flutter SDK defaults (`cupertino_icons`, `flutter_lints`)
- Multi-platform shell directories exist (Android, iOS, macOS, Linux, Windows) but contain only default boilerplate
## Current State: Single-File App
- Contains `main()` entry point calling `runApp(const MyApp())`
- `MyApp` — root `StatelessWidget` returning a `MaterialApp` with default purple theme
- `MyHomePage` — `StatefulWidget` with a counter that increments on FAB press
- Uses raw `setState()` for state management (no Riverpod, no BLoC, no provider)
## Planned Layers (from `happ_clone_specs.md`)
- Purpose: UI screens and ViewModels
- Planned screens: Dashboard, Configurations/Nodes, Routing & Rules, Settings
- State: Riverpod providers
- Purpose: Business logic, use cases, entities
- Key entities: Server configurations (VLESS, VMess, Trojan, Shadowsocks, Socks/HTTP, Hysteria2)
- Use cases: Connect/disconnect, parse subscription links, latency testing, traffic monitoring
- Purpose: Repositories, data sources, models
- Local: Hive/Isar for configuration persistence
- Remote: Subscription URL fetching, base64 decoding of config links
- Platform: Android platform channels to Xray-core native engine
- Purpose: Native VPN engine integration
- Location: `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/`
- Contains: `MainActivity.kt` (currently default FlutterActivity, no platform channels)
- Planned: `VpnService` implementation, Xray-core wrapper, `tun2socks` integration
## Data Flow
- Currently: Raw `setState()` in `_MyHomePageState`
- Planned: Riverpod for all reactive state
## Key Abstractions
- Purpose: Represents a proxy server with protocol, address, port, UUID, TLS settings, network type
- Pattern: Dart data class / freezed model
- Purpose: Groups server configurations from a single subscription URL
- Pattern: Collection with metadata (URL, update timestamp, User-Agent)
- Purpose: Abstract platform-specific VPN service behind a Dart interface
- Pattern: Platform channel abstraction
- Purpose: Traffic routing rules (Proxy, Direct, Block) by domain/IP patterns
- Pattern: Rule sets with domain suffix / geoip matching
## Entry Points
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities: Currently renders counter demo; will become app initialization with Riverpod scope, router setup, and theme configuration
- Location: `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/MainActivity.kt`
- Current: Default `FlutterActivity()` — no custom logic
- Planned: Platform channel registration, VpnService lifecycle management
- Location: `ios/Runner/AppDelegate.swift`
- Current: Default `FlutterAppDelegate` — no custom logic
- Location: `macos/Runner/AppDelegate.swift`
- Current: Default boilerplate
## Error Handling
- Connection errors from VPN engine → surface in UI
- Subscription fetch failures → user notification
- Configuration parse errors → skip invalid entries, report to user
## Cross-Cutting Concerns
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.github/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
