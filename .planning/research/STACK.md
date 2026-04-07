# Technology Stack — sing-box Engine Migration

**Project:** Arma Proxy & VPN Client v1.1
**Researched:** 2026-04-07
**Overall Confidence:** HIGH — verified via sing-box source code (testing branch, v1.13.6), SFA reference app source, Hiddify reference app source

## Scope

This document covers ONLY the stack changes needed for the sing-box migration. The existing Flutter/Dart/Riverpod/Hive/go_router stack is validated and unchanged.

---

## 1. Core Engine: libbox.aar (replaces libv2ray.aar)

### What It Is

sing-box exposes its engine to Android via **libbox.aar** — a Go-Mobile compiled AAR built from `./experimental/libbox` using `gomobile bind`. The AAR contains native `.so` libraries for all Android ABIs (arm64-v8a, armeabi-v7a, x86, x86_64) and Java/Kotlin bindings under the `io.nekohasekai.libbox` package (configured via `-javapkg=io.nekohasekai`).

### Version

| Component | Version | Source | Confidence |
|-----------|---------|--------|------------|
| sing-box | v1.13.6 (latest stable) | GitHub releases, April 6 2026 | HIGH |
| gomobile | v0.1.12 (sagernet fork) | `Makefile` lib_install target | HIGH |
| Min Android API | 23 (main) / 21 (legacy) | `build_libbox/main.go` | HIGH |
| Build tags | `with_gvisor,with_quic,with_wireguard,with_utls,with_clash_api` + more | `build_libbox/main.go` | HIGH |

### How to Obtain

**Option A: Build from source** (recommended for custom builds)
```bash
# Prerequisites: Go 1.22+, Android SDK, NDK, Java 17
go install github.com/sagernet/gomobile/cmd/gomobile@v0.1.12
go install github.com/sagernet/gomobile/cmd/gobind@v0.1.12

cd sing-box  # cloned at v1.13.6 tag
go run ./cmd/internal/build_libbox -target android
# Produces: libbox.aar (all ABIs) and libbox-legacy.aar (API 21)
```

**Option B: Extract from SFA APK** (quick start for prototyping)
- Download SFA-1.13.6-arm64-v8a.apk from GitHub releases
- Extract the AAR/SO files from the APK

**Recommendation: Option A.** Build from source to control build tags and strip unused protocols if needed. The Arma app's `minSdk = 24` means the main variant (API 23) works. No need for legacy variant.

### Build Configuration

The current `android/app/build.gradle.kts` needs these changes:

```kotlin
// REPLACE: implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
// WITH:    same pattern, but now libs/ contains libbox.aar instead of libv2ray.aar

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}

// packaging block stays the same
packaging {
    jniLibs {
        useLegacyPackaging = true  // Still required for Go native libs in AAR
    }
}
```

---

## 2. API Surface Comparison: libv2ray → libbox

### Current libv2ray API (what we use today)

| API Call | Where Used | Purpose |
|----------|-----------|---------|
| `go.Seq.setContext(ctx)` | XrayCoreManager.initialize() | Initialize Go runtime JNI |
| `Libv2ray.initCoreEnv(assetPath, "")` | XrayCoreManager.initialize() | Load geo assets, init core |
| `Libv2ray.checkVersionX()` | XrayCoreManager.getVersion() | Get engine version string |
| `Libv2ray.newCoreController(callback)` | XrayCoreManager.createController() | Create controller instance |
| `CoreController.startLoop(config, tunFd)` | ArmaVpnService.startVpn() | Start proxy with config JSON + TUN fd |
| `CoreController.stopLoop()` | ArmaVpnService.stopVpn() | Stop proxy |
| `CoreController.isRunning` | Health checks | Check if core is running |
| `CoreController.queryStats(tag, dir)` | TrafficMonitor | Get cumulative bytes (reset-on-read) |
| `Libv2ray.measureOutboundDelay(config, url)` | MainActivity.measureDelay | Static latency test without running instance |
| `CoreCallbackHandler.onEmitStatus(fd, msg)` | ArmaVpnService callback | Socket protection (VPN routing bypass) |

### New libbox API (what we migrate to)

