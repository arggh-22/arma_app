# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Privacy-first Xray-core VPN/proxy client. Flutter (Dart 3), Android-primary. iOS/macOS targets are scaffolded (NEPacketTunnelProvider bridge exists; Xray xcframework + Xcode wiring still pending). Linux/Windows/web targets exist but are secondary.

## Commands

```bash
flutter run                                   # Run (Android device/emulator)
flutter build apk                             # Build Android
flutter test                                  # Full test suite
flutter test test/path/to/file_test.dart      # Single test file
flutter analyze                               # Lint (includes custom_lint / riverpod_lint)
dart format lib/ test/                        # Format
dart run build_runner build --delete-conflicting-outputs   # Code generation
```

Run code generation after editing any file with `@Riverpod`, `@HiveType`/`@HiveField`, `@freezed`, or `@JsonSerializable`. Generated `.g.dart` files are committed.

**build_runner gotcha**: `hive_ce_generator` crashes on Dart *records* or `?[` null-aware index anywhere in a `lib/` file (front-end parse failure). Use `MapEntry` + typed helpers instead of records in library code.

## Architecture

Clean Architecture + MVVM. Each feature under `lib/features/<feature>/`:
```
data/          — Hive models, parsers, repository impls, datasources
domain/        — Entities, repository interfaces
presentation/  — Riverpod providers/notifiers, screens, widgets
```

Top level:
- `lib/core/` — router, theme, storage bootstrap, l10n, constants, utils
- `lib/features/` — `connection`, `dashboard`, `server`, `routing`, `settings`, `log`, `api`
- `lib/xray/` — `XrayConfigBuilder` (builds the complete Xray JSON config in Dart)
- `lib/shared/widgets/` — shared UI (e.g. `NavigationShell`)
- `lib/main.dart` — bootstraps `AppConstants`, Workmanager, Hive, SharedPreferences, then `ProviderScope`

## State Management — Riverpod

All providers use `riverpod_annotation` code generation:

```dart
@Riverpod(keepAlive: true)
class MyNotifier extends _$MyNotifier {
  @override
  MyState build() => /* initial */;
}
```

- `keepAlive: true` for app-lifetime state (connection, subscriptions, settings)
- `AsyncValue` for loading/error/data states
- `sharedPreferencesProvider` is overridden at the `ProviderScope` in `main.dart`

## Native Bridge (Android)

All VPN ops go through `VpnPlatformService` (`lib/features/connection/data/datasources/vpn_platform_service.dart`):

- **MethodChannel** `com.arma.vpn/method`: `startVpn`, `stopVpn`, `isRunning`, `requestVpnPermission`, `measureDelay`, `getInstalledApps`, `setPerAppConfig`, `setNotificationDetailsEnabled`, `getXrayVersion`
- **EventChannel** `com.arma.vpn/vpn_status`: streams `{type: 'status', ...}` and `{type: 'stats', ...}`

The EventChannel stream is cached as a singleton broadcast stream. **Never call `receiveBroadcastStream()` more than once** — the second call overwrites the native handler.

Kotlin side (`android/app/src/main/kotlin/com/arma/vpn/`) is a dumb executor. **All Xray JSON config logic lives in Dart**; the native AAR receives the complete JSON string.

## Xray Config Builder

`lib/xray/xray_config_builder.dart` — key rules:
- `XrayConfigBuilder.build(server, settings: vpnSettings)` for normal VPN connections
- `XrayConfigBuilder.buildForLatencyTest(server)` for ping tests (no inbounds, no geo rules)
- VLESS `flow` MUST only be set for TCP + TLS/Reality. Setting flow on WS/gRPC/H2 breaks the connection.
- The server's own address MUST route `direct` (first routing rule) to avoid a TUN → proxy → server → TUN deadlock.
- H2 transport always forces TLS regardless of the `security` field.
- Mirror Happ's xhttp config (include `xPaddingBytes` 10-100, don't force a chrome fingerprint) — a mismatch here caused XHTTP 400s.

## Hive Storage

Boxes opened in `lib/core/storage/app_hive_bootstrap.dart`:
- `configs` → `Box<ServerConfigModel>` (typeId 0)
- `subscriptions` → `Box<SubscriptionModel>`
- `domain_rules` → `Box<DomainRuleModel>`
- Auth box → AES-encrypted via `flutter_secure_storage`

**Schema evolution**: `ServerConfigModel` uses intentional `@HiveField` index gaps (3-4, 7-9, 16-19, 26-29, 36-39). Never reuse a field index; add new fields into a gap with the next available index.

`openHiveBoxSafe<T>()` recovers from corrupt/incompatible data by deleting and reopening the box — safe for non-critical caches only.

## Navigation

`go_router` with `StatefulShellRoute.indexedStack` for persistent tab state:
- Tabs (state preserved): `/dashboard`, `/servers`, `/routing`, `/settings`
- Standalone (no tab): `/logs`, `/telegram-link`

## Localization

5 languages: EN, FA (RTL), HY, RU, ZH. ARB files in `lib/core/l10n/`, config in `l10n.yaml`. Regenerate with `flutter gen-l10n` or `build_runner`. Use `AppLocalizations.of(context)!`.

## Protocols

VLESS (incl. Reality/XTLS), VMess, Trojan, Shadowsocks, Hysteria2. One parser per protocol in `lib/features/server/data/parsers/` (e.g. `vless_parser.dart`, `hysteria2_parser.dart`), plus subscription parsers (Clash, SIP008, JSON, base64).

## arma Subscription API Notes

- The arma `/sub/` endpoint redirects browser User-Agents to HTML (0 servers). Requests must send UA `arma`.
- arma sub links are short-lived: the `/sub/` token embeds an expiry timestamp, so imported arma subs 400 on refresh once expired (not a bug — surface an error, don't crash).
- "Works in Happ but not the app" is usually stale/bad `key_body` from the API (dead IP or apex SNI), not the builder. Diff the config and TCP-probe before editing the builder.

## Key Conventions

- **No `print()`** — use `debugPrint()` (linter enforces `avoid_print`)
- Const constructors everywhere possible; `super.key` shorthand
- Dart 3 pattern matching (`switch` expressions, sealed classes) for state modeling
- Trailing commas on widget trees
- `///` doc comments on public APIs; `//` for inline notes
- Feature barrel files (e.g. `features/server/server.dart`) export only the public API
- Import order: `dart:` → `package:flutter/` → third-party → `package:arma_proxy_vpn_client/`
