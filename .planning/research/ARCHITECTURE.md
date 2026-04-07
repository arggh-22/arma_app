# Architecture: sing-box Engine Migration

**Domain:** Flutter VPN Client — Xray-core → sing-box Migration
**Researched:** 2026-04-07
**Overall Confidence:** HIGH — verified against sing-box v1.13.6 libbox source (GitHub SagerNet/sing-box) and Hiddify (Flutter+sing-box reference, 57k+ stars)

---

## Executive Summary

The sing-box migration is an **engine swap, not an architecture rewrite**. The Flutter Dart layer (UI, state management, navigation, persistence) is entirely unaffected. The platform channel interfaces (MethodChannel, EventChannel) stay identical. What changes is: (1) the Dart config builder — different JSON format, (2) three Kotlin files in the native layer — XrayCoreManager, ArmaVpnService, TrafficMonitor, and (3) the native AAR library — libv2ray.aar → sing-box.aar.

The critical architectural difference is **inverted TUN control**: Xray-core receives a TUN fd from Android (`startLoop(config, tunFd)`), while sing-box *requests* a TUN fd from Android via a `PlatformInterface.openTun()` callback. This inverts the control flow in ArmaVpnService and is the highest-risk change.

---

## Migration Impact Map — What Changes, What Stays

### NO CHANGES (Keep As-Is)

| File/Component | Location | Why Unchanged |
|---|---|---|
| **All Flutter UI screens** | `lib/features/*/presentation/` | Pure Dart, no engine dependency |
| **ConnectionStatus entity** | `lib/features/connection/domain/entities/connection_status.dart` | Sealed class is engine-agnostic |
| **TrafficStats entity** | `lib/features/connection/domain/entities/traffic_stats.dart` | Just uplinkBps/downlinkBps, engine-agnostic |
| **VpnPlatformService** | `lib/features/connection/data/datasources/vpn_platform_service.dart` | MethodChannel/EventChannel wrapper — interface unchanged |
| **ConnectionNotifier** (mostly) | `lib/features/connection/presentation/providers/connection_provider.dart` | State machine unchanged; only the config builder call changes (1 line) |
| **ServerConfig entity** | `lib/features/server/domain/entities/server_config.dart` | Same fields, just serialized to different JSON |
| **VpnSettings entity** | `lib/features/settings/domain/entities/vpn_settings.dart` | Same settings, consumed by different builder |
| **All share link parsers** | `lib/features/server/data/parsers/` | Parse URI → ServerConfig, engine-independent |
| **Riverpod providers** | All `*_provider.dart` files | Engine-agnostic state management |
| **VpnNotificationManager** | `android/.../notification/VpnNotificationManager.kt` | Pure Android notification, no engine calls |
| **VpnServiceConnection (Messenger IPC)** | `android/.../ipc/ServiceConnection.kt` | Cross-process IPC is engine-agnostic |
| **AndroidManifest.xml** | Service declaration, permissions | Same VpnService pattern |
| **ProtocolType enum** | `lib/core/constants/protocol_constants.dart` | All 5 protocols supported by both engines |

### REWRITE (New Files)

| Current File | New File | Scope of Change |
|---|---|---|
| `lib/xray/xray_config_builder.dart` | `lib/singbox/singbox_config_builder.dart` | **Complete rewrite** — different JSON schema |
| `android/.../core/XrayCoreManager.kt` | `android/.../core/SingBoxCoreManager.kt` | **Complete rewrite** — different API surface |
| `android/app/libs/libv2ray.aar` | `android/app/libs/singbox.aar` | **Replace** binary |
| `android/app/src/main/assets/geoip.dat` | `android/app/src/main/assets/geoip.db` | **Replace** geo data (sing-box uses .db format) |
| `android/app/src/main/assets/geosite.dat` | `android/app/src/main/assets/geosite.db` | **Replace** geo data |

### SIGNIFICANT MODIFICATION

| File | What Changes | What Stays |
|---|---|---|
| `android/.../service/ArmaVpnService.kt` | TUN creation moves into PlatformInterface callback; engine lifecycle; socket protection mechanism | Service declaration, notification, Messenger IPC, per-app proxy logic, network callback |
| `android/.../monitor/TrafficMonitor.kt` | Stats source: CommandClient subscription replaces QueryStats polling | Callback pattern to ArmaVpnService |
| `android/.../MainActivity.kt` | measureDelay implementation; import changes | MethodChannel/EventChannel setup, VPN permission, per-app config, getInstalledApps |
| `lib/features/connection/presentation/providers/connection_provider.dart` | 1 line: `XrayConfigBuilder.build()` → `SingBoxConfigBuilder.build()` | Everything else |
| `android/app/build.gradle.kts` | AAR filename in `libs/` | Everything else |

