# Architecture Patterns

**Domain:** Flutter-based Proxy/VPN Client with Xray-core Engine
**Researched:** 2025-07-18
**Overall Confidence:** HIGH — verified against v2rayNG (Kotlin, 30k+ stars) and Hiddify (Flutter, 18k+ stars) source code

## Recommended Architecture

### High-Level System Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER (Dart)                        │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │Dashboard │  │Node List │  │ Routing  │  │Settings│ │
│  │  Screen  │  │  Screen  │  │  Screen  │  │ Screen │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘ │
│       │              │              │             │      │
│  ┌────▼──────────────▼──────────────▼─────────────▼────┐│
│  │              Riverpod Providers / ViewModels         ││
│  │  ConnectionNotifier │ ProfileNotifier │ StatsNotifier││
│  └────────────────────┬────────────────────────────────┘│
│                       │                                  │
│  ┌────────────────────▼────────────────────────────────┐│
│  │              Domain Layer (Use Cases)                ││
│  │  ConnectVpn │ ImportConfig │ TestLatency │ ...      ││
│  └────────────────────┬────────────────────────────────┘│
│                       │                                  │
│  ┌────────────────────▼────────────────────────────────┐│
│  │              Data Layer (Repositories)               ││
│  │  VpnRepository │ ConfigRepository │ SubscriptionRepo││
│  └──────┬─────────────────┬────────────────────────────┘│
│         │                 │                              │
│  ┌──────▼──────┐  ┌───────▼───────┐                     │
│  │Platform     │  │ Hive Local    │                     │
│  │Channel      │  │ Data Source   │                     │
│  │Service      │  │               │                     │
│  └──────┬──────┘  └───────────────┘                     │
│         │                                                │
└─────────┼────────────────────────────────────────────────┘
          │  MethodChannel + EventChannel
          │
┌─────────▼────────────────────────────────────────────────┐
│                    KOTLIN (Android Native)                │
│                                                          │
│  ┌──────────────────┐     ┌──────────────────────────┐  │
│  │  MainActivity    │     │  ArmaVpnService          │  │
│  │  (Channel Host)  │     │  (extends VpnService)    │  │
│  │                  │     │                          │  │
│  │  - MethodChannel │     │  - TUN interface setup   │  │
│  │  - EventChannel  │     │  - Network routing       │  │
│  └────────┬─────────┘     │  - Per-app proxy         │  │
│           │               │  - Foreground service    │  │
│           │               └──────────┬───────────────┘  │
│           │                          │                   │
│  ┌────────▼──────────────────────────▼───────────────┐  │
│  │              XrayCoreManager                       │  │
│  │  - initCoreEnv()                                   │  │
│  │  - startLoop(configJson, tunFd)                    │  │
│  │  - stopLoop()                                      │  │
│  │  - measureOutboundDelay(config, testUrl)            │  │
│  │  - queryStats(tag, link)                           │  │
│  └────────────────────────┬──────────────────────────┘  │
│                           │                              │
└───────────────────────────┼──────────────────────────────┘
                            │  JNI (Go-Mobile bindings)
                            │
┌───────────────────────────▼──────────────────────────────┐
│                 XRAY-CORE AAR (Go-Mobile)                │
│                                                          │
│  libv2ray.aar                                            │
│  ├── Libv2ray.initCoreEnv(assetPath, deviceId)           │
│  ├── Libv2ray.newCoreController(callbackHandler)         │
│  ├── CoreController.startLoop(configJson, tunFd)         │
│  ├── CoreController.stopLoop()                           │
│  ├── CoreController.isRunning                            │
│  ├── Libv2ray.measureOutboundDelay(config, url)          │
│  ├── Libv2ray.queryStats(tag, link)                      │
│  └── Libv2ray.checkVersionX()                            │
│                                                          │
│  Internal: xray-core ↔ tun2socks ↔ TUN fd               │
└──────────────────────────────────────────────────────────┘
```

### Data Flow: User Taps "Connect"

```
1. User taps Connect button
       │
2. Dashboard UI → ConnectionNotifier.toggleConnection()
       │
3. ConnectionNotifier → ConnectVpnUseCase.execute(activeProfile)
       │
4. ConnectVpnUseCase:
   a) ConfigRepository.getProfile(id) → ProfileEntity
   b) XrayConfigBuilder.buildJson(profile, routingRules, dnsSettings) → JSON string
   c) VpnRepository.connect(configJson)
       │
