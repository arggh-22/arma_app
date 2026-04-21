# Arma Proxy & VPN Client — Technical Specification

> Privacy-first proxy/VPN client for Android built with Flutter + sing-box core.

## 1. Tech Stack

### Core Framework

| Component | Version / Detail |
|---|---|
| **Flutter** | Material 3, `generate: true` for l10n |
| **Dart SDK** | `^3.11.4` |
| **Android** | minSdk 24, Java 17, Kotlin, namespace `com.arma.vpn` |
| **VPN Engine** | sing-box v1.13.6 (Libbox AAR), with Xray-core fallback toggle |

### Dependencies

| Category | Packages |
|---|---|
| **State Management** | `flutter_riverpod: ^3.3.1`, `riverpod_annotation: ^4.0.2` |
| **Navigation** | `go_router: ^17.2.0` |
| **Local Storage** | `hive_ce: ^2.19.3`, `hive_ce_flutter: ^2.3.4`, `shared_preferences: ^2.5.5` |
| **Networking** | `http: ^1.6.0`, `connectivity_plus: ^7.1.1` |
| **Code Gen (annotations)** | `freezed_annotation: ^3.1.0`, `json_annotation: ^4.11.0` |
| **UI / UX** | `gap: ^3.0.1`, `flutter_animate: ^4.5.2`, `qr_flutter: ^4.1.0`, `mobile_scanner: ^7.2.0` |
| **Utilities** | `uuid: ^4.5.3`, `equatable: ^2.0.8`, `yaml: ^3.1.3`, `intl: ^0.20.2` |
| **Platform / Sharing** | `share_plus: ^12.0.2`, `path_provider: ^2.1.5`, `url_launcher: ^6.3.2`, `device_info_plus: ^12.4.0` |

### Dev Dependencies

| Category | Packages |
|---|---|
| **Code Generators** | `riverpod_generator: ^4.0.3`, `freezed: ^3.1.0`, `json_serializable: ^6.12.0`, `hive_ce_generator: ^1.10.0`, `build_runner: ^2.13.1` |
| **Linting** | `flutter_lints: ^6.0.0`, `riverpod_lint: ^3.1.3` |
| **Testing** | `flutter_test` (SDK), `mockito: ^5.6.4` |

---

## 2. Architecture

### Pattern: Feature-first Clean Architecture + MVVM with Riverpod

```
lib/
├── main.dart              # Bootstrap: Hive init, SharedPreferences, ProviderScope
├── app.dart               # ArmaApp: MaterialApp.router, theme/locale, auto-refresh subscriptions
├── hive_registrar.g.dart  # Generated Hive adapter registration
├── core/                  # Cross-cutting concerns
│   ├── constants/         # app_constants.dart, protocol_constants.dart
│   ├── error/             # exceptions.dart, failures.dart
│   ├── l10n/              # ARB files (en, fa, ru, zh)
│   ├── router/            # app_router.dart (GoRouter)
│   ├── theme/             # app_theme.dart, app_colors.dart
│   └── utils/             # clipboard_helper.dart
├── shared/widgets/        # navigation_shell.dart
├── singbox/               # sing-box config builder + platform service
│   ├── config_builder.dart
│   └── singbox_platform_service.dart
├── xray/formatters/       # speed_formatter.dart
└── features/              # 6 feature modules
    ├── server/
    ├── connection/
    ├── dashboard/
    ├── routing/
    ├── settings/
    └── log/
```

### Each Feature Module

```
lib/features/<feature>/
├── data/           # Models (Hive), datasources, repositories impl, parsers
├── domain/         # Entities (Freezed), repository interfaces
└── presentation/   # Providers (Riverpod), screens, widgets
```

### Data Flow

```
Screen → Provider/Notifier → Repository (interface in domain, impl in data) → Datasource (Hive box)
```

---

## 3. Supported Protocols

