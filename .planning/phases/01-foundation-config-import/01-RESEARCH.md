# Phase 1: Foundation & Config Import - Research

**Researched:** 2026-04-05
**Domain:** Flutter project setup, Material 3 theming, localization (incl. RTL), share link parsing, local storage (hive_ce), navigation (go_router), state management (Riverpod)
**Confidence:** HIGH

## Summary

Phase 1 builds the entire application foundation from a blank Flutter scaffold. It spans six technical domains: (1) dependency installation and project configuration, (2) Clean Architecture + MVVM directory structure with Riverpod, (3) Material 3 theming with teal/cyan seed color and light/dark modes, (4) go_router navigation with bottom navigation shell route, (5) share link parsing for 5 protocol formats (VLESS, VMess, Trojan, Shadowsocks, Hysteria2), and (6) hive_ce local persistence for configs and preferences. Additionally, the app must support 4 languages including Persian with RTL layout.

The technical risk profile of Phase 1 is LOW. All work is pure Dart — no platform channels, no native code, no VPN engine integration. The most complex task is share link parsing, specifically the VMess dual-format problem (legacy base64-JSON vs standard URI), which is a well-documented pitfall. The Hive schema design is the most consequential decision — field index choices made here are permanent and affect all future versions.

**Primary recommendation:** Build the foundation layer-by-layer: dependencies → core infrastructure (theme, router, constants) → domain entities with freezed → data layer with hive_ce → parsers → screens → localization. Run `build_runner` after each model batch. Establish the code generation pipeline early — it touches every layer.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Primary color palette is teal/cyan accent — modern feel, differentiated from competitors' blue/indigo schemes
- **D-02:** Use Material 3 defaults with custom ColorScheme — minimal custom components, ship faster. No custom design system build.
- **D-03:** The connect/disconnect button is a custom circular button with press animation — power-button style, satisfying feedback (Happ-inspired). This is the ONE custom UI element.
- **D-04:** Light and dark themes using Flutter ThemeData with teal/cyan seed color
- **D-05:** Bottom navigation bar with 4 tabs: Dashboard, Servers, Routing, Settings
- **D-06:** Navigation via go_router with shell route for bottom nav persistence
- **D-07:** Each tab is top-level — Routing is its own tab, not nested in Settings
- **D-08:** Server items displayed as cards (not list tiles) — each server in a card with protocol badge, server name, and visual separation (Hiddify-style)
- **D-09:** Servers grouped by subscription source as sections; manually-added servers appear in a "Manual" section
- **D-10:** Tap to select as active node (highlighted/checked state)
- **D-11:** Parse all 5 protocol share link formats in Phase 1: vless://, vmess:// (both legacy base64-JSON and standard URI), trojan://, ss://, hysteria2://
- **D-12:** Parsers are pure Dart — no platform channels needed. Unit-testable.

