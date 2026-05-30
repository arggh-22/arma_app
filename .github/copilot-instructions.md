<!-- GSD Configuration — managed by get-shit-done installer -->
# Instructions for GSD

- Use the get-shit-done skill when the user asks for GSD or uses a `gsd-*` command.
- Treat `/gsd-...` or `gsd-...` as command invocations and load the matching file from `.github/skills/gsd-*`.
- When a command says to spawn a subagent, prefer a matching custom agent from `.github/agents`.
- Do not apply GSD workflows unless the user explicitly asks for them.
- After completing any `gsd-*` command (or any deliverable it triggers: feature, bug fix, tests, docs, etc.), ALWAYS: (1) offer the user the next step by prompting via `ask_user`; repeat this feedback loop until the user explicitly indicates they are done.
<!-- /GSD Configuration -->

---

# Arma Proxy VPN Client — Copilot Instructions

Privacy-first Xray-core VPN/proxy client for Android. Flutter (Dart 3) targeting Android primarily; web target is a documentation/download site.

## Commands

```bash
# Run
flutter run

# Build
flutter build apk

# Test (full suite)
flutter test

# Single test
flutter test test/path/to/test_file.dart

# Lint
flutter analyze

# Format
dart format lib/ test/

# Code generation (Riverpod, Hive, Freezed, JSON)
flutter pub run build_runner build --delete-conflicting-outputs
```

Run code generation after modifying any file with `@Riverpod`, `@HiveType`/`@HiveField`, `@freezed`, or `@JsonSerializable` annotations. The generated `.g.dart` files are committed to the repo.

## Architecture

Clean Architecture + MVVM. Each feature under `lib/features/<feature>/` follows:
```
data/        — Hive models, parsers, repositories impl, datasources
domain/      — Entities, repository interfaces
presentation/ — Riverpod providers/notifiers, screens, widgets
```

Top-level structure:
- `lib/core/` — router, theme, storage bootstrap, l10n, constants, utils
- `lib/features/` — `connection`, `dashboard`, `server`, `routing`, `settings`, `log`, `api`
- `lib/xray/` — `XrayConfigBuilder` (builds complete Xray JSON config in Dart)
- `lib/shared/widgets/` — shared UI components (e.g., `NavigationShell`)

## State Management — Riverpod

All providers use `riverpod_annotation` code generation:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'my_provider.g.dart';

@Riverpod(keepAlive: true)
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => /* initial state */;
}
```

- Use `keepAlive: true` for app-lifetime state (connection, subscriptions, settings)
- Use `AsyncValue` pattern for loading/error/data states in providers
- `sharedPreferencesProvider` is overridden at the `ProviderScope` in `main.dart`

## Native Bridge (Android)

All VPN operations go through `VpnPlatformService` (`lib/features/connection/data/datasources/vpn_platform_service.dart`):

- **MethodChannel**: `com.arma.vpn/method` — `startVpn`, `stopVpn`, `isRunning`, `requestVpnPermission`, `measureDelay`, `getInstalledApps`, `setPerAppConfig`, `setNotificationDetailsEnabled`, `getXrayVersion`
- **EventChannel**: `com.arma.vpn/vpn_status` — streams `{type: 'status', ...}` and `{type: 'stats', ...}` events

The `EventChannel` stream is cached as a singleton broadcast stream. Never call `receiveBroadcastStream()` more than once — the second call overwrites the native handler.

The Kotlin side (`android/app/src/main/kotlin/com/arma/vpn/`) is a dumb executor. **All Xray JSON config logic lives in Dart** via `XrayConfigBuilder.build(server, settings: ...)`. The native AAR receives the complete JSON string.

## Xray Config Builder

`lib/xray/xray_config_builder.dart` — key rules:
- Use `XrayConfigBuilder.build(server, settings: vpnSettings)` for normal VPN connections
- Use `XrayConfigBuilder.buildForLatencyTest(server)` for ping tests (no inbounds, no geo rules)
- VLESS `flow` field MUST only be set for TCP + TLS/Reality. Setting flow on WS/gRPC/H2 breaks the connection.
- Server's own address MUST route `direct` (first routing rule) to prevent TUN → proxy → server → TUN deadlock
- H2 transport always forces TLS regardless of `security` field value

## Hive Storage

Boxes opened in `lib/core/storage/app_hive_bootstrap.dart`:
- `configs` → `Box<ServerConfigModel>` (typeId: 0)
- `subscriptions` → `Box<SubscriptionModel>`
- `domain_rules` → `Box<DomainRuleModel>`
- Auth box → AES-encrypted via `flutter_secure_storage`

**Schema evolution**: `ServerConfigModel` uses intentional `@HiveField` index gaps (e.g., 3-4, 7-9, 16-19, 26-29, 36-39). Never reuse a field index. Add new fields in the gap ranges with the next available index.

`openHiveBoxSafe<T>()` handles corrupt/incompatible data by deleting the box file and reopening clean — safe for non-critical caches.

## Navigation

`go_router` with `StatefulShellRoute.indexedStack` for persistent tab state. Routes:
- `/dashboard`, `/servers`, `/routing`, `/settings` — bottom nav tabs (state preserved)
- `/logs`, `/telegram-link` — standalone screens (no tab, no state preservation)

## Localization

4 languages: EN, FA (RTL), RU, ZH, HY. ARB files in `lib/core/l10n/`. Config in `l10n.yaml`. Run `flutter gen-l10n` or `build_runner` to regenerate. Use `AppLocalizations.of(context)!` in widgets.

## Protocols Supported

VLESS (incl. Reality/XTLS), VMess, Trojan, Shadowsocks, Hysteria2. Parsers in `lib/features/server/data/parsers/`. Each protocol has a dedicated parser file (e.g., `vless_parser.dart`, `hysteria2_parser.dart`).

## Key Conventions

- **No `print()`** — use `debugPrint()` (linter enforces `avoid_print`)
- **Const constructors** everywhere possible; use `super.key` shorthand
- Dart 3 pattern matching (`switch` expressions, sealed classes) preferred for state modeling
- Trailing commas on all widget trees
- `/// doc comments` on all public APIs; `//` for inline notes
- Feature barrel files (e.g., `features/server/server.dart`) export only the public API
- Import order: `dart:` → `package:flutter/` → third-party → `package:arma_proxy_vpn_client/`