5. VpnRepository → VpnPlatformService.startVpn(configJson)
       │
6. VpnPlatformService calls MethodChannel("com.arma.vpn/method")
   → invokeMethod("startVpn", {"config": configJson})
       │
7. MainActivity.MethodChannel handler receives call
   a) Stores config JSON
   b) Starts ArmaVpnService via Intent
       │
8. ArmaVpnService.onStartCommand():
   a) VpnService.prepare(context) → check permission
   b) Builder().addAddress().addRoute().addDnsServer()
      .setMtu(1500).setSession(serverName).establish()
      → ParcelFileDescriptor (TUN interface)
   c) XrayCoreManager.startLoop(configJson, tunFd)
       │
9. Xray-core starts proxy engine:
   a) Parses JSON config → creates inbound/outbound/routing
   b) Binds to TUN fd via tun2socks
   c) All device traffic → TUN → xray-core → remote proxy server
       │
10. CoreCallbackHandler.onEmitStatus() fires
    → Kotlin updates EventChannel sink
    → Dart EventChannel stream emits ConnectionStatus.connected
    → ConnectionNotifier state updates
    → Dashboard UI rebuilds with "Connected" state
```

### Data Flow: Traffic Statistics (Real-time)

```
1. ArmaVpnService starts periodic timer (every 1 second)
       │
2. XrayCoreManager.queryStats("proxy", "uplink") → bytes up
   XrayCoreManager.queryStats("proxy", "downlink") → bytes down
       │
3. Calculate delta from previous reading → speed (bytes/sec)
       │
4. EventChannel sink.add({"uplink": speed_up, "downlink": speed_down})
       │
5. Dart EventChannel stream → StatsNotifier updates
       │
6. Dashboard UI rebuilds: "↓ 1.2 MB/s  ↑ 45 KB/s"
```

### Data Flow: Import Config from Share Link

```
1. User pastes "vless://uuid@server:port?params#name"
       │
2. ImportConfigScreen → ImportConfigUseCase.execute(link)
       │
3. ImportConfigUseCase → ConfigParser.parse(link)
       │
4. ConfigParser (PURE DART - no platform channel needed):
   a) Detect protocol from scheme (vless://, vmess://, trojan://, ss://)
   b) Decode URI components (vmess:// uses base64-encoded JSON)
   c) Extract: server, port, uuid, security, transport, TLS settings
   d) Return ServerConfig entity
       │
5. ImportConfigUseCase → ConfigRepository.save(serverConfig)
       │
6. ConfigRepository → HiveDataSource.putConfig(serverConfig)
       │