---

## Target Architecture (sing-box)

### High-Level System Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER (Dart)                        │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │
│  │Dashboard │  │Node List │  │ Routing  │  │Settings│ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └───┬────┘ │
│       │              │              │             │      │
│  ┌────▼──────────────▼──────────────▼─────────────▼────┐│
│  │              Riverpod Providers (UNCHANGED)          ││
│  └────────────────────┬────────────────────────────────┘│
│                       │                                  │
│  ┌────────────────────▼────────────────────────────────┐│
│  │  SingBoxConfigBuilder.build(server, settings)  [NEW]││
│  │  → sing-box JSON config string                      ││
│  └────────────────────┬────────────────────────────────┘│
│                       │                                  │
│  ┌────────────────────▼────────────────────────────────┐│
│  │  VpnPlatformService (UNCHANGED)                     ││
│  │  MethodChannel: startVpn(configJson, serverName)    ││
│  │  EventChannel: status + stats stream                ││
│  └──────────────────────┬──────────────────────────────┘│
│                         │                                │
└─────────────────────────┼────────────────────────────────┘
                          │ Platform Channels (UNCHANGED)
                          │
┌─────────────────────────▼────────────────────────────────┐
│                 KOTLIN (Android Native)                   │
│                                                          │
│  ┌──────────────────────┐  ┌─────────────────────────┐  │
│  │  MainActivity        │  │  ArmaVpnService         │  │
│  │  (MOSTLY UNCHANGED)  │  │  (extends VpnService    │  │
│  │  - MethodChannel     │  │   + PlatformInterface)  │  │
│  │  - EventChannel      │  │                         │  │
│  │  - measureDelay [Δ]  │  │  - openTun() callback   │  │
│  └────────┬─────────────┘  │  - autoDetectInterface  │  │
│           │                │  - Foreground service    │  │
│           │                │  - Messenger IPC (same)  │  │
│           │                └──────────┬──────────────┘  │
│           │                           │                  │
│  ┌────────▼───────────────────────────▼──────────────┐  │
│  │           SingBoxCoreManager [NEW]                 │  │
│  │  - Libbox.setup(SetupOptions)                      │  │
│  │  - CommandServer(handler, platformInterface)       │  │
│  │  - CommandServer.startOrReloadService(config, opts)│  │
│  │  - CommandServer.closeService()                    │  │
│  │  - CommandClient(handler, options) [for stats]     │  │
│  │  - Libbox.version()                                │  │
│  └────────────────────────┬──────────────────────────┘  │
│                           │                              │
└───────────────────────────┼──────────────────────────────┘
                            │  JNI (Go-Mobile bindings)
                            │
┌───────────────────────────▼──────────────────────────────┐
│                  SING-BOX AAR (Go-Mobile)                 │
│                                                          │
│  singbox.aar (or libbox.aar)                             │
│  ├── Libbox.setup(SetupOptions)                          │
│  ├── Libbox.version() → String                           │
│  ├── Libbox.checkConfig(configContent) → error           │
│  ├── Libbox.formatConfig(configContent) → String         │
│  ├── CommandServer(handler, platformInterface)           │
│  │   ├── .start()                                        │
│  │   ├── .startOrReloadService(config, overrideOptions)  │
│  │   ├── .closeService()                                 │
│  │   ├── .close()                                        │
│  │   └── .needWIFIState() / .needFindProcess()           │
│  ├── CommandClient(handler, options)                     │
│  │   ├── .connect()                                      │
│  │   ├── .disconnect()                                   │
│  │   └── handler → writeStatus(StatusMessage)            │
│  ├── PlatformInterface (implemented by VpnService)       │
│  │   ├── .openTun(TunOptions) → Int (fd)                 │
│  │   ├── .autoDetectInterfaceControl(fd) → VPN protect() │
│  │   ├── .startDefaultInterfaceMonitor(listener)         │
│  │   ├── .getInterfaces() → NetworkInterfaceIterator     │
│  │   ├── .findConnectionOwner(...) → ConnectionOwner     │
│  │   └── .sendNotification(Notification)                 │
│  └── StatusMessage                                       │
│      ├── .uplink / .downlink (bytes/sec)                 │
│      ├── .uplinkTotal / .downlinkTotal                   │
│      ├── .connectionsIn / .connectionsOut                │
│      └── .memory / .goroutines                           │
└──────────────────────────────────────────────────────────┘
```

---

## Critical Architectural Difference: Inverted TUN Control

### Xray-core Flow (Current)
```
ArmaVpnService.startVpn(config):
  1. Android creates TUN: builder.establish() → ParcelFileDescriptor
  2. Android passes TUN fd TO engine: coreController.startLoop(config, tunFd)
  3. Engine reads TUN fd from env: os.Setenv("xray.tun.fd", fd)
  4. Engine starts gVisor TCP/IP stack on that fd