| Old API | New API | Package | Notes |
|---------|---------|---------|-------|
| `go.Seq.setContext(ctx)` | `go.Seq.setContext(ctx)` | `go.Seq` | **Same** — gomobile runtime init unchanged |
| `Libv2ray.initCoreEnv(assetPath, "")` | `Libbox.setup(options)` | `io.nekohasekai.libbox.Libbox` | **Changed** — takes `SetupOptions` object with basePath, workingPath, tempPath, commandServerPort, etc. |
| `Libv2ray.checkVersionX()` | `Libbox.version()` | `io.nekohasekai.libbox.Libbox` | **Renamed** |
| `Libv2ray.newCoreController(callback)` | `CommandServer(handler, platformInterface)` | `io.nekohasekai.libbox.CommandServer` | **Major change** — no more CoreController. Uses CommandServer + CommandClient pattern with gRPC IPC |
| `CoreController.startLoop(config, tunFd)` | `CommandServer.startOrReloadService(configContent, overrideOptions)` | `io.nekohasekai.libbox.CommandServer` | **Major change** — config as string, TUN created by platform callback, not passed as fd |
| `CoreController.stopLoop()` | `CommandServer.closeService()` | `io.nekohasekai.libbox.CommandServer` | **Renamed** |
| `CoreController.isRunning` | State tracked via CommandClient status stream | | **Changed** — no direct property, use status stream |
| `CoreController.queryStats(tag, dir)` | CommandClient `WriteStatus` callback → `StatusMessage` | | **Major change** — traffic via streaming status, not polling |
| `Libv2ray.measureOutboundDelay(config, url)` | sing-box URLTest outbound group OR custom HTTP client | | **No direct equivalent** — see section 5 |
| `CoreCallbackHandler.onEmitStatus(fd)` | `PlatformInterface.autoDetectInterfaceControl(fd)` | `io.nekohasekai.libbox.PlatformInterface` | **Changed** — fd protection via platform interface |

### Critical Architecture Change: CommandServer/CommandClient Pattern

sing-box v1.13 uses a **gRPC-based command server** architecture:

1. **CommandServer** — runs in the VPN service process, manages the sing-box instance
2. **CommandClient** — connects to CommandServer to get status updates, logs, traffic stats
3. Communication is via **Unix domain socket** (file-based) or **TCP localhost port**

This is fundamentally different from libv2ray's simple `CoreController.startLoop(config, fd)` approach.

**Impact on Arma:**
- The VPN service creates a `CommandServer` and implements `PlatformInterface`
- Flutter/MainActivity uses `CommandClient` to subscribe to status and traffic streams
- TUN creation is **inverted**: sing-box calls `PlatformInterface.openTun(options)` → platform creates TUN and returns fd
- Socket protection is via `PlatformInterface.autoDetectInterfaceControl(fd)` → calls `VpnService.protect(fd)`

---

## 3. PlatformInterface Implementation (Required)

The **core integration contract** between sing-box and Android. The VPN service MUST implement this interface.

### Interface Methods (from source analysis)

```kotlin
interface PlatformInterface {
    // DNS
    fun localDNSTransport(): LocalDNSTransport?

    // Socket protection - CRITICAL for VPN
    fun usePlatformAutoDetectInterfaceControl(): Boolean  // return true
    fun autoDetectInterfaceControl(fd: Int)               // call VpnService.protect(fd)

    // TUN creation - INVERTED from libv2ray
    fun openTun(options: TunOptions): Int                 // create TUN, return fd

    // Process identification (for per-app proxy)
    fun useProcFS(): Boolean                              // true if API < 29
    fun findConnectionOwner(...): ConnectionOwner         // for per-app proxy routing

    // Network monitoring
    fun startDefaultInterfaceMonitor(listener: InterfaceUpdateListener)
    fun closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener)
    fun getInterfaces(): NetworkInterfaceIterator

    // Platform info
    fun underNetworkExtension(): Boolean                  // false on Android
    fun includeAllNetworks(): Boolean                     // false on Android
    fun readWIFIState(): WIFIState?
    fun systemCertificates(): StringIterator
    fun clearDNSCache()

    // Notifications
    fun sendNotification(notification: Notification)

    // Neighbor monitoring (for local network discovery)
    fun startNeighborMonitor(listener: NeighborUpdateListener)
    fun closeNeighborMonitor(listener: NeighborUpdateListener)

    // Interface registration
    fun registerMyInterface(name: String)
}
```

### TUN Creation is INVERTED