| Protocol | Transport | TLS | Special |
|---|---|---|---|
| **VLESS** | TCP, WebSocket, gRPC, HTTP/2 | TLS, Reality, XTLS | Flow: `xtls-rprx-vision` (auto-default for Reality+TCP) |
| **VMess** | TCP, WebSocket, gRPC, HTTP/2 | TLS | Legacy base64-JSON + standard URI |
| **Trojan** | TCP, WebSocket, gRPC | TLS | Password-based |
| **Shadowsocks** | TCP | — | SIP002 format, multiple ciphers |
| **Hysteria2** | QUIC | TLS | Obfuscation, bandwidth control |
| **SOCKS5 / HTTP** | TCP | Optional | Basic proxy protocols |

---

## 4. Feature Modules — Detailed

### 4.1 Server Management (`features/server/`)

**Domain Entities:**
- `ServerConfig` (`@freezed`) — 48+ fields covering all protocols, transports, TLS, Reality, ECH, subscription metadata
- `Subscription` (`@freezed`) — URL, bandwidth tracking, expiry, auto-update, profile metadata

**Parsers (13 files):**

| Parser | Purpose |
|---|---|
| `ShareLinkParser` | Router: dispatches `vless://`, `vmess://`, `trojan://`, `ss://`, `hysteria2://` + raw JSON VMess |
| `VlessParser` | VLESS URI parsing |
| `VmessParser` | VMess URI parsing (legacy base64-JSON + standard URI) |
| `TrojanParser` | Trojan URI parsing |
| `ShadowsocksParser` | SS/SIP002 URI parsing |
| `Hysteria2Parser` | Hysteria2/hy2 URI parsing |
| `SubscriptionParser` | Auto-detects format: SIP008 JSON, Clash YAML, base64 share links, plain text |
| `ClashParser` | Clash YAML `proxies:` extraction |
| `Sip008Parser` | SIP008 JSON array format |
| `ShareLinkGenerator` | Generates share URIs for all 5 protocols (reverse of parsing) |
| `SubscriptionUserinfoParser` | Parses `subscription-userinfo` header (bandwidth/expiry) |
| `SubscriptionHeadersParser` | Parses profile-title, announce, routing, network-filter, support-url |
| `SubscriptionRoutingParser` | Converts routing JSON → sing-box route rules |

**Functionality:**
- Import servers via share links, QR code, subscription URL, clipboard paste
- Subscription auto-refresh with bandwidth/expiry tracking
- Flag emoji extraction from server names
- Latency testing (individual + bulk)
- Auto-select fastest server
- Multi-select bulk operations (delete)
- Server sorting (Name/Latency/Protocol) and filtering (All/Working/Failed)
- Share link generation + QR display
- Duplicate detection on import

### 4.2 Connection (`features/connection/`)

**Domain:**
- `ConnectionStatus` — Sealed class state machine: `Disconnected` → `Connecting` → `Connected` → `Disconnecting`
- `TrafficStats` — Real-time: uplink/downlink BPS, totals, connection counts

**Platform Channels:**

| Channel | Type | Purpose |
|---|---|---|
| `com.arma.vpn/method` | MethodChannel | `startVpn`, `stopVpn`, `isRunning`, `requestVpnPermission`, `measureLatency`, `testActiveLatency`, `getInstalledApps`, `setPerAppConfig`, `getSingBoxVersion`, `checkSingBoxConfig` |
| `com.arma.vpn/vpn_status` | EventChannel | Status events, traffic stats, debug messages |

**ConnectionNotifier Features:**
- Pre-resolves server domain to IP (breaks circular DNS dependency)
- Reads subscription routing headers for custom rules
- Builds + validates sing-box JSON config
- State timeout (30s connecting, 10s disconnecting)
- Auto-fallback: on error, tries next-best server (up to 3 attempts)
- Lifecycle-aware: re-syncs on app resume

### 4.3 Dashboard (`features/dashboard/`)

Presentation-only (no data/domain). Consumes connection + server providers.

### 4.4 Routing (`features/routing/`)

- Region bypass presets (Iran, China, Russia) using bundled `.srs` rule-set files
- LAN bypass toggle
- Custom domain rules (proxy/direct/block per domain)
- Per-app proxy routing (whitelist/blacklist mode)
- Rules integrated into sing-box config at build time

### 4.5 Settings (`features/settings/`)

