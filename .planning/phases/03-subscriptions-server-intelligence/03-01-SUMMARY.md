---
phase: 03-subscriptions-server-intelligence
plan: 01
subsystem: data
tags: [hive, freezed, subscription, l10n, mobile_scanner, http, qr_flutter, share_plus]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: ServerConfig entity/model/datasource/repository pattern, Hive setup, l10n infrastructure
  - phase: 02-vpn-engine
    provides: Main.dart Hive initialization, AndroidManifest permissions
provides:
  - Subscription freezed entity with usage info fields
  - SubscriptionModel (Hive typeId 1) with toDomain/fromDomain converters
  - SubscriptionLocalDatasource with CRUD + batch saveAll
  - SubscriptionRepository interface and SubscriptionRepositoryImpl
  - subscription-userinfo HTTP header parser
  - CAMERA permission and camera hardware feature
  - 6 new pub dependencies (mobile_scanner, qr_flutter, http, yaml, share_plus, path_provider)
  - kotlinx-coroutines-android Gradle dependency
  - 46+ Phase 3 l10n keys in all 4 locales (en, fa, ru, zh)
affects: [03-02, 03-03, 03-04, 03-05, 03-06]

# Tech tracking
tech-stack:
  added: [mobile_scanner 7.2.0, qr_flutter 4.1.0, http 1.6.0, yaml 3.1.3, share_plus 12.0.2, path_provider 2.1.5, kotlinx-coroutines-android 1.9.0]
  patterns: [Subscription data layer mirrors ServerConfig pattern, SubscriptionModel.fromDomain factory method]

key-files:
  created:
    - lib/features/server/domain/entities/subscription.dart
    - lib/features/server/data/models/subscription_model.dart
    - lib/features/server/data/datasources/subscription_local_datasource.dart
    - lib/features/server/domain/repositories/subscription_repository.dart
    - lib/features/server/data/repositories/subscription_repository_impl.dart
    - lib/features/server/data/parsers/subscription_userinfo_parser.dart
  modified:
    - pubspec.yaml
    - android/app/build.gradle.kts
    - android/app/src/main/AndroidManifest.xml
    - lib/main.dart
    - lib/core/l10n/app_en.arb
    - lib/core/l10n/app_fa.arb
    - lib/core/l10n/app_ru.arb
    - lib/core/l10n/app_zh.arb

key-decisions:
  - "SubscriptionModel uses factory constructor fromDomain (not extension static method like ServerConfigModel) for cleaner API"
  - "Used flutter pub run build_runner instead of dart run build_runner — system dart (3.10.7) doesn't meet SDK constraint (^3.11.4)"

patterns-established:
  - "Subscription data layer: entity → model → datasource → repository, same structure as ServerConfig"
  - "SubscriptionModel.fromDomain factory constructor pattern for Hive model creation"

requirements-completed: [CONF-02, CONF-04, CONF-08, SERV-08]

# Metrics
duration: 4min
completed: 2026-04-05
---

# Phase 03 Plan 01: Subscription Data Foundation Summary

**Subscription data layer (freezed entity, Hive typeId 1, CRUD datasource, repository, userinfo parser) + 6 dependencies + CAMERA permission + 46 l10n keys across 4 locales**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-05T16:07:10Z
- **Completed:** 2026-04-05T16:11:36Z
- **Tasks:** 2
- **Files modified:** 30

## Accomplishments
- Complete Subscription data layer following the established ServerConfig pattern (entity, model, datasource, repository)
- subscription-userinfo HTTP header parser for bandwidth/expiry tracking
- 6 new pub dependencies for Phase 3 features (QR scanning, HTTP, sharing, file paths, YAML)
- CAMERA permission in AndroidManifest with `required="false"` for graceful degradation
- 46+ l10n keys added across all 4 locales (en, fa, ru, zh) covering subscriptions, QR scanning, sorting, filtering, logs, and diagnostics

## Task Commits

Each task was committed atomically:

1. **Task 1: Add dependencies + Subscription entity, model, datasource, repository** - `5f33166` (feat)
2. **Task 2: Add all Phase 3 l10n keys to 4 locale ARB files** - `d452f24` (feat)

## Files Created/Modified
- `lib/features/server/domain/entities/subscription.dart` - Freezed entity with usage info fields
- `lib/features/server/data/models/subscription_model.dart` - Hive model (typeId: 1) with toDomain/fromDomain
- `lib/features/server/data/datasources/subscription_local_datasource.dart` - Hive CRUD + batch saveAll
- `lib/features/server/domain/repositories/subscription_repository.dart` - Abstract repository interface
- `lib/features/server/data/repositories/subscription_repository_impl.dart` - Concrete impl with validation
- `lib/features/server/data/parsers/subscription_userinfo_parser.dart` - HTTP header parser
- `pubspec.yaml` - 6 new dependencies added
- `android/app/build.gradle.kts` - kotlinx-coroutines-android dependency
- `android/app/src/main/AndroidManifest.xml` - CAMERA permission + camera feature
- `lib/main.dart` - SubscriptionModelAdapter registration + subscriptions box
- `lib/core/l10n/app_*.arb` - 46+ l10n keys in all 4 locales

## Decisions Made
- SubscriptionModel uses factory constructor `fromDomain` instead of extension static method (used by ServerConfigModel) — cleaner API, same pattern otherwise
- Used `flutter pub run build_runner` instead of `dart run build_runner` because system dart (3.10.7) doesn't meet SDK constraint (^3.11.4) while Flutter-bundled dart (3.11.4) does

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `dart run build_runner` failed due to system Dart SDK (3.10.7) being older than project requirement (^3.11.4). Resolved by using `flutter pub run build_runner` which uses Flutter's bundled Dart 3.11.4.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Subscription data layer ready for Plan 02 (subscription fetching/parsing service)
- l10n keys ready for all Phase 3 UI work (Plans 03-06)
- CAMERA permission and mobile_scanner dep ready for QR scanning feature
- All dependencies resolved and project compiles cleanly

---
*Phase: 03-subscriptions-server-intelligence*
*Completed: 2026-04-05*