**Before (libv2ray):** Kotlin creates TUN → passes fd to `startLoop(config, fd)` → Xray reads TUN via env var
**After (sing-box):** sing-box calls `PlatformInterface.openTun(options)` → Kotlin creates TUN from `TunOptions` → returns fd

The `TunOptions` object provides everything sing-box wants in the TUN:
- `inet4Address`, `inet6Address` — IP addresses for the TUN interface
- `mtu` — MTU value
- `autoRoute` — whether to add default route
- `dnsServerAddress` — DNS server to configure
- `inet4RouteAddress`, `inet6RouteAddress` — specific routes
- `includePackage`, `excludePackage` — per-app proxy lists
- `isHTTPProxyEnabled`, `httpProxyServer`, `httpProxyServerPort` — HTTP proxy settings

**Key implication:** TUN configuration moves from Kotlin code into the sing-box JSON config. The `tun` inbound in the config specifies addresses, MTU, routes, per-app settings, and sing-box passes these to the platform via `openTun()`.

---

## 4. sing-box JSON Config Format (replaces Xray JSON)

### Top-Level Structure

```json
{
  "log": { "level": "debug" },
  "dns": { "servers": [...], "rules": [...] },
  "inbounds": [
    { "type": "tun", "tag": "tun-in", ... }
  ],
  "outbounds": [
    { "type": "vless", "tag": "proxy", ... },
    { "type": "direct", "tag": "direct" },
    { "type": "block", "tag": "block" }
  ],
  "route": { "rules": [...], "rule_set": [...] },
  "experimental": { "cache_file": { "enabled": true } }
}
```

### Key Differences from Xray JSON

| Aspect | Xray-core | sing-box | Impact |
|--------|-----------|----------|--------|
| **Protocol names** | `vless`, `vmess`, `trojan`, `shadowsocks` | Same names | No change |
| **Outbound structure** | `protocol` + `settings.vnext/servers` + `streamSettings` | `type` + flat fields + `tls` + `transport` | **Major rewrite** of config builder |
| **TLS config** | `streamSettings.tlsSettings` / `realitySettings` | `tls: { enabled: true, server_name, utls, reality }` | Nested under `tls` key |
| **Transport** | `streamSettings.wsSettings/grpcSettings/httpSettings` | `transport: { type: "ws"/"grpc"/"http" }` | Separate `transport` object |
| **Reality** | `streamSettings.realitySettings.publicKey` | `tls.reality.public_key` | Nested under `tls.reality` |
| **Flow (VLESS)** | `settings.vnext[0].users[0].flow` | Top-level `flow` field | Simpler |
| **uTLS fingerprint** | `streamSettings.tlsSettings.fingerprint` | `tls.utls.fingerprint` | Under `tls.utls` |
| **Fragment** | `streamSettings.sockopt.fragment` | `tls.fragment: true` + `tls.fragment_fallback_delay` | Built into TLS options |
| **Record fragment** | Not available | `tls.record_fragment: true` | New feature |
| **Mux** | `mux.enabled/concurrency` | `multiplex: { enabled, protocol, max_connections }` | Renamed, more options |
| **Routing rules** | `routing.rules[].type:"field"` + `outboundTag` | `route.rules[].action:"route"` + `outbound` | Action-based routing |
| **Geo matching** | `geoip:xx` / `geosite:xx` in rules | `geoip` / `geosite` fields OR `rule_set` | Both supported, rule_set preferred |
| **DNS** | `servers: [{address, domains}]` | `servers: [{type, tag, ...}]` with typed transports | Typed DNS servers |
| **Stats/Policy** | `stats: {}` + `policy.system.statsOutboundUplink` | `experimental.v2ray_api` or CommandServer status | Different mechanism |
| **Sniffing** | `inbounds[].sniffing.enabled` | `route.rules` with `action: "sniff"` | Moved to route rules |
| **Direct outbound** | `protocol: "freedom"` | `type: "direct"` | Renamed |
| **Block outbound** | `protocol: "blackhole"` | `type: "block"` | Renamed |
| **TUN inbound** | `protocol: "tun"` + manual MTU/name | `type: "tun"` with `address`, `auto_route`, `stack` | Much richer options |
| **IP routing** | Manual `geoip:private` rules | `tun.auto_route: true` handles it | Built-in |

### Example: VLESS + Reality + TCP (sing-box format)