7. ProfileNotifier refreshes → Node List UI updates
```

---

## Component Boundaries

### Flutter Dart Layer

| Component | Responsibility | Communicates With | Notes |
|-----------|---------------|-------------------|-------|
| **Presentation (Screens)** | UI rendering, user input | Riverpod providers only | Never calls repositories directly |
| **Riverpod Providers/Notifiers** | State management, UI logic | Use cases, other providers | ConnectionNotifier, ProfileListNotifier, StatsNotifier, SettingsNotifier |
| **Use Cases** | Business logic orchestration | Repositories | One class per action: ConnectVpn, DisconnectVpn, ImportConfig, TestLatency, UpdateSubscription |
| **Repository Interfaces** | Contract definition | Nothing (interfaces) | Defined in domain layer |
| **Repository Implementations** | Data orchestration | Platform service, Hive data sources | Implements domain interfaces |
| **VpnPlatformService** | Flutter ↔ Kotlin bridge | MethodChannel, EventChannel | Single point of native communication |
| **ConfigParser** | Share link parsing | Nothing (pure Dart) | Protocol-specific parsers: VlessParser, VmessParser, TrojanParser, ShadowsocksParser, Hysteria2Parser |
| **HiveDataSource** | Local persistence | Hive boxes | Configs, subscriptions, settings, routing rules |
| **XrayConfigBuilder** | Profile → Xray JSON | Nothing (pure Dart) | Builds full xray-core JSON config from simplified profile + settings |

### Kotlin Native Layer

| Component | Responsibility | Communicates With | Notes |
|-----------|---------------|-------------------|-------|
| **MainActivity** | Channel registration, VPN permission | Flutter via channels, VpnService | Entry point for all platform channel calls |
| **ArmaVpnService** | TUN interface lifecycle | XrayCoreManager, system VPN APIs | Extends Android VpnService; foreground service with notification |
| **XrayCoreManager** | Xray-core AAR wrapper | libv2ray (Go-Mobile JNI) | Thread-safe singleton; init, start, stop, stats, latency |
| **TrafficMonitor** | Speed calculation | XrayCoreManager, EventChannel | Periodic polling of stats, delta calculation |
| **NotificationManager** | Foreground notification | Android system | Required for VpnService; shows connection state |

### Xray-core AAR Layer

| Component | Responsibility | Communicates With | Notes |
|-----------|---------------|-------------------|-------|
| **Libv2ray** | Static methods for core operations | Go runtime | initCoreEnv, checkVersionX, measureOutboundDelay |
| **CoreController** | Running instance management | TUN fd, network | startLoop, stopLoop, isRunning, queryStats |
| **CoreCallbackHandler** | Callback interface for events | Kotlin handler implementation | onEmitStatus for state changes |

---

## Clean Architecture Layer Breakdown

### Directory Structure

```
lib/
├── main.dart                          # App entry, ProviderScope
├── app.dart                           # MaterialApp.router setup
│
├── core/                              # Shared infrastructure
│   ├── constants/                     # App-wide constants
│   │   ├── app_constants.dart         # Channel names, URLs, etc.
│   │   └── protocol_constants.dart    # Protocol identifiers
│   ├── error/                         # Error types
│   │   ├── failures.dart              # Domain failure classes
│   │   └── exceptions.dart            # Data layer exceptions
│   ├── router/                        # go_router setup
│   │   └── app_router.dart
│   ├── theme/                         # Light/dark theme definitions
│   │   ├── app_theme.dart
│   │   └── app_colors.dart
│   └── utils/                         # Shared utilities
│       ├── formatters.dart            # Speed, latency formatting
│       └── validators.dart            # URL, config validation
│
├── features/                          # Feature modules
│   ├── connection/                    # VPN connection feature
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── connection_status.dart    # Connected/Disconnected/Connecting
│   │   │   ├── repositories/
│   │   │   │   └── vpn_repository.dart       # Interface
│   │   │   └── usecases/
│   │   │       ├── connect_vpn.dart
│   │   │       └── disconnect_vpn.dart
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── vpn_repository_impl.dart
│   │   │   └── datasources/
│   │   │       └── vpn_platform_service.dart # MethodChannel/EventChannel wrapper
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── connection_notifier.dart   # Riverpod AsyncNotifier
│   │       ├── screens/
│   │       │   └── dashboard_screen.dart
│   │       └── widgets/
│   │           ├── connect_button.dart
│   │           └── traffic_stats_card.dart
│   │
│   ├── profile/                       # Server config management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── server_config.dart        # Protocol-agnostic entity
│   │   │   │   └── protocol_settings.dart    # VLESS/VMess/Trojan/etc. specifics
│   │   │   ├── repositories/
│   │   │   │   └── config_repository.dart
│   │   │   └── usecases/
│   │   │       ├── import_config.dart
│   │   │       ├── delete_configs.dart
│   │   │       └── test_latency.dart
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── config_repository_impl.dart
│   │   │   ├── datasources/
│   │   │   │   └── config_local_datasource.dart  # Hive
│   │   │   ├── models/
│   │   │   │   └── server_config_model.dart      # Hive adapter
│   │   │   └── parsers/                           # Share link parsers
│   │   │       ├── config_parser.dart             # Factory/dispatcher
│   │   │       ├── vless_parser.dart
│   │   │       ├── vmess_parser.dart
│   │   │       ├── trojan_parser.dart
│   │   │       ├── shadowsocks_parser.dart
│   │   │       └── hysteria2_parser.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── profile_list_notifier.dart
│   │       ├── screens/
│   │       │   └── node_list_screen.dart
│   │       └── widgets/
│   │           ├── node_card.dart
│   │           └── protocol_badge.dart
│   │
│   ├── subscription/                  # Subscription management
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── subscription.dart
│   │   │   ├── repositories/
│   │   │   │   └── subscription_repository.dart
│   │   │   └── usecases/
│   │   │       ├── add_subscription.dart
│   │   │       └── update_subscription.dart
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── subscription_repository_impl.dart
│   │   │   └── datasources/
│   │   │       ├── subscription_local_datasource.dart
│   │   │       └── subscription_remote_datasource.dart  # HTTP fetch + decode
│   │   └── presentation/
│   │       └── ...
│   │
│   ├── routing/                       # Traffic routing rules
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── routing_rule.dart
│   │   │   └── repositories/
│   │   │       └── routing_repository.dart
│   │   ├── data/
│   │   │   └── ...
│   │   └── presentation/
│   │       └── screens/
│   │           └── routing_screen.dart
│   │
│   └── settings/                      # App settings
│       ├── domain/
│       │   └── entities/
│       │       └── app_settings.dart
│       ├── data/
│       │   └── datasources/
│       │       └── settings_local_datasource.dart
│       └── presentation/
│           └── screens/
│               └── settings_screen.dart
│
└── xray/                              # Xray-specific logic
    ├── config_builder.dart            # ProfileEntity → Xray JSON
    ├── xray_config.dart               # Full Xray JSON structure as Dart class
    └── geo_assets.dart                # geoip.dat, geosite.dat management