- Theme: System/Light/Dark
- Language: EN/FA/RU/ZH (runtime switching)
- DNS: Protocol (DoH/DoT/Plain), remote/direct server picker (Cloudflare/Google/Quad9/AdGuard/Electro/Custom)
- FakeIP DNS mode with CIDR configuration
- Engine: Sniffing toggle, Mux toggle + concurrency (1-8)
- Anti-censorship profiles: None/Light/Moderate/Aggressive
- TLS Fragment (size + sleep ranges), Padding, Mixed SNI
- Diagnostics: log viewer
- Data: clear cached data

### 4.6 Log (`features/log/`)

- Ring buffer (5000 lines max)
- Real-time streaming via `StreamController`
- Level filtering (All/Info/Warning/Error)
- Text search
- Auto-scroll (disables on manual scroll)
- Export to file + system share sheet

---

## 5. Native Android Integration

### Package Structure

```
kotlin/com/arma/vpn/
├── MainActivity.kt                       # Flutter ↔ Native bridge
├── core/SingBoxCoreManager.kt            # Libbox.setup(), getVersion(), checkConfig()
├── engine/
│   ├── VpnEngine.kt                      # Strategy interface
│   ├── SingBoxEngine.kt                  # PlatformInterface + CommandServerHandler
│   ├── NetworkInterfaceArrayIterator.kt   # gomobile iterator adapter
│   └── StringArrayIterator.kt            # gomobile iterator adapter
├── ipc/ServiceConnection.kt              # Messenger-based IPC bridge
├── latency/LatencyTestManager.kt         # URLTest-based latency via temp CommandServer
├── monitor/TrafficMonitor.kt             # CommandClient subscription
├── notification/VpnNotificationManager.kt # Foreground notification
└── service/ArmaVpnService.kt             # Android VpnService in :vpn_process
```

### Two-Process IPC Architecture

```
Flutter (Dart) ←MethodChannel/EventChannel→ MainActivity (main process)
                                              ←Messenger IPC→ ArmaVpnService (:vpn_process)
```

### sing-box Engine Integration

- **SingBoxEngine** implements `PlatformInterface` (15 methods) + `CommandServerHandler`
- **Inverted TUN control**: sing-box calls `openTun(TunOptions)` → engine creates VPN tunnel → returns fd
- **getInterfaces()**: ConnectivityManager via Binder IPC (bypasses SELinux /proc/net/ blocks in VPN process)
- **autoDetectInterfaceControl()**: Socket protection via `VpnService.protect(fd)` — prevents routing loops
- **startDefaultInterfaceMonitor()**: NetworkCallback for network change detection
- **systemCertificates()**: Android CA store → PEM for TLS verification
- **TrafficMonitor**: CommandClient subscribing to `CommandStatus` + `CommandLog` at 1s intervals
- **LatencyTestManager**: Creates temporary CommandServer/CommandClient for `urlTest()` without TUN

---

## 6. Data Layer

### Hive Boxes

| Box | TypeId | Model | Fields |
|---|---|---|---|
| `'configs'` | 0 | `ServerConfigModel` | 48 HiveFields with intentional index gaps for schema evolution |
| `'subscriptions'` | 1 | `SubscriptionModel` | 19 HiveFields |
| `'domain_rules'` | 2 | `DomainRuleModel` | 2 HiveFields: domain, actionIndex |

### SharedPreferences Keys (~30)

Theme, locale, active server ID, DNS (protocol/remote/direct), engine (sniffing/mux/muxConcurrency), anti-censorship (fragment/sleep/padding/mixedSni/profile), per-app (enabled/mode/selectedApps JSON), routing (enabledRegions JSON, bypassLan), engineType, FakeIP (enabled/cidr), deviceId (UUID v4).

### Domain ↔ Data Mapping

- Domain entities use `@freezed` (immutable, `copyWith`, `fromJson`)
- Data models use `@HiveType` with `toDomain()` method + `fromDomain()` extension
- Bidirectional mapping with intentional field index gaps for future schema evolution

---

## 7. sing-box Config Builder

`lib/singbox/config_builder.dart` — Builds complete sing-box JSON configuration from `ServerConfig` + `VpnSettings`.

### Config Sections

