# Architecture

**Analysis Date:** 2025-07-15

## Pattern Overview

**Overall:** Default Flutter scaffold (unimplemented — no architecture yet)

The codebase is a freshly generated Flutter project containing only the default counter app template. No architectural layers, state management, routing, or business logic have been implemented.

A comprehensive specification exists at `happ_clone_specs.md` defining the **target architecture**:
- **Pattern:** Clean Architecture + MVVM
- **State Management:** Riverpod
- **Routing:** go_router
- **Local Storage:** Hive or Isar
- **VPN Engine:** Xray-core via Android Platform Channels / `VpnService`

**Key Characteristics:**
- Single-file Dart application (`lib/main.dart`) with no separation of concerns
- No domain, data, or presentation layers exist
- No external dependencies beyond Flutter SDK defaults (`cupertino_icons`, `flutter_lints`)
- Multi-platform shell directories exist (Android, iOS, macOS, Linux, Windows) but contain only default boilerplate

## Current State: Single-File App

**`lib/main.dart`:**
- Contains `main()` entry point calling `runApp(const MyApp())`
- `MyApp` — root `StatelessWidget` returning a `MaterialApp` with default purple theme
- `MyHomePage` — `StatefulWidget` with a counter that increments on FAB press
- Uses raw `setState()` for state management (no Riverpod, no BLoC, no provider)

There are **no layers** to document. The entire application logic, UI, and state live in one file.

## Planned Layers (from `happ_clone_specs.md`)

The spec defines these layers to be built:

**Presentation Layer (MVVM):**
- Purpose: UI screens and ViewModels
- Planned screens: Dashboard, Configurations/Nodes, Routing & Rules, Settings
- State: Riverpod providers

**Domain Layer:**
- Purpose: Business logic, use cases, entities
- Key entities: Server configurations (VLESS, VMess, Trojan, Shadowsocks, Socks/HTTP, Hysteria2)
- Use cases: Connect/disconnect, parse subscription links, latency testing, traffic monitoring

**Data Layer:**
- Purpose: Repositories, data sources, models
- Local: Hive/Isar for configuration persistence
- Remote: Subscription URL fetching, base64 decoding of config links
- Platform: Android platform channels to Xray-core native engine

**Platform Layer (Android-specific):**
- Purpose: Native VPN engine integration
- Location: `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/`
- Contains: `MainActivity.kt` (currently default FlutterActivity, no platform channels)
- Planned: `VpnService` implementation, Xray-core wrapper, `tun2socks` integration

## Data Flow

**Current:** None meaningful — counter increments via `setState()`.

**Planned Data Flow (VPN Connection):**

1. User taps Connect button on Dashboard
2. Riverpod ViewModel triggers connect use case
3. Use case retrieves selected server configuration from Hive/Isar
4. Configuration is serialized to Xray JSON format
5. JSON is passed to Android native code via Platform Channel
6. Kotlin code starts `VpnService`, configures `tun2socks`, and launches Xray-core
7. Connection state updates flow back through Platform Channel → Riverpod → UI

**Planned Data Flow (Subscription Import):**

1. User adds subscription URL (or scans QR code, or pastes from clipboard)
2. App fetches URL content with optional custom User-Agent
3. Response is base64-decoded and parsed for protocol share links (`vless://`, `vmess://`, etc.)
4. Parsed configurations are stored in Hive/Isar
5. UI updates via Riverpod state

**State Management:**
- Currently: Raw `setState()` in `_MyHomePageState`
- Planned: Riverpod for all reactive state

## Key Abstractions

None exist yet. The following are planned per spec:

**Server Configuration Model:**
- Purpose: Represents a proxy server with protocol, address, port, UUID, TLS settings, network type
- Pattern: Dart data class / freezed model

**Subscription Group:**
- Purpose: Groups server configurations from a single subscription URL
- Pattern: Collection with metadata (URL, update timestamp, User-Agent)

**VPN Engine Interface:**
- Purpose: Abstract platform-specific VPN service behind a Dart interface
- Pattern: Platform channel abstraction

**Routing Rule:**
- Purpose: Traffic routing rules (Proxy, Direct, Block) by domain/IP patterns
- Pattern: Rule sets with domain suffix / geoip matching

## Entry Points

**Flutter App:**
- Location: `lib/main.dart`
- Triggers: App launch
- Responsibilities: Currently renders counter demo; will become app initialization with Riverpod scope, router setup, and theme configuration

**Android:**
- Location: `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/MainActivity.kt`
- Current: Default `FlutterActivity()` — no custom logic
- Planned: Platform channel registration, VpnService lifecycle management

**iOS:**
- Location: `ios/Runner/AppDelegate.swift`
- Current: Default `FlutterAppDelegate` — no custom logic

**macOS:**
- Location: `macos/Runner/AppDelegate.swift`
- Current: Default boilerplate

## Error Handling

**Strategy:** None implemented

**Planned (per spec):**
- Connection errors from VPN engine → surface in UI
- Subscription fetch failures → user notification
- Configuration parse errors → skip invalid entries, report to user

## Cross-Cutting Concerns

**Logging:** Not implemented. Spec mentions "Export App Logs" in Settings.
**Validation:** Not implemented. Needed for configuration parsing and URL validation.
**Authentication:** Not applicable — app is a local-only proxy client with no user accounts.
**Theming:** Default MaterialApp theme with `ColorScheme.fromSeed(seedColor: Colors.deepPurple)`. Spec calls for Light/Dark mode toggle with Deep Blue/Indigo primary.

---

*Architecture analysis: 2025-07-15*