android/
└── app/src/main/kotlin/com/arma/vpn/
    ├── MainActivity.kt                # Channel registration
    ├── service/
    │   └── ArmaVpnService.kt          # VpnService implementation
    ├── core/
    │   └── XrayCoreManager.kt         # libv2ray wrapper
    ├── monitor/
    │   └── TrafficMonitor.kt          # Speed calculation
    └── notification/
        └── VpnNotificationManager.kt  # Foreground service notification
```

---

## Platform Channel Contract

This is the critical interface between Flutter and Android. Define it precisely and build both sides against it.

### MethodChannel: `com.arma.vpn/method`

| Method | Arguments | Returns | Description |
|--------|-----------|---------|-------------|
| `startVpn` | `{"config": String}` | `bool` | Start VPN with xray JSON config |
| `stopVpn` | none | `bool` | Stop VPN and release TUN |
| `isRunning` | none | `bool` | Check if core is active |
| `getVersion` | none | `String` | Xray-core version string |
| `measureDelay` | `{"config": String, "url": String}` | `int` (ms) | Single-node latency test |
| `requestVpnPermission` | none | `bool` | Trigger VPN permission dialog |

### EventChannel: `com.arma.vpn/vpn_status`

Streams `Map<String, dynamic>`:

```dart
// Connection state changes
{"type": "status", "state": "connecting" | "connected" | "disconnected" | "error", "message": "..."}

// Traffic stats (emitted every 1 second while connected)
{"type": "stats", "uplink": int, "downlink": int}  // bytes per second
```

**Design decision: single EventChannel with typed events** rather than separate channels for status and stats. This simplifies channel management and the Dart side can filter by `type` field. v2rayNG uses broadcast intents (Android-native pattern); Hiddify uses gRPC streaming. For a Flutter app, EventChannel is the idiomatic approach.

### VpnPlatformService (Dart Wrapper)

```dart
/// Single point of contact for all native VPN operations.
/// Lives in data layer. Implements no domain interface directly —
/// it's consumed by VpnRepositoryImpl.
class VpnPlatformService {
  static const _methodChannel = MethodChannel('com.arma.vpn/method');
  static const _eventChannel = EventChannel('com.arma.vpn/vpn_status');

  Future<bool> startVpn(String configJson) async {
    return await _methodChannel.invokeMethod<bool>('startVpn', {'config': configJson}) ?? false;
  }

  Future<bool> stopVpn() async {
    return await _methodChannel.invokeMethod<bool>('stopVpn') ?? false;
  }

  Future<bool> get isRunning async {
    return await _methodChannel.invokeMethod<bool>('isRunning') ?? false;
  }

  Future<int> measureDelay(String configJson, String testUrl) async {
    return await _methodChannel.invokeMethod<int>('measureDelay', {
      'config': configJson,
      'url': testUrl,
    }) ?? -1;
  }

  Stream<Map<String, dynamic>> get vpnEvents {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
  }

  Stream<ConnectionStatus> get connectionStatus {
    return vpnEvents
        .where((e) => e['type'] == 'status')
        .map((e) => ConnectionStatus.fromMap(e));
  }