| Section | Builder Method | Description |
|---|---|---|
| `log` | `_buildLog()` | Level: debug, output: stderr, timestamps |
| `dns` | `_buildDns()` | Split DNS: remote (DoH via proxy) + local (UDP 1.0.0.1 for direct traffic) |
| `inbounds` | `_buildInbounds()` | TUN with mixed stack, MTU 9000, auto_route, strict_route |
| `outbounds` | `_buildOutbounds()` | Protocol-specific + direct + block |
| `route` | `_buildRoute()` | Sniff → hijack-dns → private IPs → region rules → domain rules → final proxy |
| `experimental` | `_buildExperimental()` | Cache file, FakeIP store |

### Protocol-Specific Outbound Building

- `_buildProxyOutbound()` — dispatches to `_buildVlessOutbound()`, `_buildVmessOutbound()`, etc.
- Handles all transport types (TCP, WebSocket, gRPC, HTTP/2)
- TLS config with Reality, uTLS fingerprint, ECH, ALPN
- Flow auto-default: `xtls-rprx-vision` for VLESS + Reality + TCP
- Fragment/Mux when anti-censorship enabled
- Pre-resolved server IP (breaks DNS circular dependency)
- Subscription routing rules merged at build time

---

## 8. Code Generation

| Annotation | Usage |
|---|---|
| `@freezed` | `ServerConfig`, `Subscription` — immutable domain entities |
| `@HiveType` / `@HiveField` | `ServerConfigModel`, `SubscriptionModel`, `DomainRuleModel` |
| `@JsonSerializable` | Via `@freezed` on domain entities |
| `@Riverpod` / `@riverpod` | All 20+ providers (functional + notifier) |

Build command:
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 9. Localization

| Language | File | Notes |
|---|---|---|
| English | `lib/core/l10n/app_en.arb` (template, ~214 keys) | Default |
| Farsi/Persian | `lib/core/l10n/app_fa.arb` | RTL support |
| Russian | `lib/core/l10n/app_ru.arb` | |
| Chinese | `lib/core/l10n/app_zh.arb` | |

- Config: `l10n.yaml` → generated `app_localizations.dart`
- Runtime locale switching via `localeProvider` (persisted in SharedPreferences)
- Access: `AppLocalizations.of(context)!.someKey`

---

## 10. Testing

### Test Structure (21 test files)

```
test/
├── features/server/data/parsers/     # All 5 protocol parsers + subscription parsers
├── features/server/data/models/      # ServerConfigModel Hive mapping
├── features/server/data/utils/       # FlagEmojiExtractor
├── features/server/domain/entities/  # ServerConfig entity
├── parsers/                          # ClashParser, Sip008Parser, ShareLinkGenerator, SubscriptionParser
├── singbox/                          # SingBoxConfigBuilder (55+ tests)
└── xray/                             # SpeedFormatter, XrayConfigBuilder
```

### Coverage Focus

- Protocol URI parsers (all 5 protocols, edge cases, malformed input)
- Subscription format detection and parsing
- Share link round-trip (generate → re-parse)
- sing-box config builder (DNS, routing, outbounds, transport, TLS, anti-censorship)
- Data model ↔ domain entity mapping

---

## 11. Error Handling

### Two-Tier Pattern

**Data Layer** — Exception subclasses:
- `ParseException` — Invalid share link / subscription data
- `StorageException` — Hive / SharedPreferences failures
- `NetworkException` — HTTP fetch failures

**Domain Layer** — Sealed `Failure` class:
- `ParseFailure`
- `StorageFailure`
- `ClipboardFailure`
- `NetworkFailure`

**Connection errors** — `ConnectionStatus.Disconnected(lastError: String?)` sealed variant.

---

## 12. Key Conventions

- **Imports**: Absolute `package:arma_proxy_vpn_client/...` everywhere, no barrel files
- **Providers**: Code-gen only (`@riverpod` / `@Riverpod(keepAlive: true)`), never manual `Provider(...)`
- **Logging**: `debugPrint()` only (linter enforces `avoid_print`)
- **Part files**: `part '<filename>.g.dart'` and `part '<filename>.freezed.dart'`
- **Notifier mutations**: Call `ref.invalidateSelf()` after state changes