### Agent's Discretion
- Exact spacing, typography, and card shadow/radius values
- Loading skeleton and empty state designs
- Error handling UI patterns (snackbar vs dialog)
- Exact hive_ce box structure and schema design
- go_router route naming conventions

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| STOR-01 | All configs and subscriptions persist locally across app restarts (hive_ce) | hive_ce 2.19.3 with TypeAdapters; explicit field indices with gaps for schema migration |
| STOR-02 | User preferences (theme, language, routing rules, Xray settings) persist locally | shared_preferences for simple prefs OR hive_ce settings box; both verified |
| UI-01 | App has a clean, modern design with Light and Dark theme (Material 3) | ColorScheme.fromSeed with teal 0xFF00897B seed; ThemeMode toggle; UI-SPEC contract defines all values |
| UI-03 | App supports multiple languages: English, Persian (RTL), Russian, Chinese | flutter_localizations + intl 0.20.2 with ARB files; Directionality auto-handled by MaterialApp |
| UI-07 | FAB on config screen expands with import options: QR, Clipboard, Subscription, Manual | Phase 1 implements Clipboard + Manual Paste (functional) and QR (placeholder snackbar). Subscription is Phase 3. |
| CONF-01 | User can import configs by pasting share links (vless://, vmess://, trojan://, ss://, hysteria2://) | Pure Dart parsers per protocol; VMess dual-format support critical (Pitfall 7) |
| CONF-03 | User can import configs from clipboard with one tap | Flutter services `Clipboard.getData()` + feed into parser pipeline |
| CONF-05 | App parses both VMess formats: legacy base64-JSON and standard URI | Explicit format detection: if content contains `?`, `&`, `@` → standard URI, else → base64-JSON |
| CONF-06 | User can manually enter config via JSON paste | Full-screen dialog with multiline TextField; detect share link vs raw JSON; parse accordingly |
| SERV-01 | User sees a list of all servers grouped by subscription with protocol badges and latency | Grouped ListView.builder with section headers; protocol badge colored chips; latency display deferred to Phase 3 |
| SERV-02 | User can tap a server to select it as the active node | Selection state stored in hive_ce or Riverpod provider; visual feedback per UI-SPEC |
</phase_requirements>

## Project Constraints (from copilot-instructions.md)

- **Tech stack**: Flutter (Dart) with Clean Architecture + MVVM, Riverpod for state management, Hive for local storage, go_router for navigation
- **Platform**: Android-only for v1
- **No backend**: All data stored locally on device
- **Privacy**: No analytics, no tracking, no data collection
- **Naming**: `snake_case.dart` for files, `PascalCase` for classes, `camelCase` for variables/methods
- **Code style**: `dart format` with 80-char line length, trailing commas, `const` constructors
- **Linting**: `flutter_lints` ^6.0.0, `avoid_print` enforced — use `debugPrint()` only
- **Imports**: Use `package:arma_proxy_vpn_client/` for cross-package imports
- **Error handling**: Use `AsyncValue` pattern for Riverpod, specific exception types, no generic catches
- **Widget patterns**: Dart 3 `super.key` syntax, separate widget/state classes
- **Module design**: Each feature directory gets a barrel file

## Standard Stack

### Core (Phase 1 dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | Reactive state management | Spec requirement. Code-gen approach with `@riverpod`. Hiddify uses it. [VERIFIED: pub.dev] |
| riverpod_annotation | ^4.0.2 | Declarative provider annotations | Enables `@riverpod` code gen [VERIFIED: pub.dev] |
| go_router | ^17.2.0 | Declarative routing with shell routes | Official Flutter team package. Supports bottom nav persistence via ShellRoute [VERIFIED: pub.dev] |
| hive_ce | ^2.19.3 | Lightweight NoSQL storage | Community Edition — original Hive abandoned since 2022. API-compatible replacement [VERIFIED: pub.dev] |
| hive_ce_flutter | ^2.3.4 | Flutter integration for hive_ce | Provides `path_provider` integration for Hive box paths [VERIFIED: pub.dev] |
| freezed_annotation | ^3.1.0 | Immutable data class annotations | Generates copyWith, equality, JSON serialization for config models [VERIFIED: pub.dev] |
| json_annotation | ^4.11.0 | JSON serialization annotations | Used with json_serializable for toJson/fromJson [VERIFIED: pub.dev] |
| intl | ^0.20.2 | Internationalization / localization | ARB message extraction, plural/gender support, date/number formatting [VERIFIED: pub.dev] |
| gap | ^3.0.1 | Layout spacing widget | Cleaner than SizedBox for gaps in Row/Column [VERIFIED: pub.dev] |
| shared_preferences | ^2.5.5 | Simple key-value preferences | Theme mode, language selection — lighter than Hive for trivial settings [VERIFIED: pub.dev] |
| uuid | ^4.5.3 | UUID generation | Generate unique IDs for config entries [VERIFIED: pub.dev] |
| equatable | ^2.0.8 | Value equality | Base class for entities where freezed is overkill [VERIFIED: pub.dev] |

### Dev Dependencies (Phase 1)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| riverpod_generator | ^4.0.3 | Generates Riverpod providers | Run via build_runner after annotating providers [VERIFIED: pub.dev] |
| riverpod_lint | ^3.1.3 | Riverpod-specific lint rules | Catches common mistakes at analysis time [VERIFIED: pub.dev] |
| custom_lint | ^0.8.1 | Custom lint runner | Required for riverpod_lint [VERIFIED: pub.dev] |
| freezed | ^3.2.5 | Generates freezed models | Run via build_runner after defining @freezed classes [VERIFIED: pub.dev] |
| json_serializable | ^6.13.1 | Generates toJson/fromJson | Run via build_runner for data models [VERIFIED: pub.dev] |
| hive_ce_generator | ^1.11.1 | Generates Hive TypeAdapters | Run via build_runner for @HiveType models [VERIFIED: pub.dev] |
| build_runner | ^2.13.1 | Code generation runner | `dart run build_runner build --delete-conflicting-outputs` [VERIFIED: pub.dev] |
| mockito | ^5.6.4 | Mocking framework | Unit testing repositories and providers [VERIFIED: pub.dev] |
| flutter_test | SDK | Widget and unit testing | Built-in test framework [VERIFIED: Flutter SDK] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| shared_preferences (for prefs) | hive_ce (single storage) | shared_preferences is simpler for theme/language toggles; using hive_ce for everything adds complexity but reduces dependencies. **Recommendation: use shared_preferences for simple prefs, hive_ce for structured config data** |
| intl + flutter_localizations | easy_localization package | easy_localization is simpler setup but adds a third-party dependency. intl is official Dart/Flutter standard with `flutter gen-l10n`. **Use intl — it's the standard** |
| gap | SizedBox | gap is syntactically cleaner (`Gap(16)` vs `SizedBox(height: 16)` or `SizedBox(width: 16)`) and adapts to parent axis. Minor DX win. |
| equatable | freezed for everything | freezed adds code gen overhead for simple entities. Use equatable for lightweight value objects, freezed for complex models with copyWith/JSON needs |
| flutter_animate | implicit animations only | flutter_animate provides declarative chain API. Phase 1 animations are minimal — implicit animations would work, but flutter_animate is already in the stack plan for Phase 2+ connect button |

**Installation:**
```bash
# Core dependencies
flutter pub add flutter_riverpod riverpod_annotation go_router \
  hive_ce hive_ce_flutter \
  freezed_annotation json_annotation \
  intl shared_preferences uuid gap equatable

# Dev dependencies
flutter pub add --dev riverpod_generator riverpod_lint custom_lint \
  freezed json_serializable hive_ce_generator \
  build_runner mockito

# Enable flutter_localizations (SDK dependency — add manually to pubspec.yaml)
# Under dependencies:
#   flutter_localizations:
#     sdk: flutter
```

**Version verification:** All versions verified against pub.dev API on 2026-04-05. Flutter SDK: 3.41.6, Dart SDK: 3.11.4. [VERIFIED: pub.dev API + local `flutter --version`]

## Architecture Patterns

### Recommended Project Structure

```
lib/
├── main.dart                          # ProviderScope + runApp
├── app.dart                           # MaterialApp.router with theme, locale, go_router
│
├── core/                              # Shared infrastructure (not a feature)
│   ├── constants/
│   │   ├── app_constants.dart         # App name, version display strings
│   │   └── protocol_constants.dart    # Protocol enum, scheme strings
│   ├── error/
│   │   ├── failures.dart              # Domain failure sealed classes
│   │   └── exceptions.dart            # Data layer exceptions
│   ├── router/
│   │   └── app_router.dart            # go_router config with ShellRoute
│   ├── theme/
│   │   ├── app_theme.dart             # ThemeData.light/dark with teal seed
│   │   └── app_colors.dart            # Protocol badge colors, semantic colors
│   ├── l10n/                          # Localization
│   │   ├── app_en.arb                 # English strings (source)
│   │   ├── app_fa.arb                 # Persian strings
│   │   ├── app_ru.arb                 # Russian strings
│   │   └── app_zh.arb                 # Chinese strings
│   └── utils/
│       ├── formatters.dart            # Speed/data formatting utilities
│       └── clipboard_helper.dart      # Clipboard read abstraction
│
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── dashboard_screen.dart
│   │       └── widgets/
│   │           ├── connect_button.dart       # Placeholder circular button
│   │           ├── active_server_card.dart   # Shows selected server
│   │           └── traffic_stats_placeholder.dart
│   │
│   ├── server/                              # "profile" in research → "server" in UI
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── server_config.dart       # @freezed ServerConfig
│   │   │   └── repositories/
│   │   │       └── server_repository.dart   # Abstract interface
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── server_repository_impl.dart
│   │   │   ├── datasources/
│   │   │   │   └── server_local_datasource.dart   # Hive box operations
│   │   │   ├── models/
│   │   │   │   └── server_config_model.dart       # @HiveType model
│   │   │   └── parsers/
│   │   │       ├── share_link_parser.dart          # Factory/dispatcher
│   │   │       ├── vless_parser.dart
│   │   │       ├── vmess_parser.dart               # Handles both formats!
│   │   │       ├── trojan_parser.dart
│   │   │       ├── shadowsocks_parser.dart
│   │   │       └── hysteria2_parser.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── server_list_provider.dart       # @riverpod
│   │       │   └── active_server_provider.dart     # @riverpod
│   │       ├── screens/
│   │       │   └── server_list_screen.dart
│   │       └── widgets/
│   │           ├── server_card.dart
│   │           ├── protocol_badge.dart
│   │           ├── server_group_header.dart
│   │           ├── import_fab.dart                 # Expandable FAB
│   │           ├── paste_config_dialog.dart        # Full-screen paste dialog
│   │           └── empty_server_state.dart
│   │
│   ├── routing/
│   │   └── presentation/
│   │       └── screens/
│   │           └── routing_screen.dart             # Placeholder with toggle
│   │
│   └── settings/
│       ├── domain/
│       │   └── entities/
│       │       └── app_settings.dart               # Theme, language prefs
│       ├── data/
│       │   └── datasources/
│       │       └── settings_local_datasource.dart  # shared_preferences
│       └── presentation/
│           ├── providers/
│           │   ├── theme_provider.dart             # @riverpod ThemeMode
│           │   └── locale_provider.dart            # @riverpod Locale
│           └── screens/
│               └── settings_screen.dart
│
└── shared/                                         # Cross-feature widgets
    └── widgets/
        └── navigation_shell.dart                   # Bottom nav scaffold
```

**Source:** Clean Architecture from `.planning/research/ARCHITECTURE.md`, adapted for Phase 1 scope [VERIFIED: codebase analysis]

### Pattern 1: go_router ShellRoute for Bottom Navigation

**What:** A `ShellRoute` wraps all 4 tab destinations, providing a persistent `NavigationBar` that survives tab switches without rebuilding.

**When to use:** Always — this is the navigation structure for the entire app.

**Example:**
```dart
// Source: go_router official docs + D-06 from CONTEXT.md
final goRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => NavigationShell(child: child),
      routes: [
        GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/servers', builder: (_, __) => const ServerListScreen()),
        GoRoute(path: '/routing', builder: (_, __) => const RoutingScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);
```

**Key detail:** Use `StatefulShellRoute.indexedStack` (go_router 17.x) to preserve each tab's state when switching tabs — without it, tabs rebuild on every switch: [ASSUMED — verify exact API in go_router 17.x docs]

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) =>
    NavigationShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [GoRoute(path: '/dashboard', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/servers', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/routing', ...)]),
    StatefulShellBranch(routes: [GoRoute(path: '/settings', ...)]),
  ],
)
```

### Pattern 2: Riverpod Provider Organization (Code-Gen)

**What:** Use `@riverpod` annotation for all providers. Providers live in feature-specific `providers/` directories.

**When to use:** All state management in the app.

**Example:**
```dart
// Source: Riverpod 3.x code-gen pattern [VERIFIED: riverpod_annotation 4.0.2]
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_list_provider.g.dart';