```
**Android controls TUN creation. Engine is passive recipient.**

### sing-box Flow (Target)
```
ArmaVpnService.startVpn(config):
  1. Android creates CommandServer with PlatformInterface (this service)
  2. Android calls commandServer.startOrReloadService(config, options)
  3. sing-box parses config, sees "tun" inbound, calls back:
     → PlatformInterface.openTun(TunOptions) → Android creates TUN now
  4. Android builds TUN from TunOptions (addresses, routes, MTU, per-app)
     → returns fd to sing-box
  5. sing-box creates its own TCP/IP stack on the returned fd
```
**sing-box controls WHEN TUN is created. Android is callback provider.**

### Why This Matters

The TUN configuration (addresses, routes, DNS, MTU, per-app proxy) currently lives in `ArmaVpnService.configureTunInterface()` with hardcoded values. With sing-box, these values come FROM the engine's parsed config via `TunOptions`. The Android side reads them from `TunOptions` and builds the VPN accordingly.

**Benefit:** TUN configuration is now driven by the sing-box JSON config — no more hardcoded `26.26.26.1/30` in Kotlin. Per-app proxy can be configured in JSON too.

**Risk:** The VPN service must implement the full `PlatformInterface` contract correctly or sing-box crashes.

---

## Data Flow: User Taps "Connect" (sing-box)

```
1. User taps Connect button
       │
2. Dashboard UI → ConnectionNotifier.connect(server)  [UNCHANGED]
       │
3. ConnectionNotifier:
   a) Reads VpnSettings from persistence               [UNCHANGED]
   b) SingBoxConfigBuilder.build(server, settings)      [NEW BUILDER]
      → sing-box JSON string
   c) VpnPlatformService.startVpn(configJson, name)    [UNCHANGED]
       │
4. MethodChannel → MainActivity → Intent → ArmaVpnService  [UNCHANGED]
       │
5. ArmaVpnService.startVpn(config):
   a) Start foreground service with notification         [UNCHANGED]
   b) Send "connecting" status via Messenger             [UNCHANGED]
   c) SingBoxCoreManager.setup(context)                  [NEW — replaces XrayCoreManager.initialize]
   d) Create CommandServer(this as CommandServerHandler,
                            this as PlatformInterface)   [NEW]
   e) commandServer.start()                              [NEW]
   f) commandServer.startOrReloadService(config, opts)   [NEW — replaces startLoop]
       │
6. sing-box engine processes config, then CALLS BACK:
   a) PlatformInterface.autoDetectInterfaceControl(fd)
      → ArmaVpnService.protect(fd)                      [REPLACES CoreCallbackHandler.onEmitStatus]
   b) PlatformInterface.openTun(tunOptions)
      → ArmaVpnService builds TUN from options           [MOVED from step 5 to callback]
      → returns fd
   c) PlatformInterface.startDefaultInterfaceMonitor(...)
      → ArmaVpnService registers network monitor        [NEW — replaces registerNetworkCallback]
       │
7. Engine is running → Start traffic monitoring:
   a) CommandClient subscribes to CommandServer           [NEW — replaces QueryStats polling]
   b) StatusMessage delivers uplink/downlink/total        [NEW format]
   c) Forward to EventChannel as stats events            [UNCHANGED sink format]
       │
8. Send "connected" status via Messenger                 [UNCHANGED]
```

---

## Data Flow: Traffic Statistics (sing-box)

### Current (Xray-core): Polling
```
TrafficMonitor → Timer every 1s →
  coreController.queryStats("proxy", "uplink")  → cumulative bytes (resets)
  coreController.queryStats("proxy", "downlink") → cumulative bytes (resets)
  → callback(up, down)
```

### Target (sing-box): Subscription
```
CommandClient(handler, options) where:
  options.addCommand(CommandStatus)
  options.statusInterval = 1000  // ms

handler.writeStatus(StatusMessage) callback fires with:
  statusMessage.uplink    → bytes/sec (instantaneous)
  statusMessage.downlink  → bytes/sec (instantaneous)
  statusMessage.uplinkTotal   → cumulative bytes
  statusMessage.downlinkTotal → cumulative bytes

