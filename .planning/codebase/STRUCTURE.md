# Codebase Structure

**Analysis Date:** 2025-07-15

## Directory Layout

```
arma_proxy_vpn_client/
├── lib/                    # Dart/Flutter application source (ONLY main.dart exists)
│   └── main.dart           # App entry point — default counter template
├── test/                   # Flutter test files
│   └── widget_test.dart    # Default counter widget test
├── android/                # Android platform shell
│   └── app/
│       ├── build.gradle.kts
│       └── src/main/
│           ├── AndroidManifest.xml
│           └── kotlin/.../MainActivity.kt
├── ios/                    # iOS platform shell
│   └── Runner/
│       ├── AppDelegate.swift
│       ├── SceneDelegate.swift
│       └── Info.plist
├── macos/                  # macOS platform shell
│   └── Runner/
│       └── AppDelegate.swift
├── linux/                  # Linux platform shell
│   └── runner/
│       └── main.cc
├── windows/                # Windows platform shell
│   └── runner/
│       └── main.cpp
├── pubspec.yaml            # Dart dependencies and project metadata
├── pubspec.lock            # Locked dependency versions
├── analysis_options.yaml   # Dart analyzer / linter configuration
├── happ_clone_specs.md     # Full project specification document
└── .planning/              # GSD planning documents
    └── codebase/           # Codebase analysis docs (this file)
```

## Directory Purposes

**`lib/`:**
- Purpose: All Dart/Flutter application source code
- Contains: Currently only `main.dart` (default counter app)
- Key files: `lib/main.dart`
- **This is where ALL new Dart code goes.** Currently flat — needs subdirectory structure.

**`test/`:**
- Purpose: Flutter widget and unit tests
- Contains: `widget_test.dart` (default counter test)
- Key files: `test/widget_test.dart`

**`android/`:**
- Purpose: Android platform-specific code, Gradle build config, manifest
- Contains: Kotlin source, build scripts, resources, manifest
- Key files: `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/MainActivity.kt`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`

**`ios/`:**
- Purpose: iOS platform-specific code, Xcode project files
- Contains: Swift source, storyboards, assets, Info.plist
- Key files: `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`

**`macos/`:**
- Purpose: macOS desktop platform shell
- Contains: Swift source, Xcode project, entitlements
- Key files: `macos/Runner/AppDelegate.swift`

**`linux/`:**
- Purpose: Linux desktop platform shell
- Contains: C++ source, CMake build files
- Key files: `linux/runner/main.cc`

**`windows/`:**
- Purpose: Windows desktop platform shell
- Contains: C++ source, CMake build files, resources
- Key files: `windows/runner/main.cpp`

## Key File Locations

**Entry Points:**
- `lib/main.dart`: Flutter app entry point — `main()` → `runApp(MyApp())`
- `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/MainActivity.kt`: Android activity
- `ios/Runner/AppDelegate.swift`: iOS app delegate

**Configuration:**
- `pubspec.yaml`: Dependencies, SDK version, assets, fonts
- `analysis_options.yaml`: Linter rules (uses `package:flutter_lints/flutter.yaml`)
- `android/app/build.gradle.kts`: Android build config (applicationId: `com.example.arma_proxy_vpn_client`, Java 17)
- `android/app/src/main/AndroidManifest.xml`: Android permissions and activity declarations

**Specification:**
- `happ_clone_specs.md`: Complete project specification — architecture, screens, protocols, development phases

**Testing:**
- `test/widget_test.dart`: Default counter widget smoke test

## Naming Conventions

**Files (Dart):**
- snake_case: `main.dart`, `widget_test.dart` (standard Dart convention)

**Directories:**
- snake_case for Dart/Flutter: `lib/`, `test/`
- Platform conventions in platform dirs: camelCase for Kotlin, PascalCase for Swift files

**Classes:**
- PascalCase: `MyApp`, `MyHomePage`, `_MyHomePageState`

**Functions/Methods:**
- camelCase: `_incrementCounter`, `createState`

**Variables:**
- camelCase with underscore prefix for private: `_counter`

## Where to Add New Code

**Based on the spec's Clean Architecture + MVVM plan, new code should follow this structure:**

**New Feature (e.g., Dashboard screen):**
- ViewModel/Provider: `lib/presentation/providers/dashboard_provider.dart`
- Screen widget: `lib/presentation/screens/dashboard_screen.dart`
- Screen-specific widgets: `lib/presentation/widgets/dashboard/`
- Use case: `lib/domain/usecases/connect_vpn.dart`
- Repository interface: `lib/domain/repositories/vpn_repository.dart`
- Repository implementation: `lib/data/repositories/vpn_repository_impl.dart`
- Data model: `lib/data/models/server_config_model.dart`
- Domain entity: `lib/domain/entities/server_config.dart`
- Tests: `test/presentation/`, `test/domain/`, `test/data/`

**Recommended `lib/` directory structure (per spec):**
```
lib/
├── main.dart                      # Entry point
├── app.dart                       # MaterialApp / Router setup
├── core/                          # Shared utilities, constants, theme
│   ├── theme/                     # Light/Dark theme definitions
│   ├── constants/                 # App-wide constants
│   ├── utils/                     # Shared helpers
│   └── router/                    # go_router configuration
├── domain/                        # Business logic layer
│   ├── entities/                  # Core business objects
│   ├── repositories/              # Repository interfaces (abstract)
│   └── usecases/                  # Application use cases
├── data/                          # Data access layer
│   ├── models/                    # Data transfer objects / serialization
│   ├── repositories/              # Repository implementations
│   ├── datasources/               # Local (Hive) and remote data sources
│   └── services/                  # Platform channel services (VPN engine)
└── presentation/                  # UI layer
    ├── providers/                 # Riverpod providers / ViewModels
    ├── screens/                   # Full-page screen widgets
    │   ├── dashboard/
    │   ├── nodes/
    │   ├── routing/
    │   └── settings/
    └── widgets/                   # Reusable UI components
```

**New Platform Channel (Android VpnService):**
- Kotlin: `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/`
- Add new files: `VpnService.kt`, `XrayEngine.kt`, `PlatformChannelHandler.kt`
- Dart interface: `lib/data/services/vpn_platform_service.dart`

**Utilities:**
- Shared helpers: `lib/core/utils/`
- Protocol parsers: `lib/data/parsers/` or `lib/core/utils/parsers/`

**New Tests:**
- Unit tests: `test/domain/usecases/`, `test/data/repositories/`
- Widget tests: `test/presentation/screens/`, `test/presentation/widgets/`
- Integration tests: `integration_test/` (standard Flutter convention, directory does not exist yet)

## Special Directories

**`android/`, `ios/`, `macos/`, `linux/`, `windows/`:**
- Purpose: Platform-specific native code and build configuration
- Generated: Partially (plugin registrants are auto-generated; project structure is scaffolded)
- Committed: Yes
- Modify when: Adding platform channels, permissions, native dependencies, or build config changes

**`.dart_tool/`:**
- Purpose: Dart tooling cache (package config, build artifacts)
- Generated: Yes (by `flutter pub get`)
- Committed: No (in `.gitignore`)

**`.planning/`:**
- Purpose: GSD planning and analysis documents
- Generated: No (manually created)
- Committed: Yes

**`build/`:**
- Purpose: Compiled output artifacts
- Generated: Yes (by `flutter build`)
- Committed: No (in `.gitignore`)

---

*Structure analysis: 2025-07-15*