```json
{
  "type": "vless",
  "tag": "proxy",
  "server": "example.com",
  "server_port": 443,
  "uuid": "xxx-xxx-xxx",
  "flow": "xtls-rprx-vision",
  "tls": {
    "enabled": true,
    "server_name": "www.example.com",
    "utls": {
      "enabled": true,
      "fingerprint": "chrome"
    },
    "reality": {
      "enabled": true,
      "public_key": "xxxxx",
      "short_id": "xxxx"
    }
  }
}
```

Compare to current Xray format (from XrayConfigBuilder):
```json
{
  "tag": "proxy",
  "protocol": "vless",
  "settings": {
    "vnext": [{
      "address": "example.com",
      "port": 443,
      "users": [{ "id": "xxx", "encryption": "none", "flow": "xtls-rprx-vision" }]
    }]
  },
  "streamSettings": {
    "network": "tcp",
    "security": "reality",
    "realitySettings": {
      "serverName": "www.example.com",
      "fingerprint": "chrome",
      "publicKey": "xxxxx",
      "shortId": "xxxx"
    }
  }
}
```

### TUN Inbound Example (sing-box)

```json
{
  "type": "tun",
  "tag": "tun-in",
  "address": [
    "172.19.0.1/30",
    "fdfe:dcba:9876::1/126"
  ],
  "mtu": 9000,
  "auto_route": true,
  "strict_route": false,
  "stack": "mixed",
  "platform": {
    "http_proxy": {
      "enabled": false
    }
  },
  "sniff": true,
  "sniff_override_destination": false
}
```

**Note:** Per-app proxy (`include_package` / `exclude_package`) can be set in the TUN inbound config OR passed via `OverrideOptions` when calling `startOrReloadService()`. The SFA reference app uses `OverrideOptions` — this is the cleaner approach since it separates config concerns from runtime concerns.

### DNS Configuration (sing-box)

```json
{
  "dns": {
    "servers": [
      {
        "type": "https",
        "tag": "remote-dns",
        "server": "1.1.1.1",
        "path": "/dns-query"
      },
      {
        "type": "local",
        "tag": "local-dns"
      }
    ],
    "rules": [
      {
        "outbound": ["direct"],
        "server": "local-dns"
      }
    ]
  }
}
```

### Routing Rules (sing-box)

```json
{
  "route": {
    "rules": [
      {
        "ip_is_private": true,
        "action": "bypass"
      },
      {
        "geoip": ["ir"],
        "action": "route",
        "outbound": "direct"
      },
      {
        "geosite": ["category-ir"],
        "action": "route",
        "outbound": "direct"
      },
      {
        "domain_suffix": [".ir"],
        "action": "route",
        "outbound": "direct"
      }
    ],
    "auto_detect_interface": true
  }
}
```

**Key difference:** sing-box uses `action`-based rules. The `"bypass"` action replaces `geoip:private` → direct patterns. The `auto_detect_interface: true` replaces manual server address bypass rules.

### Geo Assets: .dat → rule_set (migration path)

sing-box still supports `geoip` and `geosite` fields in rules (with `geoip.dat` / `geosite.dat` from sing-geoip/sing-geosite repos), but the **preferred** approach is `rule_set` with `.srs` binary format files. For the migration, keep using `geoip`/`geosite` — it's the fastest path.

**Asset files needed:**
- `geoip.dat` from https://github.com/SagerNet/sing-geoip (NOT v2fly/geoip)
- `geosite.dat` from https://github.com/SagerNet/sing-geosite (NOT v2fly/domain-list-community)

⚠️ **CRITICAL:** sing-box uses its OWN geo format, not v2fly format. The existing `geoip.dat`/`geosite.dat` from Xray assets are INCOMPATIBLE. Must download sing-box-specific ones.

---

## 5. Latency Testing

### Current Approach (Xray)

```kotlin
// Static method — no running instance needed
val delay = Libv2ray.measureOutboundDelay(config, url)
```

### sing-box Approach

sing-box does NOT have a direct `measureOutboundDelay` static method. Options:

**Option A: URLTest outbound group** (in-config approach)
Configure a `urltest` outbound group in the config. sing-box will periodically test latency. Results available via CommandClient `WriteGroups` callback with `OutboundGroupItem.URLTestDelay`.

**Option B: Custom Go wrapper** (matches current UX)
Build a thin Go wrapper that creates a temporary sing-box instance, runs a URL test, and returns the delay. This is what Hiddify does.