  Stream<TrafficStats> get trafficStats {
    return vpnEvents
        .where((e) => e['type'] == 'stats')
        .map((e) => TrafficStats.fromMap(e));
  }
}
```

---

## Patterns to Follow

### Pattern 1: Feature-First Module Organization

**What:** Each feature (connection, profile, subscription, routing, settings) is a self-contained module with its own domain/data/presentation layers.

**Why:** Prevents cross-feature coupling. Features can be developed and tested independently. Natural work parallelization.

**Boundary rule:** Features communicate through shared Riverpod providers, never by importing each other's data or domain layers. If feature A needs data from feature B, it reads feature B's provider.

### Pattern 2: Xray Config Builder as Pure Dart

**What:** Build the full xray-core JSON configuration entirely in Dart, pass the complete JSON string to the native side.

**Why:** Keeps all config logic testable in Dart. The native side is a dumb executor — it receives valid JSON and passes it to `CoreController.startLoop()`. This is exactly how v2rayNG works: `V2rayConfigManager.getV2rayConfig()` builds the JSON, then `startCoreLoop()` passes it to the core.

**Example config structure the builder produces:**

```json
{
  "log": {"loglevel": "warning"},
  "dns": {"servers": [{"address": "1.1.1.1"}, "localhost"]},
  "inbounds": [{
    "tag": "socks-in",
    "protocol": "socks",
    "listen": "127.0.0.1",
    "port": 10808
  }],
  "outbounds": [{
    "tag": "proxy",
    "protocol": "vless",
    "settings": {"vnext": [{"address": "...", "port": 443, "users": [...]}]},
    "streamSettings": {"network": "ws", "security": "tls", ...}
  }, {
    "tag": "direct",
    "protocol": "freedom"
  }, {
    "tag": "block",
    "protocol": "blackhole"
  }],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {"type": "field", "outboundTag": "direct", "domain": ["geosite:private"]},
      {"type": "field", "outboundTag": "direct", "ip": ["geoip:private"]}
    ]
  },
  "stats": {}
}
```

### Pattern 3: Connection State Machine

**What:** Model VPN connection as an explicit state machine with defined transitions.

**Why:** Prevents impossible states (e.g., "connecting while already connected"). Makes UI rendering predictable.

```dart
sealed class ConnectionStatus {
  const ConnectionStatus();
}
class Disconnected extends ConnectionStatus {
  final String? lastError;
  const Disconnected([this.lastError]);
}
class Connecting extends ConnectionStatus {
  const Connecting();
}
class Connected extends ConnectionStatus {
  const Connected();
}
class Disconnecting extends ConnectionStatus {
  const Disconnecting();
}
```

**Valid transitions:**
```
Disconnected → Connecting → Connected → Disconnecting → Disconnected
                    ↓                                        ↑
                    └──── (on error) ────────────────────────┘
```

### Pattern 4: Repository Pattern with Hive

**What:** Abstract Hive behind repository interfaces. Repository implementations in `data/` layer; interfaces in `domain/` layer.

**Why:** Hive API is simple but leaks implementation details. If you ever migrate to Isar or drift, only the `data/` layer changes.

```dart
// domain/repositories/config_repository.dart
abstract class ConfigRepository {
  Future<List<ServerConfig>> getAllConfigs();
  Future<ServerConfig?> getConfig(String id);
  Future<void> saveConfig(ServerConfig config);
  Future<void> deleteConfigs(List<String> ids);
  Future<List<ServerConfig>> getConfigsBySubscription(String subscriptionId);
}