@riverpod
class ServerListNotifier extends _$ServerListNotifier {
  @override
  Future<List<ServerConfig>> build() async {
    final repository = ref.watch(serverRepositoryProvider);
    return repository.getAllConfigs();
  }

  Future<void> addServer(ServerConfig config) async {
    final repository = ref.read(serverRepositoryProvider);
    await repository.saveConfig(config);
    ref.invalidateSelf();
  }

  Future<void> deleteServer(String id) async {
    final repository = ref.read(serverRepositoryProvider);
    await repository.deleteConfig(id);
    ref.invalidateSelf();
  }
}
```

### Pattern 3: Hive TypeAdapter with Freezed Integration

**What:** Domain entities use `@freezed` for immutability. Hive models use `@HiveType` for storage. Mapper functions convert between them at the data layer boundary.

**When to use:** All persistent data models.

**Why two models:** Domain entities are framework-independent. Hive models carry storage annotations. This separation means switching storage later only affects the data layer. [VERIFIED: ARCHITECTURE.md pattern]

```dart
// Domain entity (features/server/domain/entities/server_config.dart)
@freezed
class ServerConfig with _$ServerConfig {
  const factory ServerConfig({
    required String id,
    required String name,
    required ProtocolType protocol,
    required String address,
    required int port,
    String? uuid,
    String? password,
    // ... protocol-specific fields
    String? subscriptionId,
    required DateTime addedAt,
  }) = _ServerConfig;

  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);
}

