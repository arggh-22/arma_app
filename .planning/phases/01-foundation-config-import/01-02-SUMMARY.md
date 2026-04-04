---
phase: 01-foundation-config-import
plan: 02
subsystem: data-layer-l10n
tags: [freezed, hive, riverpod, l10n, arb, clean-architecture, data-layer]
dependency_graph:
  requires: [01-01]
  provides: [ServerConfig entity, Hive persistence, Riverpod providers, AppLocalizations, error classes]
  affects: [lib/main.dart, lib/app.dart]
tech_stack:
  added: [freezed, hive_ce, shared_preferences, riverpod code generation]
  patterns: [sealed class hierarchy, Hive TypeAdapter with index gaps, domain↔model mapper, provider override pattern]
key_files:
  created:
    - lib/core/l10n/app_en.arb
    - lib/core/l10n/app_fa.arb
    - lib/core/l10n/app_ru.arb
    - lib/core/l10n/app_zh.arb
    - lib/core/error/failures.dart
    - lib/core/error/exceptions.dart
    - lib/features/server/domain/entities/server_config.dart
    - lib/features/server/data/models/server_config_model.dart
    - lib/features/server/domain/repositories/server_repository.dart
    - lib/features/server/data/datasources/server_local_datasource.dart
    - lib/features/server/data/repositories/server_repository_impl.dart
    - lib/features/settings/data/datasources/settings_local_datasource.dart
    - lib/features/settings/presentation/providers/theme_provider.dart
    - lib/features/settings/presentation/providers/locale_provider.dart
    - lib/features/server/presentation/providers/server_list_provider.dart
    - lib/features/server/presentation/providers/active_server_provider.dart
    - test/features/server/domain/entities/server_config_test.dart
    - test/features/server/data/models/server_config_model_test.dart
  modified:
    - lib/main.dart
    - lib/app.dart
decisions:
  - "Freezed 3.x requires `abstract class` keyword for mixin-based code generation"
  - "Riverpod generator 4.x uses `Ref` (not scoped Ref types like `SharedPreferencesRef`) for functional providers"
  - "Provider names follow shortened convention: `themeProvider` not `themeNotifierProvider`"
  - "ServerRepositoryImpl validates Hive records (protocolIndex range, empty required fields, port range) per T-01-02-01"
metrics:
  duration: 11min
  completed: "2026-04-04T23:47:00Z"
  tasks: 3
  files: 28
---

# Phase 01 Plan 02: Domain Model, Data Layer & Localization Summary

Freezed ServerConfig entity with all 5 protocol fields, Hive persistence with schema-safe index gaps, Riverpod providers for server list / active server / theme / locale, and 4-language ARB localization (EN/FA-RTL/RU/ZH) wired into MaterialApp.

## What Was Built

### Task 1: Localization ARB Files and Error Classes
- Created 4 ARB files (EN, FA, RU, ZH) with 40+ UI strings each covering dashboard, server list, import, settings, routing, and error messages
- Persian (FA) enables RTL layout automatically via Flutter's localization system
- All ARB files include parameterized strings (`{serverName}`, `{language}`, `{speed}`)
- Generated `AppLocalizations` with delegates for all 4 locales
- Sealed `Failure` hierarchy: `ParseFailure`, `StorageFailure`, `ClipboardFailure`
- Exception classes: `ParseException`, `StorageException`

### Task 2: ServerConfig Domain Entity and Hive Data Layer (TDD)
- **RED:** 9 failing tests covering entity creation, defaults, copyWith, JSON round-trip, model mapping, HiveField index gaps
- **GREEN:** Implemented `@freezed abstract class ServerConfig` with 28 fields covering all 5 protocols (VLESS/VMess/Trojan/Shadowsocks/Hysteria2)
- `ServerConfigModel` with `@HiveType(typeId: 0)` and explicit field indices 0-44 with intentional gaps at 3-4, 7-9, 16-19, 26-29, 36-39 for future schema evolution
- `ServerConfigModelMapper` extension with `toDomain()` and `fromDomain()` methods
- `ServerRepository` abstract interface with CRUD operations
- `ServerLocalDatasource` wrapping Hive box with error handling
- `ServerRepositoryImpl` with data validation per threat model T-01-02-01 (validates protocolIndex range, non-empty required fields, port range — skips corrupted records with debugPrint warning)

### Task 3: Settings Datasource, Providers, and App Wiring
- `SettingsLocalDatasource` for theme mode, locale, and active server ID via SharedPreferences
- `ThemeNotifier` provider: reads/writes theme mode (system/light/dark) to SharedPreferences
- `LocaleNotifier` provider: reads/writes locale code with `supportedLocales` and `localeDisplayNames`
- `ServerListNotifier` provider: reactive list from Hive with `addServer`/`deleteServer`
- `ActiveServerNotifier` provider: tracks selected server, persists ID in SharedPreferences
- Updated `main.dart`: Hive init, adapter registration, box opening, SharedPreferences loading, provider override
- Updated `app.dart`: theme/locale providers wired to MaterialApp.router, AppLocalizations delegates and supportedLocales

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Freezed 3.x abstract class requirement**
- **Found during:** Task 2 GREEN phase
- **Issue:** Freezed 3.2.5 generates `mixin _$ServerConfig` with abstract getters, requiring the class to be abstract
- **Fix:** Changed `@freezed class ServerConfig` to `@freezed abstract class ServerConfig`
- **Files modified:** lib/features/server/domain/entities/server_config.dart

**2. [Rule 3 - Blocking] Riverpod generator 4.x provider naming and Ref types**
- **Found during:** Task 3
- **Issue:** Riverpod generator 4.x generates `themeProvider` (not `themeNotifierProvider`) and uses plain `Ref` (not `SharedPreferencesRef`)
- **Fix:** Updated provider references in app.dart, removed scoped Ref types, cleaned unnecessary imports
- **Files modified:** lib/app.dart, lib/features/settings/presentation/providers/theme_provider.dart, lib/features/server/presentation/providers/server_list_provider.dart, lib/features/server/presentation/providers/active_server_provider.dart

**3. [Rule 3 - Blocking] Dart SDK version mismatch between standalone dart and Flutter-embedded dart**
- **Found during:** Task 2
- **Issue:** Standalone `dart` is 3.10.7 but project requires ^3.11.4 (Flutter SDK bundles 3.11.4)
- **Fix:** Used `flutter pub run build_runner` instead of `dart run build_runner`
- **Files modified:** None (tooling change only)

## Verification Results

- ✅ `flutter pub run build_runner build --delete-conflicting-outputs` succeeds (0 errors)
- ✅ `flutter gen-l10n` generates AppLocalizations for 4 locales
- ✅ `flutter analyze lib/` — zero issues
- ✅ All 7 generated `.g.dart` and `.freezed.dart` files exist
- ✅ All 9 TDD tests pass
- ✅ ServerConfig entity has all required protocol fields
- ✅ Hive model has field index gaps at 3-4, 7-9, 16-19, 26-29, 36-39

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | dc4e18d | feat(01-02): add 4-language ARB localization and error class hierarchy |
| 2 (RED) | 70267c4 | test(01-02): add failing tests for ServerConfig entity and Hive model |
| 2 (GREEN) | 11f872d | feat(01-02): implement ServerConfig entity, Hive model, repository and datasource |
| 3 | ae4abd0 | feat(01-02): wire providers, settings persistence, and l10n into app |

## Self-Check: PASSED

All 26 files verified present. All 4 commits verified in git log.