→ Forward uplink/downlink to EventChannel as stats events
```

**Key difference:** sing-box provides both instantaneous AND cumulative stats in `StatusMessage`. No manual delta calculation needed. The existing `TrafficStats` entity (uplinkBytesPerSecond, downlinkBytesPerSecond) maps directly.

---

## Data Flow: Latency Testing (sing-box)

### Current (Xray-core)
```
MainActivity.measureDelay():
  Libv2ray.measureOutboundDelay(config, url) → Long (ms)
  // Creates temp xray instance, sends HTTP through proxy, measures RTT
```

### Target (sing-box) — Two Options

**Option A: URLTest outbound group (recommended)**
sing-box has built-in `urltest` outbound type that periodically checks latency. This can be configured in the sing-box JSON config for latency testing. However, this requires a running instance.

**Option B: HTTP client through SOCKS5 proxy**
```
1. Start a temporary sing-box instance with SOCKS5 inbound (port 10808)
2. Use Libbox.NewHTTPClient() with client.trySocks5(10808)
3. Execute HTTP request to test URL
4. Measure RTT
5. Stop temporary instance
```

**Option C: Simplest — keep it in Dart**
Since sing-box doesn't have a direct `measureDelay()` equivalent, the simplest approach is to:
1. Start a minimal sing-box instance with a SOCKS5 inbound + the proxy outbound
2. Make HTTP request through the SOCKS5 proxy from Dart (using dio)
3. Measure response time in Dart
4. Stop the mini instance

**Recommendation:** Start with Option C for simplicity. The existing `measureDelay` MethodChannel call stays but the native implementation changes. If too slow, optimize later.

---

## Config Builder: Xray JSON vs sing-box JSON

### Structural Comparison

| Concept | Xray-core JSON | sing-box JSON |
|---|---|---|
| Top-level key | `routing` | `route` |
| Direct outbound | `protocol: "freedom"` | `type: "direct"` |
| Block outbound | `protocol: "blackhole"` | `type: "block"` |
| VLESS outbound | `protocol: "vless"` | `type: "vless"` |
| Server address | `vnext[0].address` | `server` |
| Server port | `vnext[0].port` | `server_port` |
| TLS settings | `streamSettings.tlsSettings` | `tls` (nested object) |
| Transport | `streamSettings.network + ...Settings` | `transport` (nested object with `type`) |
| Sniffing | `inbounds[0].sniffing.enabled` | `route.auto_detect_interface` + `inbounds[0].sniff` |
| DNS config | `dns.servers[]` | `dns.servers[]` (different structure) |
| Stats | `stats: {}` + `policy` section | `experimental.clash_api` or built-in via CommandServer |
| Geo data | `geoip:private`, `geosite:cn` | `geoip:private`, `geosite:cn` (same names, different file format `.db`) |
| Fragment | `sockopt.fragment` | `experimental.tls_fragment` (if available) |
| Mux | `mux.enabled` + `mux.concurrency` | `multiplex` (different field names) |

### Example: VLESS + WS + TLS

**Xray-core (current):**
```json
{
  "log": {"loglevel": "debug"},
  "stats": {},
  "policy": {"levels": {"0": {"statsUserUplink": true, "statsUserDownlink": true}}, "system": {"statsOutboundUplink": true, "statsOutboundDownlink": true}},
  "dns": {"servers": [{"address": "https://1.1.1.1/dns-query", "domains": [], "port": 53}, "localhost"]},
  "inbounds": [{"tag": "tun-in", "protocol": "tun", "settings": {"name": "tun0", "MTU": 9000, "userLevel": 0}, "sniffing": {"enabled": true, "destOverride": ["http", "tls", "quic"]}}],
  "outbounds": [
    {"tag": "proxy", "protocol": "vless", "settings": {"vnext": [{"address": "example.com", "port": 443, "users": [{"id": "uuid", "encryption": "none", "flow": ""}]}]}, "streamSettings": {"network": "ws", "security": "tls", "tlsSettings": {"serverName": "example.com", "allowInsecure": false, "alpn": [], "fingerprint": "chrome"}, "wsSettings": {"path": "/ws", "headers": {"Host": "example.com"}}}},
    {"tag": "direct", "protocol": "freedom", "settings": {}},
    {"tag": "block", "protocol": "blackhole", "settings": {"response": {"type": "http"}}}
  ],
  "routing": {"domainStrategy": "IPIfNonMatch", "rules": [{"type": "field", "outboundTag": "direct", "ip": ["geoip:private"]}, {"type": "field", "outboundTag": "proxy", "port": "0-65535"}]}
}
```

**sing-box (target):**
```json
{
  "log": {"level": "debug", "timestamp": true},
  "dns": {
    "servers": [
      {"tag": "remote", "address": "https://1.1.1.1/dns-query", "detour": "proxy"},
      {"tag": "local", "address": "local"}
    ],
    "rules": [{"outbound": "any", "server": "local"}]
  },
  "inbounds": [
    {"tag": "tun-in", "type": "tun", "inet4_address": "172.19.0.1/30", "inet6_address": "fdfe:dcba:9876::1/126", "mtu": 9000, "auto_route": true, "strict_route": true, "sniff": true, "sniff_override_destination": false}
  ],
  "outbounds": [
    {"tag": "proxy", "type": "vless", "server": "example.com", "server_port": 443, "uuid": "uuid", "tls": {"enabled": true, "server_name": "example.com", "utls": {"enabled": true, "fingerprint": "chrome"}}, "transport": {"type": "ws", "path": "/ws", "headers": {"Host": "example.com"}}},
    {"tag": "direct", "type": "direct"},
    {"tag": "block", "type": "block"}
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {"ip_is_private": true, "outbound": "direct"},
      {"protocol": "dns", "outbound": "dns-out"}
    ],
    "final": "proxy"
  },
  "experimental": {
    "clash_api": {"external_controller": "127.0.0.1:9090"}
  }
}
```

### Key Config Differences to Handle

1. **TUN inbound**: sing-box TUN has `inet4_address`, `inet6_address`, `auto_route`, `strict_route`, `sniff` as direct fields (not nested `settings`/`sniffing`)
2. **Outbound protocol mapping**: `freedom` → `direct`, `blackhole` → `block`, others same names
3. **Server fields**: `vnext[0].address/port` → flat `server`/`server_port`
4. **Users**: `vnext[0].users[0].id` → flat `uuid`
5. **TLS**: `streamSettings.tlsSettings` → nested `tls` object with `enabled: true`
6. **uTLS fingerprint**: `fingerprint` in tlsSettings → `utls.fingerprint` nested
7. **Transport**: `streamSettings.wsSettings` → `transport: {type: "ws", ...}`
8. **Reality**: `streamSettings.realitySettings` → `tls.reality` nested object
9. **Routing**: `routing.rules[].outboundTag` → `route.rules[].outbound`; `type: "field"` not needed; `route.final` replaces catch-all rule
10. **DNS**: Different structure — servers have `tag` and `detour`, rules reference by tag
11. **Stats**: No `stats`/`policy` sections — sing-box uses `experimental.clash_api` or CommandServer
12. **Geo rules**: `geoip:private` → `ip_is_private: true`; `geosite:category-ir` → `geosite: ["category-ir"]`
13. **Hysteria2**: Built-in support as `type: "hysteria2"` outbound

---

## Component-by-Component Migration Guide

### 1. SingBoxConfigBuilder (Dart) — Complete Rewrite

**Location:** `lib/singbox/singbox_config_builder.dart` (new file, parallel to old)

**Interface:** Same as XrayConfigBuilder:
```dart
class SingBoxConfigBuilder {
  static String build(ServerConfig server, {VpnSettings? settings});
  static String buildForLatencyTest(ServerConfig server);
}
```

**What changes inside:**
- JSON structure is completely different (see comparison above)
- Protocol outbound builders produce flat objects instead of nested vnext/servers
- TLS/transport are nested objects within the outbound
- Routing rules use different syntax
- DNS config has tagged servers with detour
- `experimental.clash_api` replaces `stats`/`policy` for traffic monitoring

**What stays:** Input (ServerConfig + VpnSettings) and output type (JSON String) are identical. The ConnectionNotifier just calls a different builder.

### 2. SingBoxCoreManager (Kotlin) — Complete Rewrite

**Location:** `android/.../core/SingBoxCoreManager.kt` (replaces XrayCoreManager.kt)

**Current XrayCoreManager API:**
```kotlin
object XrayCoreManager {
    fun initialize(context: Context)           // go.Seq.setContext + copyAssets + initCoreEnv
    fun createController(callback): CoreController  // creates running instance
    fun getVersion(): String
}
```

**New SingBoxCoreManager API:**
```kotlin
object SingBoxCoreManager {
    fun setup(context: Context)  // Libbox.setup(SetupOptions) — called once
    fun getVersion(): String     // Libbox.version()
    // No createController — CommandServer is created per-session in ArmaVpnService
}
```

**Key differences:**
- `Libbox.setup(SetupOptions)` replaces `go.Seq.setContext()` + `Libv2ray.initCoreEnv()`
- SetupOptions needs: `basePath`, `workingPath`, `tempPath`, `fixAndroidStack`, `commandServerListenPort`, `commandServerSecret`, `debug`
- No geo asset copying needed if bundled in working dir (sing-box reads `.db` files from working path)
- No `CoreController` concept — lifecycle managed by `CommandServer`

### 3. ArmaVpnService (Kotlin) — Significant Modification

**Current responsibilities that STAY:**
- VpnService lifecycle (onCreate, onStartCommand, onBind, onRevoke, onDestroy)
- Foreground notification management
- Messenger IPC (IncomingHandler, sendStatusToClient, sendStatsToClient)
- Per-app proxy logic (whitelist/blacklist via SharedPreferences)
- isRunning state tracking

**Current responsibilities that CHANGE:**

| Current (Xray) | New (sing-box) |
|---|---|
| `configureTunInterface()` called proactively in startVpn | `openTun(TunOptions)` called as callback from engine |
| `CoreCallbackHandler.onEmitStatus(fd)` for socket protect | `PlatformInterface.autoDetectInterfaceControl(fd)` |
| `coreController.startLoop(config, tunFd)` | `commandServer.startOrReloadService(config, opts)` |
| `coreController.stopLoop()` | `commandServer.closeService()` |
| `registerNetworkCallback()` with ConnectivityManager | `PlatformInterface.startDefaultInterfaceMonitor(listener)` |
| `TrafficMonitor` polling queryStats | `CommandClient` subscription |

**The service must implement TWO interfaces:**
1. `CommandServerHandler` — for engine lifecycle callbacks (serviceStop, serviceReload, etc.)
2. `PlatformInterface` — for platform integration callbacks (openTun, autoDetectInterfaceControl, etc.)

**Recommended approach:** Use Hiddify's pattern — create a `PlatformInterfaceWrapper` interface that provides default implementations for most methods, with the VpnService overriding only `openTun()` and `autoDetectInterfaceControl()`.

### 4. TrafficMonitor (Kotlin) — Rewrite

**Current:** Timer-based polling of `coreController.queryStats()` every 1s.

**New:** `CommandClient` subscription model:
```kotlin
class TrafficMonitor(
    private val onStats: (uplink: Long, downlink: Long) -> Unit
) : CommandClientHandler {
    private var client: CommandClient? = null

    fun start() {
        val options = CommandClientOptions().apply {
            addCommand(CommandStatus)
            statusInterval = 1000  // ms
        }
        client = CommandClient(this, options)
        client?.connect()
    }

    fun stop() {
        client?.disconnect()
        client = null
    }

    // CommandClientHandler callbacks
    override fun writeStatus(message: StatusMessage) {
        onStats(message.uplink, message.downlink)
    }
    // ... other required handler methods (connected, disconnected, etc.)
}
```

### 5. MainActivity (Kotlin) — Minor Changes

**measureDelay change:** `Libv2ray.measureOutboundDelay(config, url)` has no direct sing-box equivalent. Options:
- Start a temporary mini sing-box with SOCKS5 inbound, HTTP probe, stop
- Or use `Libbox.NewHTTPClient()` with `trySocks5()` after starting a test instance
- Simplest: Start temp instance via `CommandServer.startOrReloadService(testConfig)`, use HTTP client, stop

**Import changes:** `libv2ray.Libv2ray` → `libbox.Libbox`, etc.

### 6. Build Configuration

**android/app/build.gradle.kts:**
```kotlin
dependencies {
    // REMOVE: implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    // ADD: implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    // Same line, just different AAR file in libs/
    // OR use Maven: implementation("io.github.niclas-niclasen:singbox:1.13.6")
}
```

The `packaging { jniLibs { useLegacyPackaging = true } }` stays — still needed for Go native libs.

---

## sing-box PlatformInterface Contract

The VpnService (or a delegate) must implement this interface. These methods are called by the sing-box engine at runtime:

| Method | Required | Purpose | Implementation |
|---|---|---|---|
| `openTun(TunOptions) → Int` | **CRITICAL** | Create Android TUN, return fd | Build VPN from TunOptions, call `builder.establish()`, return `pfd.fd` |
| `autoDetectInterfaceControl(fd: Int)` | **CRITICAL** | Protect outbound sockets | Call `vpnService.protect(fd)` |
| `usePlatformAutoDetectInterfaceControl() → Boolean` | Required | Whether platform handles socket protection | Return `true` |
| `startDefaultInterfaceMonitor(listener)` | Required | Register for network changes | Wire to ConnectivityManager, call `listener.updateDefaultInterface()` on change |
| `closeDefaultInterfaceMonitor(listener)` | Required | Unregister network listener | Unregister ConnectivityManager callback |
| `getInterfaces() → NetworkInterfaceIterator` | Required | List network interfaces | Enumerate via ConnectivityManager + NetworkInterface |
| `findConnectionOwner(...)` → ConnectionOwner | Needed for process routing | Map connections to apps | Use `ConnectivityManager.getConnectionOwnerUid()` (API 29+) |
| `useProcFS() → Boolean` | Required | Whether to use /proc/net for conn ownership | Return `Build.VERSION.SDK_INT < Build.VERSION_CODES.Q` |
| `underNetworkExtension() → Boolean` | Required | iOS only | Return `false` |
| `includeAllNetworks() → Boolean` | Required | iOS only | Return `false` |
| `readWIFIState() → WIFIState?` | Optional | WiFi SSID for rules | Read from WifiManager |
| `clearDNSCache()` | Optional | Clear DNS cache | No-op for Android |
| `systemCertificates() → StringIterator` | Optional | System CA certs | Read from AndroidCAStore KeyStore |
| `sendNotification(Notification)` | Optional | Engine notifications | Show Android notification |
| `localDNSTransport() → LocalDNSTransport?` | Optional | Local DNS resolution | Implement or return null |

**Hiddify's pattern:** Create a `PlatformInterfaceWrapper` Kotlin interface with default implementations for all methods. The VPN service class implements this interface and overrides only `openTun()` and `autoDetectInterfaceControl()`. Copy the Hiddify defaults for `getInterfaces()`, `findConnectionOwner()`, etc.

---

## Anti-Censorship Feature Mapping

| Feature | Xray-core | sing-box | Notes |
|---|---|---|---|
| **TLS Fragment** | `sockopt.fragment` in streamSettings | Not built-in in stable; may need `tls_fragment` experimental or custom build | ⚠️ VERIFY — may need Hiddify's fork |
| **Reality/XTLS** | `realitySettings` + `flow: xtls-rprx-vision` | `tls.reality` + `flow: xtls-rprx-vision` | Fully supported |
| **uTLS Fingerprint** | `fingerprint: "chrome"` | `tls.utls.fingerprint: "chrome"` | Fully supported |
| **Mux** | `mux.enabled` + `concurrency` | `multiplex.enabled` + `max_connections` | Different field names |
| **Padding** | Custom implementation | May need experimental features | ⚠️ VERIFY |
| **Mixed SNI** | Custom implementation | Not native — may need app-level implementation | ⚠️ VERIFY |

**Critical:** TLS fragment is the most-used anti-censorship feature for Iranian users. If sing-box stable doesn't support it, consider using Hiddify's fork of sing-box which adds fragment support. This must be verified during implementation.

---

## Geo Data Migration

| Current (Xray) | Target (sing-box) |
|---|---|
| `geoip.dat` (V2Ray dat format) | `geoip.db` (sing-box SRS/binary format) |
| `geosite.dat` (V2Ray dat format) | `geosite.db` (sing-box SRS/binary format) |
| Location: `android/app/src/main/assets/` | Same location, different files |
| Source: `v2fly/geoip`, `v2fly/domain-list-community` | Source: `SagerNet/sing-geoip`, `SagerNet/sing-geosite` |

sing-box also supports rule-set based routing (downloading rules on demand) as an alternative to bundled geo databases. For v1.1, bundle the .db files for simplicity.

---

## Suggested Migration Order

### Phase 1: Library Swap + Core Manager (Foundation)
**Goal:** Get sing-box AAR loading and initializing without crashing.

1. Obtain/build sing-box AAR (from Hiddify releases or build from source)
2. Replace `android/app/libs/libv2ray.aar` with `singbox.aar`
3. Replace geo assets (`.dat` → `.db`)
4. Create `SingBoxCoreManager.kt` — just `Libbox.setup()` + `version()`
5. Update `ArmaVpnService.onCreate()` to call `SingBoxCoreManager.setup()` instead of `XrayCoreManager.initialize()`
6. **Verification:** App builds, service initializes, `Libbox.version()` returns valid string

### Phase 2: Config Builder (Dart — parallel work)
**Goal:** Generate valid sing-box JSON from existing ServerConfig.

1. Create `lib/singbox/singbox_config_builder.dart`
2. Implement protocol builders: VLESS, VMess, Trojan, Shadowsocks, Hysteria2
3. Implement transport builders: TCP, WS, gRPC, H2
4. Implement TLS/Reality/uTLS builders
5. Implement DNS config builder
6. Implement routing rules builder (with geo rules)
7. Implement TUN inbound builder
8. **Verification:** Unit tests — compare generated JSON against known-good sing-box configs

### Phase 3: VPN Service Integration (Highest Risk)
**Goal:** Achieve basic connect/disconnect with sing-box engine.

1. Implement `PlatformInterfaceWrapper` (copy pattern from Hiddify, adapt)
2. Modify `ArmaVpnService` to implement `PlatformInterface`
3. Implement `openTun(TunOptions)` — build VPN from options, return fd
4. Implement `autoDetectInterfaceControl(fd)` — call `protect(fd)`
5. Replace startLoop with `CommandServer.startOrReloadService()`
6. Replace stopLoop with `CommandServer.closeService()`
7. Update shutdown order for sing-box lifecycle
8. **Verification:** Manual test — connect to a server, browse internet

### Phase 4: Traffic Monitoring + Latency
**Goal:** Restore dashboard speed display and latency testing.

1. Rewrite `TrafficMonitor` as `CommandClient` subscriber
2. Wire StatusMessage → EventChannel stats events
3. Implement latency testing (new approach for measureDelay)
4. Update `ConnectionNotifier` to use `SingBoxConfigBuilder`
5. **Verification:** Speed display works, latency test returns valid ms values

### Phase 5: Anti-Censorship + Edge Cases
**Goal:** Verify all v1.0 features work under sing-box.

1. Verify TLS fragment (may need Hiddify fork)
2. Verify mux (multiplex) configuration
3. Verify Reality/XTLS flow
4. Verify per-app proxy via TunOptions
5. Verify region presets (geo rules in sing-box format)
6. Verify custom domain rules
7. Clean up: remove old `lib/xray/` directory and `XrayCoreManager.kt`
8. **Verification:** Full regression test of all v1.0 features

### Phase Ordering Rationale

- **Phase 1 before Phase 3** because VPN service depends on the AAR being present and initializing
- **Phase 2 can parallel Phase 1** because config builder is pure Dart, no native dependency
- **Phase 3 depends on Phase 1 + 2** because it needs both the AAR and valid configs
- **Phase 4 depends on Phase 3** because CommandClient needs a running CommandServer
- **Phase 5 last** because anti-censorship features are verification on top of working engine

### Dependency Graph

```
Phase 1 (AAR + CoreManager) ──┐
                               ├──→ Phase 3 (VPN Integration) ──→ Phase 4 (Stats + Latency) ──→ Phase 5 (Verify)