// Hive model (features/server/data/models/server_config_model.dart)
@HiveType(typeId: 0)
class ServerConfigModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int protocolIndex; // enum → int for Hive

  @HiveField(5)  // GAP: indices 3-4 reserved for future fields
  final String address;

  @HiveField(6)
  final int port;

  @HiveField(10) // GAP: 7-9 reserved
  final String? uuid;

  @HiveField(11)
  final String? password;

  // ... more fields with index gaps

  @HiveField(30) // GAP for expansion
  final String? subscriptionId;

  @HiveField(31)
  final int addedAtMillis; // DateTime stored as int

  ServerConfigModel({...});
}
```

### Pattern 4: Share Link Parser Pipeline

**What:** A dispatcher function detects the protocol scheme and delegates to protocol-specific parsers. Each parser is a pure function: `String → ServerConfig?`.

**When to use:** Every import path (clipboard, paste, future QR/subscription).

```dart
// Source: D-11, D-12 from CONTEXT.md + PITFALLS.md Pitfall 7
class ShareLinkParser {
  static ServerConfig? parse(String input) {
    final trimmed = input.trim();

    if (trimmed.startsWith('vless://')) return VlessParser.parse(trimmed);
    if (trimmed.startsWith('vmess://')) return VmessParser.parse(trimmed);
    if (trimmed.startsWith('trojan://')) return TrojanParser.parse(trimmed);
    if (trimmed.startsWith('ss://'))    return ShadowsocksParser.parse(trimmed);
    if (trimmed.startsWith('hysteria2://') || trimmed.startsWith('hy2://'))
      return Hysteria2Parser.parse(trimmed);

    // Try raw JSON
    return _tryParseJson(trimmed);
  }
}
```

### Pattern 5: Localization with ARB Files

**What:** Flutter's built-in `flutter gen-l10n` generates type-safe localization from ARB files.

**When to use:** All user-facing strings.

**Setup in `pubspec.yaml`:**
```yaml
flutter:
  generate: true  # Enables flutter gen-l10n
```

**Setup in `l10n.yaml` (project root):**
```yaml
arb-dir: lib/core/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