// data/repositories/config_repository_impl.dart
class ConfigRepositoryImpl implements ConfigRepository {
  final Box<ServerConfigModel> _configBox;
  // ... maps between domain entities and Hive models
}
```

### Pattern 5: Latency Testing Off-Main-Thread

**What:** Latency tests must run in Kotlin coroutines (native side), not Dart isolates. Each test creates a temporary xray config and calls `Libv2ray.measureOutboundDelay()`.

**Why:** `measureOutboundDelay` is a blocking Go call that creates a temporary xray instance, sends an HTTP request through it, and measures RTT. This runs entirely in the Go runtime. The Dart side just fires a MethodChannel call and awaits the `Future<int>`.

**For bulk testing:** Queue tests sequentially (one at a time) to avoid port conflicts. Use a Kotlin coroutine dispatcher with single-thread concurrency.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Building Xray Config on Native Side

**What:** Passing raw profile parameters to Kotlin and assembling the JSON there.

**Why bad:** Kotlin code is harder to unit test. Config assembly logic gets split across Dart models and Kotlin builders. Leads to two places that "understand" xray config format.

**Instead:** Build the complete JSON in Dart. The `XrayConfigBuilder` class takes a `ServerConfig` entity + `RoutingRules` + `AppSettings` and produces a full xray JSON string. Native side treats it as opaque.

### Anti-Pattern 2: Multiple MethodChannels

**What:** Creating separate channels per feature (one for VPN, one for latency, one for stats).

**Why bad:** Channel registration in MainActivity becomes sprawling. Harder to reason about native lifecycle. Risk of channel name typos.

**Instead:** Single MethodChannel with method name routing. Single EventChannel with typed events. Clean, predictable, easy to debug.

### Anti-Pattern 3: Holding VPN State in Dart Only

**What:** Tracking connection state solely via Dart variables without native confirmation.

**Why bad:** VPN can be killed by Android OS (memory pressure, battery optimization). User can revoke VPN permission via system settings. Native-side state and Dart-side state drift apart.

**Instead:** Native side is source of truth. Dart receives state via EventChannel. On app resume, query `isRunning` via MethodChannel to re-sync.

### Anti-Pattern 4: Parsing Share Links on Native Side

**What:** Passing raw URI strings to Kotlin for parsing.

**Why bad:** Dart has excellent URI parsing (`Uri.parse()`). Protocol parsing is pure string manipulation with no platform dependencies. Testing on native side requires Android instrumentation tests.

**Instead:** All parsing logic is pure Dart in `features/profile/data/parsers/`. Unit-testable without a device.

### Anti-Pattern 5: Coupling VpnService to UI Lifecycle

**What:** Starting VpnService only while the app is in foreground.

**Why bad:** VPN must continue running when app is backgrounded or killed.

**Instead:** VpnService runs as a foreground service with a persistent notification. It has its own lifecycle independent of the Flutter engine. The Flutter engine reconnects to it via channels when brought back to foreground.

---

## Key Architecture Decisions

### Where Does Each Piece of Logic Live?

| Logic | Layer | Rationale |
|-------|-------|-----------|
| Share link parsing (vless://, vmess://, etc.) | Dart — `features/profile/data/parsers/` | Pure string manipulation, highly testable in Dart |
| Subscription fetching & base64 decoding | Dart — `features/subscription/data/` | HTTP + string ops, no native needed |
| Xray JSON config building | Dart — `lib/xray/config_builder.dart` | Pure Dart, complex but testable |
| VPN start/stop commands | Native — Kotlin via MethodChannel | Requires Android VpnService APIs |
| TUN interface setup | Native — `ArmaVpnService.kt` | Android system API, must be Kotlin |
| Xray-core process management | Native — `XrayCoreManager.kt` | JNI calls to Go-Mobile AAR |
| Traffic statistics reading | Native — `TrafficMonitor.kt` via EventChannel | Reads from Go runtime, streams to Dart |
| Latency testing | Native — via MethodChannel | `Libv2ray.measureOutboundDelay()` is a Go call |
| Routing rules UI/storage | Dart — `features/routing/` | User-facing CRUD, stored in Hive |
| Routing rules applied to xray | Dart — `XrayConfigBuilder` | Routing rules become JSON routing section |
| Settings storage | Dart — `features/settings/data/` | Hive preferences |
| QR code scanning | Dart — `mobile_scanner` package | Camera access via Flutter plugin, returns string → parsed in Dart |

### VPN Permission Flow

```
1. User taps Connect for first time
2. ConnectionNotifier → VpnRepository.connect()
3. VpnPlatformService.requestVpnPermission()
4. MethodChannel → MainActivity
5. MainActivity calls VpnService.prepare(context)
   → If null: permission already granted
   → If Intent: launch system VPN consent dialog