**Option C: HTTP through SOCKS** (simpler, no core dependency)
Start a temporary sing-box with a SOCKS inbound, then use Dart/Kotlin HTTP client through the SOCKS proxy to measure latency.

**Recommendation: Option A for connected state, Option C for disconnected pre-connect testing.**

For bulk latency testing of the server list (when not connected), the cleanest approach is:
1. Generate a sing-box config with a `socks` inbound (e.g., port 10808)
2. Start a temporary instance
3. Make HTTP request through SOCKS to `https://www.google.com/generate_204`
4. Measure round-trip time
5. Stop instance

This avoids needing a custom Go wrapper and keeps the Dart side in control.

---

## 6. Traffic Monitoring

### Current Approach (Xray)

```kotlin
// Poll every 1 second — returns cumulative bytes since last call (reset-on-read)
val up = controller.queryStats("proxy", "uplink")
val down = controller.queryStats("proxy", "downlink")
```

### sing-box Approach

Traffic stats come via the **CommandClient status stream**:

```kotlin
// CommandClientHandler callback
override fun writeStatus(message: StatusMessage) {
    // message.uplink      — bytes/sec upload
    // message.downlink    — bytes/sec download
    // message.uplinkTotal — total bytes uploaded
    // message.downlinkTotal — total bytes downloaded
    // message.trafficAvailable — whether stats are available
    // message.memory      — Go runtime memory usage
    // message.goroutines  — active goroutine count
    // message.connectionsIn / connectionsOut — connection counts
}
```

The `StatusMessage` is richer than Xray's simple `queryStats`. It provides:
- Per-second traffic rates (uplink/downlink)
- Cumulative totals
- Memory usage
- Connection counts
- No manual polling needed — it's a gRPC stream

**Setup requires:**
```kotlin
val options = CommandClientOptions()
options.addCommand(CommandStatus)  // Subscribe to status updates
options.statusInterval = 1000     // 1 second interval

val client = CommandClient(handler, options)
client.connect()
```

---

## 7. What Code Changes and What Stays

### Stays Unchanged (Dart side)

| Component | Why |
|-----------|-----|
| Share link parsers (vless, vmess, trojan, ss, hysteria2) | Parse to `ServerConfig` entity — engine-independent |
| Subscription parser | Downloads and decodes share links — engine-independent |
| Server list UI | Displays `ServerConfig` entities |
| Settings UI | User preferences storage (Hive) |
| Routing rule UI | Domain rules stored as app entities |
| Per-app proxy UI | Package list + mode selection |
| Theme, navigation, localization | Pure Flutter |
| `ServerConfig` entity | Internal model — stays the same |
| `VpnSettings` entity | Internal model — stays the same |
| All Riverpod providers | State management stays the same |
| Hive storage | Persistence layer unchanged |

### Must Rewrite (Dart side)

| Component | Current | New | Effort |
|-----------|---------|-----|--------|
| `XrayConfigBuilder` | Builds Xray JSON from `ServerConfig` | `SingBoxConfigBuilder` — builds sing-box JSON from `ServerConfig` | **HIGH** — complete rewrite, ~500 lines |
| `VpnPlatformService.measureDelay()` | Calls `Libv2ray.measureOutboundDelay` | New approach (see section 5) | **MEDIUM** |

### Must Rewrite (Kotlin side)

| Component | Current | New | Effort |
|-----------|---------|-----|--------|
| `XrayCoreManager` | Wraps `Libv2ray.initCoreEnv` + `CoreController` | `SingBoxManager` — wraps `Libbox.setup()` + `CommandServer` | **HIGH** — different init pattern |
| `ArmaVpnService` | Creates TUN, passes fd to `startLoop` | Implements `PlatformInterface`, TUN created on callback | **HIGH** — architecture inversion |
| `TrafficMonitor` | Polls `queryStats` every 1s | Uses `CommandClient` status stream | **MEDIUM** — simpler but different |
| `MainActivity.measureDelay` | Calls `Libv2ray.measureOutboundDelay` | New approach (see section 5) | **MEDIUM** |
| `VpnServiceConnection` (IPC) | Custom Messenger IPC | May simplify — CommandServer handles more | **MEDIUM** |

### Must Replace (Assets)