**Usage:**
```dart
// In MaterialApp.router
MaterialApp.router(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: ref.watch(localeProvider), // from Riverpod
  // ...
)

// In widgets
Text(AppLocalizations.of(context)!.noServersYet)
```

**RTL for Persian:** Automatically handled by `MaterialApp` when locale is `Locale('fa')`. The `Directionality` widget wraps the entire widget tree. Material widgets (Card, ListTile, NavigationBar) respect directionality by default. [VERIFIED: Flutter framework behavior]

### Anti-Patterns to Avoid

- **Don't use `setState` anywhere:** All state goes through Riverpod providers. The existing counter app's `setState` pattern must be completely replaced. [VERIFIED: copilot-instructions.md + spec requirement]
- **Don't create one god Hive box:** Separate boxes by concern — `configs` box for ServerConfigModel, `settings` box is shared_preferences. This allows independent schema migration. [ASSUMED — recommended pattern]
- **Don't skip code generation setup:** Freezed, json_serializable, riverpod_generator, and hive_ce_generator all need build_runner. Set up the pipeline early and run it frequently. Forgetting to run it causes confusing "undefined class" errors.
- **Don't hardcode strings:** Every user-facing string goes through `AppLocalizations` from day one. Retrofitting localization is painful.
- **Don't import across feature boundaries:** Features communicate through Riverpod providers only. `features/server/` never imports from `features/settings/data/`. If they need shared data, use a provider from the other feature's presentation layer. [VERIFIED: ARCHITECTURE.md boundary rule]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Immutable data classes | Manual copyWith, ==, hashCode | `freezed` code gen | 6+ protocol configs with 10-20 fields each. Manual equality is bug-prone and unmaintainable. |
| JSON serialization | Manual toJson/fromJson | `json_serializable` code gen | Protocol configs have many optional fields, nested objects, and enum mappings. Manual parsing invites subtle bugs. |
| Hive TypeAdapters | Manual BinaryReader/Writer | `hive_ce_generator` code gen | TypeAdapters are boilerplate-heavy. Generator handles it perfectly. |
| Riverpod providers | Manual ChangeNotifier/StreamController | `riverpod_generator` code gen | Generated providers have correct disposal, proper type safety, and lint support. |
| Bottom nav state preservation | Manual PageView/IndexedStack | `StatefulShellRoute.indexedStack` from go_router | go_router handles back navigation, deep linking, and state preservation correctly. |
| Localization | Manual Map<String, Map<String, String>> | `flutter gen-l10n` with ARB files | Type-safe generated classes with IDE autocomplete. Handles plurals, gender, RTL automatically. |
| URI parsing for share links | Manual regex-based parsing | `Uri.parse()` + Dart standard library | Dart's `Uri` class handles encoding, query parameters, fragments, and IDN hostnames correctly. |
| Base64 decoding (VMess) | Manual byte manipulation | `dart:convert` `base64.decode()` | Handles padding, URL-safe variants with minor normalization. |

**Key insight:** Phase 1 has ~15 model classes and ~30 generated files. Code generation isn't optional — it's the foundation of the architecture. Skipping it means hand-writing thousands of lines of boilerplate that are error-prone and unmaintainable.

## Common Pitfalls

### Pitfall 1: VMess Share Link Dual Format (CRITICAL for Phase 1)

**What goes wrong:** VMess share links exist in two completely incompatible formats: (1) Legacy: `vmess://` + base64-JSON blob, (2) Standard URI: `vmess://uuid@server:port?params#name`. Parsing only one format means ~40-50% of user configs fail silently.

**Why it happens:** The original v2ray project defined base64-JSON. Later, a standardized URI was proposed. Both remain widely used.

**How to avoid:** Detect format before parsing:
```dart
static ServerConfig? parse(String uri) {
  final content = uri.replaceFirst('vmess://', '');
  // Standard URI format has ?, &, and @ characters
  if (content.contains('?') && content.contains('&') && content.contains('@')) {
    return _parseStandardUri(uri);
  }
  // Legacy base64-JSON format
  return _parseLegacyBase64(content);
}
```
**Warning signs:** Import works for some VMess configs but not others. Users report "works in V2rayNG but not here."

**Source:** PITFALLS.md Pitfall 7, V2rayNG source code [VERIFIED: research analysis]

### Pitfall 2: Hive Schema Migration Not Planned From Start

**What goes wrong:** After v1 release, adding fields to data models corrupts existing Hive boxes. Users must reinstall the app, losing all configurations.

**Why it happens:** Hive doesn't support automatic schema migration. `@HiveField` indices are permanent — once assigned and data is stored, they cannot be changed or reused.

**How to avoid:**
1. Use explicit `@HiveField(index)` annotations with index gaps: use 0, 1, 2, 5, 10, 15 instead of 0, 1, 2, 3, 4, 5
2. Never reorder or remove field indices in updates
3. Add a `schemaVersion` field (index 0) to each model for future manual migration logic
4. Document reserved index ranges per model

**Warning signs:** Any Hive model without explicit field indices. Any model using consecutive indices with no gaps.