Phase 2 (Config Builder) ─────┘
```

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| TLS Fragment not in sing-box stable | HIGH | Use Hiddify's sing-box fork which adds fragment support |
| PlatformInterface implementation bugs | HIGH | Copy Hiddify's PlatformInterfaceWrapper as baseline, test incrementally |
| Config format differences causing silent failures | MEDIUM | Unit test every protocol × transport × TLS combination |
| sing-box AAR build complexity | MEDIUM | Use pre-built AAR from Hiddify releases instead of building from source |
| StatusMessage stats format different from current TrafficStats | LOW | Both provide bytes/sec — just different field names |
| Latency testing without measureOutboundDelay | LOW | Multiple viable alternatives (SOCKS5 proxy + HTTP, URLTest group) |
| Shutdown order bugs | MEDIUM | sing-box CommandServer.closeService() is cleaner than xray's stopLoop, but still test rapid toggle |

---

## AAR Source Options

1. **Build from source** (github.com/SagerNet/sing-box) using `gomobile bind`
   - Pro: Latest version, full control
   - Con: Complex Go + gomobile toolchain setup

2. **Use Hiddify's pre-built AAR** (from their releases/CI artifacts)
   - Pro: Battle-tested with Flutter, includes TLS fragment patches
   - Con: May include Hiddify-specific modifications

3. **Use community Maven artifact** (if available)
   - Pro: Standard Gradle dependency
   - Con: May not include all needed features (fragment, etc.)

**Recommendation:** Start with Hiddify's pre-built AAR for fastest iteration. If their modifications cause issues, build from source. The AAR API is the same regardless of source — it's the standard `libbox` Go-Mobile binding.

---

## Sources

- sing-box v1.13.6 libbox source code: `github.com/SagerNet/sing-box/experimental/libbox/` (service.go, setup.go, platform.go, config.go, command_server.go, command_client.go, command_types.go, tun.go, monitor.go, http.go) — **HIGH confidence**
- Hiddify Android source: `github.com/hiddify/hiddify-app/android/` (BoxService.kt, VPNService.kt, PlatformInterfaceWrapper.kt, MethodHandler.kt, ServiceConnection.kt, StatsChannel.kt) — **HIGH confidence**
- sing-box official docs: `sing-box.sagernet.org/configuration/` — **HIGH confidence** (config format reference)
- Existing Arma codebase analysis: All 6 Kotlin files, XrayConfigBuilder, ConnectionNotifier, VpnPlatformService — **HIGH confidence** (direct source reading)