| Asset | Current | New |
|-------|---------|-----|
| `android/app/libs/libv2ray.aar` | Xray-core Go-Mobile AAR | `libbox.aar` from sing-box build |
| `android/app/src/main/assets/geoip.dat` | v2fly geoip format | sing-geoip format (different!) |
| `android/app/src/main/assets/geosite.dat` | v2fly geosite format | sing-geosite format (different!) |

---

## 8. Setup / Initialization Pattern

### Current (Xray)

```kotlin
// In VPN service onCreate
XrayCoreManager.initialize(context)
// 1. go.Seq.setContext(context)
// 2. Copy geoip.dat/geosite.dat to internal storage
// 3. Libv2ray.initCoreEnv(assetPath, "")
```

### New (sing-box)

```kotlin
// In VPN service onCreate
go.Seq.setContext(context.applicationContext)

val setupOptions = SetupOptions().apply {
    basePath = context.filesDir.absolutePath
    workingPath = File(context.filesDir, "sing-box").absolutePath
    tempPath = File(context.cacheDir, "sing-box-tmp").absolutePath
    fixAndroidStack = true  // Workaround for Go issue #68760
    commandServerListenPort = 0  // Use Unix domain socket (not TCP)
    commandServerSecret = ""
    debug = BuildConfig.DEBUG
    crashReportSource = "service"
}

Libbox.setup(setupOptions)
```

**Key differences:**
1. `Setup()` replaces `initCoreEnv()` — takes a structured options object
2. Working/temp directories must be created
3. `fixAndroidStack = true` is needed for Android (Go goroutine stack issue)
4. Command server port configuration — `0` means Unix socket
5. Geo assets are loaded by sing-box from the working directory (not a separate path)

---

## 9. CommandServer Lifecycle

### Service Start Flow

```kotlin
// 1. Create CommandServer with PlatformInterface
val commandServer = CommandServer(this /* CommandServerHandler */, this /* PlatformInterface */)

// 2. Start the gRPC command server
commandServer.start()

// 3. Start or reload the sing-box service with config
commandServer.startOrReloadService(
    configJson,
    OverrideOptions().apply {
        // Per-app proxy settings passed here
        if (isWhitelistMode) {
            includePackage = StringArray(allowedApps.iterator())
        } else {
            excludePackage = StringArray(blockedApps.iterator())
        }
    }
)
```

### Service Stop Flow

```kotlin
// 1. Close the sing-box service (stops proxy)
commandServer.closeService()

// 2. Close the command server (stops gRPC)
commandServer.close()

// 3. Close TUN fd (if still open)
fileDescriptor?.close()
```

### CommandServerHandler Interface

```kotlin
interface CommandServerHandler {
    fun serviceStop()        // Called by sing-box when it wants to stop
    fun serviceReload()      // Called when config reload is requested
    fun getSystemProxyStatus(): SystemProxyStatus?
    fun setSystemProxyEnabled(enabled: Boolean)
    fun writeDebugMessage(message: String)
}
```

---

## 10. Supported Protocols Verification