**Source:** PITFALLS.md Pitfall 19 [VERIFIED: research analysis]

### Pitfall 3: URI/Share Link Encoding Edge Cases

**What goes wrong:** Share links with non-ASCII server names (Chinese, Farsi, Russian), IDN hostnames, or special characters in passwords fail to parse or produce garbled names.

**Why it happens:** No formal standard for V2ray share link encoding. Different providers use different URL encoding.

**How to avoid:**
```dart
// Always decode URI components properly
final remarks = Uri.decodeComponent(fragment);
// Handle possible base64 URL-safe encoding
content = content.replaceAll('-', '+').replaceAll('_', '/');
// Add missing padding
while (content.length % 4 != 0) content += '=';
// Decode with allowMalformed for resilience
final decoded = utf8.decode(base64.decode(content), allowMalformed: true);
```
**Warning signs:** Server names showing as `%D8%B3%D8%B1%D9%88%D8%B1` or garbled characters.

**Source:** PITFALLS.md Pitfall 20 [VERIFIED: research analysis]

### Pitfall 4: Riverpod Provider Not Wrapping App in ProviderScope

**What goes wrong:** App crashes immediately on launch with `ProviderScope not found` error.

**Why it happens:** Forgetting to wrap `runApp()` with `ProviderScope`.

**How to avoid:** First line of `main()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialize Hive before app starts
  // Register Hive adapters
  Hive.registerAdapter(ServerConfigModelAdapter());
  // Open boxes
  await Hive.openBox<ServerConfigModel>('configs');

  runApp(const ProviderScope(child: ArmaApp()));
}
```

### Pitfall 5: Code Generation Not Running After Model Changes

**What goes wrong:** Confusing "undefined class", "undefined method" errors after editing `@freezed` or `@HiveType` classes.

**Why it happens:** Generated `.g.dart` and `.freezed.dart` files are out of date.

**How to avoid:** Run build_runner after every model change:
```bash
dart run build_runner build --delete-conflicting-outputs
```
For continuous development, use watch mode:
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Pitfall 6: go_router ShellRoute Tab State Loss

**What goes wrong:** Switching tabs causes the previous tab to lose its scroll position and state.

**Why it happens:** Using basic `ShellRoute` instead of `StatefulShellRoute.indexedStack`.

**How to avoid:** Use `StatefulShellRoute.indexedStack` which preserves each branch's widget tree in an IndexedStack. [ASSUMED — needs verification against go_router 17.x API]

## Code Examples

### Share Link Format Reference

Each protocol has a specific URI format. These are the formats the parsers must handle:

#### VLESS
```
vless://uuid@server:port?type=tcp&security=reality&pbk=publicKey&fp=chrome&sni=example.com&sid=shortId&spx=%2F&flow=xtls-rprx-vision#ServerName
```
Key fields: `uuid` (userinfo), `server:port` (host), query params: `type` (network), `security` (tls/reality/none), `encryption` (default: none), `flow` (for XTLS), `sni`, `pbk`+`fp`+`sid`+`spx` (for Reality), fragment = server name. [VERIFIED: FEATURES.md + V2rayNG source patterns]

#### VMess (Legacy Base64-JSON)
```
vmess://eyJ2IjoiMiIsInBzIjoiU2VydmVyTmFtZSIsImFkZCI6InNlcnZlci5jb20iLCJwb3J0IjoiNDQzIiwiaWQiOiJ1dWlkIiwiYWlkIjoiMCIsInNjeSI6ImF1dG8iLCJuZXQiOiJ3cyIsInR5cGUiOiIiLCJob3N0IjoiIiwicGF0aCI6Ii8iLCJ0bHMiOiJ0bHMiLCJzbmkiOiIifQ==
```
Decoded JSON: `{"v":"2","ps":"ServerName","add":"server.com","port":"443","id":"uuid","aid":"0","scy":"auto","net":"ws","type":"","host":"","path":"/","tls":"tls","sni":""}`
Key: `v` must be "2", `ps` = server name, `add` = address, `id` = UUID, `aid` = alterId (usually "0"), `scy` = security (auto/aes-128-gcm/chacha20-poly1305), `net` = network type, `tls` = tls setting. [VERIFIED: PITFALLS.md Pitfall 7]

#### VMess (Standard URI)
```
vmess://uuid@server:port?type=ws&security=tls&path=%2F&host=example.com&encryption=auto&alterId=0#ServerName
```

#### Trojan
```
trojan://password@server:port?type=tcp&security=tls&sni=example.com#ServerName
```
Key: `password` is in userinfo position, not UUID. Uses `security=tls` by default. [VERIFIED: ARCHITECTURE.md]

#### Shadowsocks
```
ss://base64(method:password)@server:port#ServerName
```
Or SIP002 format:
```
ss://base64(method:password)@server:port/?plugin=...#ServerName
```
Key: The `method:password` part is base64-encoded. Common methods: `aes-256-gcm`, `chacha20-ietf-poly1305`. [ASSUMED — standard SS format]