6. onActivityResult receives user consent
7. Return true/false to Dart
8. If granted → proceed with startVpn
9. If denied → ConnectionNotifier emits Disconnected("VPN permission denied")
```

### Foreground Service Notification

Android requires VpnService to run as a foreground service with a persistent notification. This notification:
- Shows connection state (Connected/Connecting)
- Shows active server name
- Optionally shows live speed
- Has a "Disconnect" action button
- Must be created before `startForeground()` call within 5 seconds of service start

---

## Build Order (Dependencies Between Components)

The architecture has clear dependency chains that dictate build order:

```
Phase 1: Foundation (no platform dependencies)
├── Core: theme, routing, constants, error types
├── Domain entities: ServerConfig, ConnectionStatus, RoutingRule, AppSettings
├── Hive models & adapters (data layer mirrors of entities)
├── Static UI shells for all screens (mocked data)
└── Riverpod provider skeletons

Phase 2: Config & Data (still pure Dart)
├── Share link parsers (vless, vmess, trojan, ss, hysteria2)
├── XrayConfigBuilder (profile + settings → JSON)
├── ConfigRepository + HiveDataSource
├── SubscriptionRepository + remote datasource
├── Profile management CRUD in UI
└── QR scanner integration (Flutter plugin, pure Dart result)

Phase 3: Platform Bridge (requires Android)
├── Platform channel contract (method + event)
├── VpnPlatformService (Dart wrapper)
├── MainActivity channel registration (Kotlin)
├── ArmaVpnService (TUN setup, foreground service)
├── XrayCoreManager (libv2ray AAR integration)
├── VPN permission flow
├── ConnectionNotifier wired to real native bridge
└── Integrate xray-core AAR build into gradle

Phase 4: Polish & Monitoring (depends on Phase 3)
├── TrafficMonitor (Kotlin periodic stats → EventChannel)
├── StatsNotifier (Dart) wired to EventChannel
├── Dashboard live speed display
├── Latency testing (single + bulk)
├── Routing rules applied to XrayConfigBuilder
├── App lifecycle handling (pause/resume reconnection)
└── Error handling & edge cases
```

**Why this order:**
1. Phases 1–2 are pure Dart — testable without a device, fast iteration
2. Phase 3 is the critical integration point — the most risky phase
3. Phase 4 is enhancement — the VPN already works, now make it informative
4. Config parsing (Phase 2) must precede VPN connection (Phase 3) because you need configs to connect
5. XrayConfigBuilder (Phase 2) must exist before native bridge (Phase 3) because native side needs the JSON

---

## Scalability Considerations

| Concern | At 10 configs | At 100 configs | At 1000+ configs |
|---------|---------------|----------------|-------------------|
| Config list rendering | Simple ListView | ListView.builder (already lazy) | Add search/filter, group by subscription |
| Hive storage | No concern | No concern | Consider box partitioning by subscription |
| Bulk latency testing | Sequential, few seconds | Sequential, 30-60 seconds | Show progress bar, allow cancellation |
| Subscription updates | Single HTTP call | Multiple sequential calls | Parallel with concurrency limit |
| Config parsing | Instant | ~100ms | Still fast, string parsing is cheap |

---

## Sources

- **v2rayNG** (Kotlin, native Android, 30k+ stars): [github.com/2dust/v2rayNG](https://github.com/2dust/v2rayNG) — PRIMARY reference for Kotlin/VpnService/libv2ray patterns. Confidence: HIGH (verified by reading source code directly)
- **Hiddify** (Flutter, 18k+ stars): [github.com/hiddify/hiddify-app](https://github.com/hiddify/hiddify-app) — PRIMARY reference for Flutter architecture, Riverpod usage, feature module structure. Confidence: HIGH (verified by reading source code directly)
- **Android VpnService API**: [developer.android.com](https://developer.android.com/reference/android/net/VpnService) — Official Android docs. Confidence: HIGH
- **Flutter Platform Channels**: [docs.flutter.dev](https://docs.flutter.dev/platform-integration/platform-channels) — Official Flutter docs. Confidence: HIGH
- **Xray-core**: [github.com/XTLS/Xray-core](https://github.com/XTLS/Xray-core) — Protocol engine. Config format reference. Confidence: HIGH
- **libv2ray Go-Mobile bindings**: [github.com/niclas-niclas/libv2ray](https://github.com/niclas-niclas/libv2ray) / [github.com/niclas-niclas/xray-core](https://github.com/niclas-niclas/xray-core) — AAR build patterns. Confidence: MEDIUM (multiple forks exist, API may vary)