| Protocol | Xray-core | sing-box | Notes |
|----------|-----------|----------|-------|
| VLESS | ✅ | ✅ | Same support, including XTLS Vision flow |
| VLESS + Reality | ✅ | ✅ | `tls.reality` in sing-box |
| VMess | ✅ | ✅ | Same, with `alter_id` support |
| Trojan | ✅ | ✅ | Same |
| Shadowsocks | ✅ | ✅ | Same methods supported |
| Hysteria2 | ✅ | ✅ | Native in sing-box (it's the origin) |
| SOCKS/HTTP | ✅ | ✅ | As inbound types |
| WebSocket transport | ✅ | ✅ | `transport.type: "ws"` |
| gRPC transport | ✅ | ✅ | `transport.type: "grpc"` |
| H2 transport | ✅ | ✅ | `transport.type: "http"` |
| HTTPUpgrade transport | ❌ | ✅ | **New** in sing-box |
| TLS fingerprinting (uTLS) | ✅ | ✅ | `tls.utls.fingerprint` |
| TLS fragment | ✅ | ✅ | `tls.fragment: true` (built-in, not sockopt) |
| Record fragment | ❌ | ✅ | **New** — `tls.record_fragment: true` |
| Mux/Multiplex | ✅ | ✅ | `multiplex` with more options |
| QUIC transport | ❌ | ✅ | **New** |
| WireGuard | ❌ | ✅ | **New** (with `with_wireguard` build tag) |
| TUIC | ❌ | ✅ | **New** |
| Naive | ❌ | ✅ | **New** (with `with_naive_outbound` build tag) |

**All existing protocols are supported.** sing-box adds more protocols beyond what Xray-core offers.

---

## 11. Anti-Censorship Feature Mapping

| Feature | Xray Implementation | sing-box Implementation | Confidence |
|---------|---------------------|------------------------|------------|
| TLS Fragment | `sockopt.fragment.packets:"tlshello"` | `tls.fragment: true` | HIGH |
| Fragment length/interval | `sockopt.fragment.length/interval` | `tls.fragment_fallback_delay` (auto-managed) | MEDIUM — less granular control |
| Record Fragment | Not available | `tls.record_fragment: true` | HIGH — new feature |
| uTLS Fingerprint | `streamSettings.tlsSettings.fingerprint` | `tls.utls.fingerprint` | HIGH |
| Reality | `streamSettings.realitySettings` | `tls.reality` | HIGH |
| Mux | `mux.enabled/concurrency` | `multiplex.enabled/max_connections/protocol` | HIGH — more options |
| Mixed SNI | Custom implementation | Can use selector outbound group | MEDIUM |

⚠️ **Fragment control granularity:** Xray allows `length: "10-100"` and `interval: "0-5"` for precise fragment control. sing-box's `tls.fragment` is a boolean — the engine decides fragmentation strategy. `tls.fragment_fallback_delay` controls the fallback to non-fragmented if fragmented fails. This is less configurable but may be more reliable. **Users who need precise fragment control will lose that granularity.**

---

## 12. Migration Dependency Graph

```
1. Build libbox.aar                    [BLOCKING - everything depends on this]
     ↓
2. Replace geo assets                  [Can parallel with 3]
     ↓
3. SingBoxConfigBuilder (Dart)         [Can parallel with 4-6]
   - TUN inbound format
   - Outbound format per protocol
   - DNS format
   - Route rules format
     ↓
4. SingBoxManager (Kotlin)             [Depends on 1]
   - Setup() initialization
   - CommandServer creation
     ↓
5. PlatformInterface impl (Kotlin)     [Depends on 1, 4]
   - openTun()
   - autoDetectInterfaceControl()
   - Network monitoring
     ↓
6. ArmaVpnService rewrite (Kotlin)     [Depends on 4, 5]
   - Start/stop using CommandServer
   - TUN callback pattern
     ↓
7. Traffic monitoring (Kotlin)         [Depends on 6]
   - CommandClient status stream
     ↓
8. Latency testing                     [Depends on 3]
   - New approach (SOCKS + HTTP)
     ↓
9. IPC updates                         [Depends on 6, 7]
   - MainActivity ↔ VPN service bridge
     ↓
10. Integration testing                [Depends on all above]
```

---

## 13. Alternatives Considered

| Decision | Chosen | Alternative | Why Not |
|----------|--------|-------------|---------|
| Build libbox from source | ✅ | Extract from SFA APK | Need control over build tags and minSdk |
| Keep geo .dat files | ✅ | Migrate to rule_set .srs | Migration path simpler, can migrate to rule_set later |
| CommandServer pattern | ✅ (required) | Fork libbox for simpler API | Massive maintenance burden, not sustainable |
| Latency via SOCKS | ✅ | Custom Go wrapper | Avoids Go build complexity, Dart controls test |
| Unix socket for CommandServer | ✅ | TCP localhost port | More secure, SFA reference uses it |

---

## Sources

- **sing-box source code** (testing branch, default): `github.com/SagerNet/sing-box` — v1.13.6 (April 6, 2026)
  - `experimental/libbox/` — all Go API surface files
  - `option/` — all JSON config option structs
  - `constant/proxy.go` — protocol type constants
  - `cmd/internal/build_libbox/main.go` — Android AAR build script
  - `Makefile` — build targets and gomobile version
- **SFA reference app**: `github.com/SagerNet/sing-box-for-android` (dev branch)
  - `BoxService.kt` — CommandServer lifecycle
  - `VPNService.kt` — TUN creation via PlatformInterface
  - `PlatformInterfaceWrapper.kt` — full interface implementation
- **Hiddify reference app**: `github.com/hiddify/hiddify-app` (main branch)
  - `MethodHandler.kt` — Flutter ↔ sing-box bridge pattern
  - `build.gradle` — dependency configuration
- **Confidence:** All findings verified against actual source code, not documentation or training data.