#### Hysteria2
```
hysteria2://auth@server:port?sni=example.com&insecure=0&obfs=salamander&obfs-password=xxx#ServerName
```
Or shorter: `hy2://auth@server:port?...#ServerName`
Key: `auth` is the authentication string. Hysteria2 uses QUIC transport (not configurable). [ASSUMED — less standardized than other protocols]

### Theme Setup
```dart
// Source: UI-SPEC.md + D-01/D-04 from CONTEXT.md
class AppTheme {
  static const _seedColor = Color(0xFF00897B); // Teal 600

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    // Card theme matching UI-SPEC
    cardTheme: const CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
  );

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Colors.grey.shade800), // outlineVariant equivalent
      ),
    ),
  );
}
```

### Protocol Badge Widget
```dart
// Source: UI-SPEC.md Protocol Badge Colors table
class ProtocolBadge extends StatelessWidget {
  final ProtocolType protocol;
  const ProtocolBadge({super.key, required this.protocol});

  static const _colors = {
    ProtocolType.vless:      Color(0xFF00897B), // Teal 600
    ProtocolType.vmess:      Color(0xFF1565C0), // Blue 800
    ProtocolType.trojan:     Color(0xFFE65100), // Orange 900
    ProtocolType.shadowsocks: Color(0xFF6A1B9A), // Purple 800
    ProtocolType.hysteria2:  Color(0xFF2E7D32), // Green 800
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _colors[protocol],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        protocol.label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}
```

### Expandable FAB
```dart
// Source: UI-SPEC.md + UI-07 from REQUIREMENTS.md
// Use AnimatedFloatingActionButton pattern or build custom with AnimatedContainer
class ImportFab extends StatefulWidget {
  const ImportFab({super.key});
  @override
  State<ImportFab> createState() => _ImportFabState();
}

class _ImportFabState extends State<ImportFab> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggle() => setState(() => _isExpanded = !_isExpanded);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sub-FABs (visible when expanded)
        if (_isExpanded) ...[
          _MiniFab(icon: Icons.qr_code_scanner, label: 'Scan QR',
            onTap: () => _showSnackbar(context, 'QR scanning coming soon')),
          const Gap(8),
          _MiniFab(icon: Icons.edit_note, label: 'Paste Config',
            onTap: () => _openPasteDialog(context)),
          const Gap(8),
          _MiniFab(icon: Icons.content_paste, label: 'Clipboard',
            onTap: () => _importFromClipboard(context)),
          const Gap(8),
        ],
        // Main FAB
        FloatingActionButton.extended(
          onPressed: _toggle,
          icon: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0, // 45 degrees
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add),
          ),
          label: const Text('Import Server'),
        ),
      ],
    );
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Original Hive package | hive_ce (Community Edition) | 2023+ | Original abandoned June 2022. hive_ce is drop-in replacement, actively maintained. MUST use hive_ce. [VERIFIED: pub.dev] |
| Manual Riverpod providers | `@riverpod` code generation | Riverpod 2.0+ (2023) | Code gen is the standard approach. Manual providers still work but are discouraged. |
| Named routes in Navigator | go_router with ShellRoute | 2022+ | go_router is the official Flutter navigation solution. Navigator 1.0 named routes are legacy. |
| MaterialApp with onGenerateRoute | MaterialApp.router | Flutter 3.x | Router API is the modern approach for go_router integration. |
| flutter_intl / easy_localization | flutter gen-l10n (built-in) | Flutter 2.5+ | Built-in localization support via `flutter gen-l10n` is now the official recommendation. No third-party packages needed. |
| Hive without Community Edition | hive_ce | 2023 | Critical: hive is abandoned, hive_ce is the continuation |

**Deprecated/outdated:**
- `hive` / `hive_flutter` / `hive_generator`: Use `hive_ce` / `hive_ce_flutter` / `hive_ce_generator` instead [VERIFIED: STACK.md]
- `qr_code_scanner`: Deprecated. Use `mobile_scanner` (Phase 3) [VERIFIED: STACK.md]
- Manual `ChangeNotifier` with `provider` package: Use Riverpod with code gen [VERIFIED: spec requirement]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `StatefulShellRoute.indexedStack` is the correct go_router 17.x API for tab state preservation | Architecture Patterns, Pattern 1 | Medium — if API name differs, the navigation pattern needs adjustment. Verify in go_router 17.x docs. |
| A2 | Shadowsocks share link format uses base64(method:password) in userinfo | Code Examples, Shadowsocks format | Low — standard SS format, but SIP002 variants exist. Test with real configs. |
| A3 | Hysteria2 share link format uses `hysteria2://` or `hy2://` with auth in userinfo | Code Examples, Hysteria2 format | Medium — Hysteria2 format is less standardized. May need adjustment based on real configs from providers. |
| A4 | Separate Hive boxes per concern (configs vs settings) is better than single box | Anti-Patterns | Low — both approaches work. Separate boxes allow independent schema migration. |
| A5 | `flutter_animate` is deferred to later phases; Phase 1 uses implicit animations only | Standard Stack | Low — FAB expansion and card selection use implicit animations which are sufficient. |

## Open Questions

1. **Application ID / Package Name**
   - What we know: Currently `com.example.arma_proxy_vpn_client` — needs changing before any real work
   - What's unclear: What the final package name should be (e.g., `com.arma.vpn`, `io.arma.proxy`)
   - Recommendation: Decide in first task of Phase 1. Affects Android namespace, import paths. Use `com.arma.vpn` to match the MethodChannel contract in ARCHITECTURE.md.

2. **minSdk Version**
   - What we know: Currently uses `flutter.minSdkVersion` (defaults to API 21). STACK.md recommends API 24.
   - What's unclear: Whether API 24 is confirmed by user
   - Recommendation: Set to API 24 per STACK.md recommendation. V2rayNG uses 24. Covers 99%+ of active Android devices. [VERIFIED: STACK.md]

3. **Theme Persistence Mechanism**
   - What we know: Theme and language need to persist (STOR-02)
   - Options: `shared_preferences` (simpler) vs `hive_ce` settings box (consistent with rest of storage)
   - Recommendation: Use `shared_preferences` for theme/language — it's two key-value pairs. Don't over-engineer.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All Flutter development | ✓ | 3.41.6 (stable) | — |
| Dart SDK | All Dart code | ✓ | 3.11.4 | — |
| pub.dev | Package installation | ✓ | — | — |
| Android SDK | Building Android APK | Assumed ✓ | — | — |
| git | Version control | ✓ | — | — |

**Missing dependencies with no fallback:** None identified.

**Missing dependencies with fallback:** None — Phase 1 is pure Dart/Flutter, no native toolchain required beyond standard Flutter setup.

**Note:** Phase 1 requires no Android device/emulator for development — all code is pure Dart, testable with `flutter test`. Android build verification is optional but recommended. [VERIFIED: D-12 from CONTEXT.md — parsers are pure Dart]

## Security Domain

Phase 1 handles no authentication, no network communication, no cryptographic operations, and no sensitive data transmission. All data is local config storage. Security considerations are minimal.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth in app |
| V3 Session Management | No | No sessions |
| V4 Access Control | No | Single user, local only |
| V5 Input Validation | Yes | Validate share link format before parsing; sanitize server names for display; reject malformed URIs gracefully |
| V6 Cryptography | No | No crypto in Phase 1 (base64 is encoding, not encryption) |

### Known Threat Patterns for Phase 1

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed share link injection (buffer/memory issues) | Tampering | Use Dart's `Uri.parse()` with try-catch. Dart is memory-safe — no buffer overflows. Validate all fields after parsing. |
| Clipboard data injection | Tampering | Treat clipboard content as untrusted input. Parse → validate → reject if invalid. Show user what was parsed before saving. |
| Overly long config names causing UI overflow | Denial of Service (UI) | Truncate display names to reasonable length (e.g., 50 chars). Use `Text.overflow: TextOverflow.ellipsis`. |

## Sources

### Primary (HIGH confidence)
- `.planning/research/STACK.md` — Verified package versions, installation commands, alternatives analysis
- `.planning/research/ARCHITECTURE.md` — Clean Architecture layers, directory structure, platform channel contracts, data flow diagrams
- `.planning/research/PITFALLS.md` — Domain pitfalls with code examples from V2rayNG and Hiddify source analysis
- `.planning/research/FEATURES.md` — Feature landscape, share link format details, competitive analysis
- `.planning/phases/01-foundation-config-import/01-UI-SPEC.md` — UI design contract with exact colors, spacing, typography, copywriting
- `.planning/phases/01-foundation-config-import/01-CONTEXT.md` — User decisions D-01 through D-12
- `pubspec.yaml` — Current project state (default scaffold)
- pub.dev API — All package versions verified directly (2026-04-05)

### Secondary (MEDIUM confidence)
- `happ_clone_specs.md` — Reference specification for UI/UX design and development phases
- `copilot-instructions.md` — Project constraints and coding conventions

### Tertiary (LOW confidence)
- Hysteria2 share link format — less standardized than other protocols, based on community convention
- `StatefulShellRoute.indexedStack` API — assumed from go_router patterns, needs verification against 17.x docs

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions verified on pub.dev, all patterns verified from research docs
- Architecture: HIGH — directly from ARCHITECTURE.md which was verified against V2rayNG and Hiddify source code
- Pitfalls: HIGH — derived from production source code analysis (V2rayNG, Hiddify)
- Share link formats: HIGH for VLESS/VMess/Trojan, MEDIUM for Shadowsocks, LOW-MEDIUM for Hysteria2

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (30 days — stable Flutter ecosystem, package versions unlikely to break)
