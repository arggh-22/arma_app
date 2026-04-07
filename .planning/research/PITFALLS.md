# Domain Pitfalls — sing-box Engine Migration (v1.1)

**Domain:** Xray-core → sing-box migration in Flutter VPN Client (Android)
**Researched:** 2025-07-19
**Milestone:** v1.1 sing-box Engine Migration
**Overall confidence:** HIGH (verified against sing-box source code on `testing` branch, libbox Go API, official documentation, and line-by-line comparison with existing Arma v1.0 codebase)

**Sources:**
- sing-box official docs: `sing-box.sagernet.org/configuration/` — configuration schema, migration guides
- SagerNet/sing-box GitHub (`testing` branch): `experimental/libbox/` — service.go, platform.go, tun.go, config.go, setup.go, command_server.go, command_client.go
- sing-box `docs/migration.md` — official breaking changes log (1.8.0 → 1.14.0)
- Existing Arma v1.0 codebase: XrayConfigBuilder.dart, ArmaVpnService.kt, XrayCoreManager.kt, TrafficMonitor.kt, VpnServiceConnection.kt
- Hiddify (Flutter + sing-box reference): architecture patterns for libbox integration

**Note:** v1.0 pitfalls (VPN shutdown order, Go-Mobile build fragility, VPN permission flow, foreground service type, DNS leak, etc.) remain relevant and are preserved in `PITFALLS_v1.md`. This document covers **migration-specific** risks only.

---

## Critical Pitfalls

Mistakes that cause rewrites, broken migrations, or total loss of functionality.

---

### Pitfall 1: Config JSON Format Is Completely Incompatible — Zero Reuse of XrayConfigBuilder

**Severity:** CRITICAL | **Likelihood:** CERTAIN | **Confidence:** HIGH

**What goes wrong:** The entire `XrayConfigBuilder` class (543 lines) produces Xray-core JSON that sing-box will reject. Every single top-level key, every nested field name, and the overall structure are different. Developers who try to incrementally modify the existing config builder will waste days finding silent failures.

**Why it happens:** Xray-core and sing-box are independent projects with completely different configuration schemas. There is no shared format.

**Key structural differences (verified against sing-box docs):**

| Concept | Xray-core (current) | sing-box (target) |
|---------|---------------------|-------------------|
| Outbound wrapper | `vnext[]/servers[]` → `settings: {vnext: [{address, port, users: [{id, encryption}]}]}` | Flat: `{server, server_port, uuid, ...}` |
| Protocol field | `outbound.protocol: "vless"` | `outbound.type: "vless"` |
| TLS config | `streamSettings.tlsSettings: {serverName, fingerprint, alpn}` | `tls: {enabled: true, server_name, utls: {fingerprint}, alpn}` |
| Reality config | `streamSettings.realitySettings: {publicKey, shortId}` | `tls: {enabled: true, reality: {enabled: true, public_key, short_id}}` |
| Transport | `streamSettings.wsSettings: {path, headers: {Host}}` | `transport: {type: "ws", path, headers: {Host}}` |
| Direct outbound | `{protocol: "freedom", settings: {}}` | `{type: "direct"}` |
| Block outbound | `{protocol: "blackhole", settings: {response: {type: "http"}}}` | `{type: "block"}` |
| TUN inbound | `{protocol: "tun", settings: {name, MTU}}` | `{type: "tun", interface_name, mtu, address: ["172.18.0.1/30"], auto_route: true}` |
| Sniffing | `inbound.sniffing: {enabled, destOverride: ["http","tls"]}` | Top-level route `sniff: true` or inbound `sniff: true` |
| Routing rules | `{type: "field", outboundTag: "direct", domain: ["geosite:cn"]}` | `{domain_suffix: [".cn"], action: "route", outbound: "direct"}` or via `rule_set` |
| DNS | `dns.servers: [{address: "https://1.1.1.1/dns-query", domains: []}]` | `dns.servers: [{type: "https", tag: "remote", server: "1.1.1.1"}]` |
| Stats | `stats: {}, policy: {system: {statsOutboundUplink: true}}` | `experimental: {v2ray_api: {listen, stats: {outbounds: ["proxy"]}}}` or Clash API |
| Fragment | `streamSettings.sockopt.fragment: {packets: "tlshello", length, interval}` | `tls: {fragment: true, fragment_fallback_delay: "500ms"}` (since 1.12.0) |

**Consequences:** Complete rewrite of config generation. No incremental migration path — you must build `SingboxConfigBuilder` from scratch.

**Prevention:**
1. Create a **new** `SingboxConfigBuilder` class. Do NOT modify `XrayConfigBuilder`.
2. Keep `XrayConfigBuilder` intact for rollback capability.
3. Build the new config builder protocol-by-protocol with tests against sing-box's `CheckConfig()` API.
4. Use sing-box's `FormatConfig()` to validate and pretty-print generated configs during development.

**Detection:** Feed any Xray JSON config to sing-box — it will fail with parse errors immediately.

---

### Pitfall 2: libbox API Is Fundamentally Different From libv2ray — New Integration Architecture Required

**Severity:** CRITICAL | **Likelihood:** CERTAIN | **Confidence:** HIGH

**What goes wrong:** The entire Kotlin native layer (`XrayCoreManager`, `ArmaVpnService`, `TrafficMonitor`, `ServiceConnection`) is built around libv2ray's API: `Libv2ray.initCoreEnv()`, `Libv2ray.newCoreController(callback)`, `controller.startLoop(config, tunFd)`, `controller.queryStats()`. sing-box's libbox has a completely different architecture — it doesn't take a TUN fd, it doesn't have `startLoop`, and it doesn't have `queryStats`.

**libv2ray API (current — from XrayCoreManager.kt + ArmaVpnService.kt):**
```kotlin
// Init
go.Seq.setContext(context)
Libv2ray.initCoreEnv(assetPath, "")

// Start
val controller = Libv2ray.newCoreController(callback) // callback.onEmitStatus(fd) for socket protection
controller.startLoop(configJson, tunFd)  // Pass TUN fd directly

// Stats
controller.queryStats("proxy", "uplink")  // Direct polling

// Stop
controller.stopLoop()
```

**libbox API (target — from service.go, platform.go, config.go, setup.go):**
```kotlin
// Init
val setupOptions = SetupOptions().apply {
    basePath = context.filesDir.absolutePath
    workingPath = "${context.filesDir}/sing-box"
    tempPath = "${context.cacheDir}/sing-box"
    // ...
}
Libbox.setup(setupOptions)

// Start — CommandServer + PlatformInterface pattern
val commandServer = Libbox.newCommandServer(handler, platformInterface)
// platformInterface.openTun() is CALLED BY sing-box, not passed TO it
// sing-box manages the config file, not a config string + fd

// Stats — via CommandClient gRPC subscription
val commandClient = Libbox.newCommandClient(handler, options)
// handler.writeStatus(statusMessage) // Pushed, not polled

// Stop — via CommandServer
commandServer.stop()
```

**Key architectural inversion:** Xray-core receives a TUN fd from you. sing-box calls YOUR `PlatformInterface.OpenTun()` to request a TUN from the OS. This inverts the control flow of the entire VPN service.

**Consequences:** `XrayCoreManager.kt` → complete rewrite. `ArmaVpnService.kt` → heavy restructuring of TUN creation flow. `TrafficMonitor.kt` → replaced by CommandClient subscription model.

**Prevention:**
1. Study Hiddify's Android integration layer (or SFA — sing-box for Android official client) as reference.
2. Implement `PlatformInterface` in Kotlin that handles `OpenTun`, `AutoDetectInterfaceControl` (socket protection), `StartDefaultInterfaceMonitor` (network changes).
3. The config is passed as a string to `CommandServer`, NOT with a TUN fd. sing-box internally calls your `OpenTun` when it needs the TUN.
4. Traffic stats come via `CommandClient` + `CommandClientHandler.WriteStatus()`, not polling.

**Detection:** Any attempt to call `startLoop(config, tunFd)` will fail at compile time — the method doesn't exist.

---

### Pitfall 3: Geo Data Format Change — geoip.dat/geosite.dat Removed, Rule-Sets Required

**Severity:** CRITICAL | **Likelihood:** CERTAIN | **Confidence:** HIGH

**What goes wrong:** The existing routing rules use Xray-core's `geoip:private`, `geosite:cn`, `geosite:category-ir`, `geoip:ir`, `geoip:ru`, etc. sing-box deprecated geoip/geosite in v1.8.0 (still available) and **removed** them in v1.12.0. The current latest stable is 1.11.x, but the testing branch (which will be released) has removed them entirely.

**Current codebase impact (from XrayConfigBuilder._buildRouting):**
```dart
// These WILL NOT WORK in sing-box 1.12+
rules.add({'type': 'field', 'outboundTag': 'direct', 'ip': ['geoip:private']});
rules.add({'type': 'field', 'outboundTag': 'direct', 'domain': ['geosite:category-ir']});
rules.add({'type': 'field', 'outboundTag': 'direct', 'ip': ['geoip:ir']});
rules.add({'type': 'field', 'outboundTag': 'direct', 'domain': ['geosite:cn']});
```

**sing-box replacement — rule-sets:**
```json
{
  "route": {
    "rule_set": [
      {
        "type": "remote",
        "tag": "geoip-ir",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ir.srs"
      },
      {
        "type": "remote",
        "tag": "geosite-ir",
        "format": "binary",
        "url": "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ir.srs"
      }
    ],
    "rules": [
      {"rule_set": ["geoip-ir", "geosite-ir"], "action": "route", "outbound": "direct"}
    ]
  }
}
```

**Consequences:**
- All region presets (Iran, China, Russia) must be reimplemented with rule-sets.
- No more bundled `.dat` files in APK assets — either use remote rule-sets (requires network on first launch) or bundle `.srs` binary files.
- The `copyAssetsToInternal()` pattern in `XrayCoreManager.kt` for geoip.dat/geosite.dat becomes irrelevant.
- LAN bypass (`geoip:private`) becomes `ip_is_private: true` in sing-box route rules.

**Prevention:**
1. **For LAN bypass:** Use `"ip_is_private": true` in route rules (no rule-set needed).
2. **For region presets:** Use remote rule-sets from `github.com/SagerNet/sing-geoip` and `sing-geosite`. Cache via `experimental.cache_file.enabled: true`.
3. **Bundle fallback .srs files** in APK assets for offline-first experience (users in censored regions may not have internet on first launch without VPN).
4. **sing-box 1.10+ supports inline rule-sets** — for simple rules, embed directly in config.

**Detection:** Any config using `geoip:` or `geosite:` prefix will fail with "unknown rule type" on sing-box 1.12+.

---

### Pitfall 4: TLS Fragment Anti-Censorship Has Different Behavior and Fewer Options

**Severity:** CRITICAL | **Likelihood:** HIGH | **Confidence:** HIGH

**What goes wrong:** The app's anti-censorship features (fragment, padding, mixed SNI) are critical for users in Iran/China/Russia. The Xray-core fragment implementation in `XrayConfigBuilder._buildStreamSettings()` uses `sockopt.fragment` with configurable `packets` (tlshello), `length` (min-max range), and `interval` (sleep min-max). sing-box's TLS fragment (added in 1.12.0) is a much simpler boolean flag with auto-detection and limited control.

**Current Xray-core fragment (from XrayConfigBuilder):**
```json
{
  "sockopt": {
    "fragment": {
      "packets": "tlshello",
      "length": "10-100",
      "interval": "0-0"
    }
  }
}
```
Users can fine-tune `fragmentMin`, `fragmentMax`, `sleepMin`, `sleepMax` in Settings.

**sing-box TLS fragment (from docs):**
```json
{
  "tls": {
    "fragment": true,
    "fragment_fallback_delay": "500ms",
    "record_fragment": false
  }
}
```
- `fragment: true` — fragments TLS handshakes, with **auto-detected** wait times on Linux/Apple/Windows.
- `record_fragment: true` — splits into multiple TLS records (alternative approach).
- `fragment_fallback_delay` — only used when auto-detection fails (Android falls into this category since auto-detection is listed for "Linux, Apple platforms, Windows" only).
- **No min/max length control.** No interval control. No packet type selection.

**Additional anti-censorship gaps:**
- **Padding:** Xray's mux padding vs sing-box's multiplex padding — different implementation. sing-box mux uses smux/yamux/h2mux protocols with optional `"padding": true`.
- **Mixed SNI:** This is a client-side technique not natively supported by sing-box. Would need custom implementation.

**Consequences:** Users who rely on fine-tuned fragment settings for their specific network environment (common in Iran) may find sing-box's simpler fragment insufficient. This could be a migration blocker for the Iran user segment.

**Prevention:**
1. **Test fragment in target regions** before fully committing to migration. Deploy a test build.
2. Use `record_fragment: true` as an alternative — it may work better for some censorship patterns.
3. The `fragment_fallback_delay` value is the main tuning knob on Android. Expose it in Settings.
4. Keep the Settings UI simpler: instead of min/max/sleep, offer "Fragment: On/Off" + "Delay: Fast/Medium/Slow" presets.
5. For mixed SNI / advanced padding: these may require a custom sing-box build or fork. Evaluate if the user base actually depends on these features before blocking migration.
6. **Fallback plan:** Keep libv2ray.aar as a selectable engine for users who need Xray's advanced fragment options.

**Detection:** Test with a server behind GFW/Iran DPI. If connections that worked with Xray-core fail with sing-box, the fragment implementation difference is the likely cause.

---

### Pitfall 5: Traffic Stats Mechanism Completely Different — QueryStats Polling Doesn't Exist

**Severity:** CRITICAL | **Likelihood:** CERTAIN | **Confidence:** HIGH

**What goes wrong:** The current `TrafficMonitor.kt` polls `controller.queryStats("proxy", "uplink")` every second. This pattern doesn't exist in sing-box. The `v2ray_api` stats module exists in sing-box but is **not included by default** (requires `with_v2ray_api` build tag) and uses a gRPC server, not direct Go function calls.

**Current implementation (TrafficMonitor.kt):**
```kotlin
val up = controller.queryStats("proxy", "uplink")   // Direct Go call
val down = controller.queryStats("proxy", "downlink") // Resets counter on read
```

**sing-box options for traffic stats:**

**Option A: Clash API (default, included)**
```json
{
  "experimental": {
    "clash_api": {
      "external_controller": "127.0.0.1:9090"
    }
  }
}
```
Then HTTP GET `http://127.0.0.1:9090/traffic` for real-time traffic stream. This opens a local port.

**Option B: V2Ray API (requires build tag)**
```json
{
  "experimental": {
    "v2ray_api": {
      "listen": "127.0.0.1:8080",
      "stats": {
        "enabled": true,
        "outbounds": ["proxy", "direct"]
      }
    }
  }
}
```
gRPC-based, also opens a local port.

**Option C: libbox CommandClient (recommended for mobile)**
The `CommandClient` connects to `CommandServer` and receives status updates via gRPC streaming. This is the pattern used by SFA (sing-box for Android) and Hiddify.

```kotlin
val handler = object : CommandClientHandler {
    override fun writeStatus(message: StatusMessage) {
        // message contains uplink/downlink traffic
    }
}
val options = CommandClientOptions().apply {
    statusInterval = 1000 // ms
    addCommand(CommandStatus)
}
val client = Libbox.newCommandClient(handler, options)
client.connect() // Connects to CommandServer via Unix socket
```

**Consequences:** The entire `TrafficMonitor` class is obsolete. The dashboard's real-time speed display needs a different data source. The stats polling model becomes an event-driven subscription model.

**Prevention:**
1. Use the **CommandClient/CommandServer** pattern (Option C) — it's the native libbox approach.
2. `CommandServer` runs in the VPN process, `CommandClient` connects from the Flutter process.
3. The `StatusMessage` contains traffic data that can be forwarded to Dart via EventChannel.
4. The `CommandServerListenPort` is configured in `SetupOptions`, not in the sing-box JSON config.

**Detection:** Any attempt to call `queryStats` will fail — the method doesn't exist on any sing-box object.

---

## Major Pitfalls

Mistakes that cause significant rework but don't block the entire migration.

---

### Pitfall 6: Socket Protection Callback Changes — AutoDetectInterfaceControl vs onEmitStatus

**Severity:** HIGH | **Likelihood:** CERTAIN | **Confidence:** HIGH

**What goes wrong:** Xray-core uses `CoreCallbackHandler.onEmitStatus(fd)` to request socket protection from the VPN service. The existing `ArmaVpnService` calls `vpnService.protect(fd.toInt())` in this callback. sing-box uses `PlatformInterface.AutoDetectInterfaceControl(fd)` instead, plus `auto_detect_interface: true` in route config.

**Current implementation (ArmaVpnService.kt lines 198-210):**
```kotlin
val callback = object : CoreCallbackHandler {
    override fun onEmitStatus(p0: Long, p1: String?): Long {
        if (p0 > 0) {
            val protected = vpnService.protect(p0.toInt())
            return if (protected) 0L else 1L
        }
        return 0L
    }
}
```

**sing-box equivalent (PlatformInterface):**
```kotlin
class MyPlatformInterface : PlatformInterface {
    override fun autoDetectInterfaceControl(fd: Int): Boolean {
        return vpnService.protect(fd)
    }
    override fun usePlatformAutoDetectInterfaceControl(): Boolean = true
    // ... many other required methods
}
```

**The PlatformInterface has 15+ required methods**, not just socket protection:
- `openTun(options: TunOptions): Int` — create TUN and return fd
- `startDefaultInterfaceMonitor(listener: InterfaceUpdateListener)` — network change monitoring
- `closeDefaultInterfaceMonitor(listener: InterfaceUpdateListener)`
- `getInterfaces(): NetworkInterfaceIterator` — enumerate network interfaces
- `findConnectionOwner(...)` — process identification
- `useProcFS(): Boolean`
- `readWIFIState(): WIFIState`
- `systemCertificates(): StringIterator`
- `clearDNSCache()`
- `sendNotification(notification: Notification)`
- `underNetworkExtension(): Boolean` (iOS)
- `includeAllNetworks(): Boolean` (iOS)
- `localDNSTransport(): LocalDNSTransport`
- `registerMyInterface(name: String)`
- `startNeighborMonitor/closeNeighborMonitor`

**Consequences:** Implementing PlatformInterface is a large surface area. Missing or incorrect implementations cause runtime crashes in the Go layer with minimal error messages.

**Prevention:**
1. Study SFA (sing-box for Android) source code for the canonical PlatformInterface implementation.
2. Implement methods incrementally — start with the essential ones: `openTun`, `autoDetectInterfaceControl`, `usePlatformAutoDetectInterfaceControl`, `startDefaultInterfaceMonitor`, `getInterfaces`.
3. Stub the rest (iOS-specific methods like `underNetworkExtension` return false, etc.).
4. **The route config must include `"auto_detect_interface": true`** for socket protection to work.

---

### Pitfall 7: V2Ray Transport Differences — No TCP, No mKCP, WebSocket Compatibility

**Severity:** HIGH | **Likelihood:** HIGH | **Confidence:** HIGH

**What goes wrong:** sing-box's V2Ray transport layer has explicit differences from Xray-core's implementation, documented in the sing-box source:

1. **No TCP transport** — "plain HTTP is merged into the HTTP transport." The current `XrayConfigBuilder` generates `tcpSettings` blocks — these don't exist in sing-box.
2. **No mKCP transport** — removed entirely. If any imported configs use mKCP, they'll fail silently.
3. **No DomainSocket transport** — removed.
4. **WebSocket early data** — to be compatible with Xray-core, `early_data_header_name` must be set to `"Sec-WebSocket-Protocol"`. Default is path-based (incompatible with Xray servers).
5. **gRPC** — "standard gRPC" (with full gRPC library) is **not included by default**. The built-in gRPC is a lightweight custom implementation. May have compatibility issues with some servers.
6. **HTTP transport** — TLS is NOT enforced (unlike Xray's `h2` which forces TLS). Must explicitly add TLS config.

**Current code impact (XrayConfigBuilder._buildStreamSettings):**
```dart
case 'tcp':
  settings['tcpSettings'] = {'header': {'type': 'none'}};  // NO EQUIVALENT in sing-box
case 'h2':
  settings['httpSettings'] = {'host': [...], 'path': ...};  // Different field name
```

**sing-box transport mapping:**
```json
// TCP with no header → just omit transport (sing-box defaults to raw TCP)
// TCP with HTTP header → use transport type: "http"
// WS → transport type: "ws" (mostly compatible)
// gRPC → transport type: "grpc" (lightweight implementation)
// H2 → transport type: "http" with TLS enabled
```

**Prevention:**
1. **TCP:** If `network == "tcp"` and no special header, omit the `transport` field entirely.
2. **WS:** Map `wsSettings.path` → `transport.path`, `wsSettings.headers.Host` → `transport.headers.Host`. Add `early_data_header_name: "Sec-WebSocket-Protocol"` for Xray server compatibility.
3. **gRPC:** Map `grpcSettings.serviceName` → `transport.service_name`. Note: `authority` field mapping may differ.
4. **H2:** Map to `transport: {type: "http"}` + ensure `tls.enabled: true`.
5. **Test all transport types** against Xray-core servers (which is what users' servers run).

---

### Pitfall 8: DNS Configuration Restructured — Legacy Format Removed in 1.14.0

**Severity:** HIGH | **Likelihood:** HIGH | **Confidence:** HIGH

**What goes wrong:** The current split-DNS pattern in `XrayConfigBuilder._buildDns()` uses a flat array format:
```json
{
  "dns": {
    "servers": [
      {"address": "https://1.1.1.1/dns-query", "domains": [], "port": 53},
      "localhost"
    ]
  }
}
```

sing-box 1.12+ requires typed DNS server objects:
```json
{
  "dns": {
    "servers": [
      {"type": "https", "tag": "remote-dns", "server": "1.1.1.1"},
      {"type": "local", "tag": "local-dns"}
    ],
    "rules": [
      {"outbound": "direct", "server": "local-dns"},
      {"action": "route", "server": "remote-dns"}
    ]
  }
}
```

**Key differences:**
- DNS servers have `type` field: `local`, `udp`, `tcp`, `tls`, `https`, `quic`, `h3`
- DNS routing is via `dns.rules`, separate from route rules
- DoH: `address: "https://1.1.1.1/dns-query"` → `type: "https", server: "1.1.1.1"`
- DoT: `address: "tls://1.1.1.1"` → `type: "tls", server: "1.1.1.1"`
- Plain: `address: "1.1.1.1"` → `type: "udp", server: "1.1.1.1"`
- `localhost` → `type: "local"`
- Domain-resolver chaining replaces `address_resolver` in 1.12+

**Prevention:**
1. Parse `VpnSettings.dnsProtocol` and `remoteDns`/`directDns` into sing-box's typed server format.
2. Create DNS rules to route queries: direct DNS for domestic domains, remote DNS via proxy for everything else.
3. The `domain_resolver` field in Dial Fields is required when DNS server addresses contain domain names.

---

### Pitfall 9: Mux/Multiplex Implementation Differs — Protocol Selection Required

**Severity:** MEDIUM | **Likelihood:** HIGH | **Confidence:** HIGH

**What goes wrong:** The current `XrayConfigBuilder` adds mux as:
```json
{"mux": {"enabled": true, "concurrency": 4}}
```

sing-box's multiplex requires a `protocol` field and has different semantics:
```json
{
  "multiplex": {
    "enabled": true,
    "protocol": "h2mux",
    "max_connections": 4,
    "padding": false
  }
}
```

**Key differences:**
- Field name: `mux` → `multiplex`
- Protocol selection: sing-box supports `smux`, `yamux`, `h2mux` (default)
- `concurrency` → `max_connections` (or `min_streams` / `max_streams`)
- Padding is explicit: `"padding": true/false`
- **Server must also support sing-box mux** — Xray mux and sing-box mux are NOT interoperable

**Critical implication:** If users' servers run Xray-core, sing-box mux will NOT work with those servers. Mux requires both client AND server to use the same implementation. This means **mux should likely be disabled by default** for the sing-box migration, since most user servers run Xray-core.

**Prevention:**
1. Default `muxEnabled` to `false` after migration.
2. Only enable mux when the server is known to run sing-box.
3. Show a clear warning in Settings that mux requires a sing-box compatible server.
4. Map `VpnSettings.muxConcurrency` → `max_connections` in the config builder.

---

### Pitfall 10: Per-App Proxy Moves Into Config — No More VpnService.Builder Control

**Severity:** MEDIUM | **Likelihood:** HIGH | **Confidence:** HIGH

**What goes wrong:** The current implementation uses `VpnService.Builder.addAllowedApplication()` / `addDisallowedApplication()` for per-app routing (ArmaVpnService.kt lines 418-449). With sing-box, per-app proxy is configured in the **TUN inbound config**, not via VpnService.Builder.

**Current approach (ArmaVpnService.kt):**
```kotlin
// Read from SharedPreferences
val perAppMode = perAppPrefs.getString("per_app_mode", null)
val selectedApps = perAppPrefs.getStringSet("selected_apps", emptySet())
// Apply via VpnService.Builder
if (perAppMode == "whitelist") {
    for (pkg in selectedApps) { builder.addAllowedApplication(pkg) }
} else {
    builder.addDisallowedApplication(packageName) // self-exclusion
    for (pkg in selectedApps) { builder.addDisallowedApplication(pkg) }
}
```

**sing-box approach (TUN config):**
```json
{
  "type": "tun",
  "include_package": ["com.android.chrome"],   // whitelist
  "exclude_package": ["com.android.captiveportallogin"]  // blacklist
}
```

**Why this matters:** sing-box's `PlatformInterface.OpenTun(options TunOptions)` receives the package lists from the config and passes them to VpnService.Builder internally. The TUN is created by YOUR code in `OpenTun`, using the options sing-box provides. So per-app config moves from Kotlin SharedPreferences logic → Dart config builder → sing-box TUN config → Kotlin OpenTun callback.

**Prevention:**
1. Move per-app package lists into the sing-box JSON config under the TUN inbound.
2. In the Kotlin `OpenTun` implementation, read the package lists from `TunOptions.GetIncludePackage()` / `GetExcludePackage()` and apply them to `VpnService.Builder`.
3. The self-exclusion of the VPN app's own package should still be done in `OpenTun`.

---

### Pitfall 11: Latency Testing Architecture Change — No More MeasureDelay

**Severity:** MEDIUM | **Likelihood:** CERTAIN | **Confidence:** HIGH

**What goes wrong:** The current latency test uses `Libv2ray.measureDelay(configJson, url)` — a static Go function that creates a temporary Xray instance, connects through the proxy, and measures HTTP response time. sing-box's libbox does not expose an equivalent single-shot function.

**Current implementation (VpnPlatformService.dart):**
```dart
Future<int> measureDelay(String configJson, {String testUrl = 'https://www.google.com/generate_204'})
```

**sing-box alternatives:**
1. **URL Test outbound:** A built-in outbound type that automatically tests latency:
   ```json
   {"type": "urltest", "outbounds": ["proxy-a", "proxy-b"], "url": "https://www.google.com/generate_204", "interval": "3m"}
   ```
   But this is for ongoing monitoring, not one-shot tests.

2. **CommandClient + status:** The `StatusMessage` from CommandClient may include latency info.

3. **Manual HTTP through SOCKS:** Start a temporary sing-box instance with a SOCKS inbound, send an HTTP request through it, measure time. This is the most equivalent approach but requires managing temporary instances.

4. **libbox `CheckConfig()` + temporary service:** Similar to approach 3, but more complex.

**Prevention:**
1. For **bulk latency testing**, start a temporary sing-box instance with a SOCKS/HTTP inbound per server, use Dart's `HttpClient` to measure response time through the local proxy.
2. For **single-node testing**, the same approach but with a single outbound.
3. Alternatively, use a URL Test outbound group to get automatic best-server selection.
4. This is a significant architecture change — budget extra time for the latency test feature.

---

## Moderate Pitfalls

Issues that cause bugs but have straightforward fixes.

---

### Pitfall 12: Build Tag Selection Affects Library Size and Features

**Severity:** MEDIUM | **Likelihood:** MEDIUM | **Confidence:** MEDIUM

**What goes wrong:** sing-box's feature set depends on build tags. The default build includes gVisor TUN stack, WireGuard, QUIC, uTLS, Clash API, and more. Including everything produces a larger AAR than libv2ray.aar. Missing a required tag means silent feature absence.

**Current libv2ray.aar:** ~20-30MB (contains Xray-core with TUN support)

**sing-box with default tags:** Potentially 30-50MB depending on included features.

**Critical build tags for Arma:**
- `with_quic` ✅ (needed for Hysteria2)
- `with_utls` ✅ (needed for TLS fingerprinting — chrome/firefox/safari)
- `with_gvisor` ✅ (needed for TUN stack)
- `with_clash_api` — Optional (one way to get stats, but CommandClient is better)
- `with_v2ray_api` — NOT included by default. Only needed if using V2Ray stats API.
- `with_grpc` — NOT included by default. Needed only for standard gRPC transport.
- `with_wireguard` — Not needed for Arma's protocols.
- `with_embedded_tor` — Not needed.

**Prevention:**
1. Use a **custom build tag set** to minimize library size: `with_quic,with_utls,with_gvisor`.
2. Test that all required protocols work with the selected tags.
3. Compare APK size before/after migration. If it increases by >10MB, review tag selection.
4. Consider building without `with_wireguard` and `with_clash_api` to save space.

---

### Pitfall 13: VLESS Flow Field Mapping — Same Logic, Different Location

**Severity:** MEDIUM | **Likelihood:** MEDIUM | **Confidence:** HIGH

**What goes wrong:** The VLESS `flow` field placement changes between Xray and sing-box. The logic is the same (only set for TCP + TLS/Reality), but it's a top-level field in sing-box, not nested in `users[]`.

**Xray:** `outbound.settings.vnext[0].users[0].flow: "xtls-rprx-vision"`
**sing-box:** `outbound.flow: "xtls-rprx-vision"` (top-level in outbound)

The existing `_resolveFlow()` logic (only set flow for VLESS + TCP + TLS/Reality) remains correct and should be reused in the sing-box config builder.

**Prevention:** Copy the flow-resolution logic but place the result at the outbound root, not nested in users.

---

### Pitfall 14: Hysteria2 Obfuscation Format Differs

**Severity:** LOW | **Likelihood:** MEDIUM | **Confidence:** HIGH

**What goes wrong:** Xray-core's Hysteria2 obfuscation uses a string field. sing-box uses a nested object:

**Xray:** Not directly available (Xray's Hysteria2 support is limited)
**sing-box:**
```json
{
  "obfs": {
    "type": "salamander",
    "password": "cry_me_a_r1ver"
  }
}
```

Also, sing-box adds Hysteria2-specific features not in Xray: `server_ports` (port ranges), `hop_interval` (port hopping), `bbr_profile`. These are new capabilities users might want.

**Prevention:** Map `ServerConfig.obfs` / `ServerConfig.obfsPassword` to the nested object format. Expose new Hysteria2 features (port hopping, BBR profile) in future settings.

---

### Pitfall 15: Rollback Strategy — Keeping Both Engines Is Expensive But Necessary

**Severity:** HIGH | **Likelihood:** N/A (planning risk) | **Confidence:** HIGH

**What goes wrong:** If sing-box doesn't work in specific censored network environments (fragment behavior, Reality compatibility issues, or unforeseen protocol bugs), you need to fall back to Xray-core. But if you've already deleted libv2ray.aar and `XrayConfigBuilder`, there's no way back.

**Consequences:** Shipping a broken engine to users in censored regions means they lose internet access. This is not a "feature degradation" — it's a total outage for affected users.

**Rollback strategies (in order of preference):**

**Strategy A: Feature flag engine selection (RECOMMENDED)**
- Keep BOTH libv2ray.aar and libbox.aar in the project during migration.
- Add a Settings toggle: "Engine: sing-box (default) / Xray-core (legacy)"
- Config builder selection based on engine flag.
- APK size increases by ~20-30MB (acceptable for reliability).
- Remove Xray engine only after 2-3 releases with sing-box proving stable.

**Strategy B: Version-gated rollback**
- Ship sing-box in v1.1-beta with opt-in.
- Ship sing-box as default in v1.1-stable only after beta validation.
- Maintain a v1.0 branch that can be quickly released if v1.1 has issues.

**Strategy C: Clean break (HIGH RISK)**
- Remove Xray-core entirely, ship sing-box only.
- Acceptable ONLY if thorough testing in all target regions (Iran, China, Russia) confirms feature parity.

**Prevention:**
1. Use **Strategy A** for the initial migration release.
2. Keep `XrayConfigBuilder.dart` and `XrayCoreManager.kt` in the codebase (possibly moved to a legacy directory).
3. Implement an interface/abstraction layer: `ProxyEngine` with `XrayEngine` and `SingboxEngine` implementations.
4. Test in Iran and China before removing the Xray fallback.

---

## Testing Pitfalls

---

### Pitfall 16: Protocol×Transport×TLS Matrix Requires Real Server Testing

**Severity:** HIGH | **Likelihood:** HIGH | **Confidence:** MEDIUM

**What goes wrong:** Unit tests for config generation only verify JSON structure. They cannot verify that the generated config actually establishes a working connection. The protocol×transport×TLS matrix has ~30+ valid combinations, and each must be tested against a real server.

**Minimum test matrix for feature parity:**

| Protocol | Transport | TLS | Priority |
|----------|-----------|-----|----------|
| VLESS | TCP | Reality | CRITICAL (most common in Iran) |
| VLESS | TCP | TLS | HIGH |
| VLESS | WS | TLS | HIGH (CDN users) |
| VLESS | gRPC | TLS | MEDIUM |
| VMess | TCP | TLS | HIGH |
| VMess | WS | TLS | HIGH (CDN users) |
| VMess | TCP | none | MEDIUM |
| Trojan | TCP | TLS | HIGH |
| Trojan | WS | TLS | MEDIUM |
| SS | TCP | - | HIGH |
| Hysteria2 | QUIC | TLS | HIGH |

**Prevention:**
1. Set up a test server running **Xray-core** (since that's what most user servers run) with all protocol/transport combos.
2. Automate connection tests: generate sing-box config → start sing-box → curl through proxy → verify response.
3. Test VLESS Reality first — it's the most popular protocol in censored regions and has the most complex config.
4. Compare sing-box connection success rate vs Xray-core for the same server configs.

---

### Pitfall 17: Messenger IPC Between Processes May Need Restructuring

**Severity:** MEDIUM | **Likelihood:** MEDIUM | **Confidence:** MEDIUM

**What goes wrong:** The current Messenger IPC (ServiceConnection.kt) passes Xray-specific messages: `MSG_COMMAND_START` carries config JSON, `MSG_TRAFFIC_STATS` carries raw uplink/downlink bytes from QueryStats. With sing-box, the CommandServer/CommandClient architecture may partially replace this IPC, or the IPC message format may need updating.

**sing-box's libbox CommandServer** listens on a Unix socket. If the VPN service runs in a separate process (`:vpn_process`), the CommandClient in the main process connects to this socket. This means the Messenger IPC might be partially redundant — CommandClient already provides stats and status.

**Prevention:**
1. Evaluate whether CommandClient/CommandServer can replace Messenger for status and stats.
2. Keep Messenger IPC for start/stop commands (config delivery from Flutter → VPN process).
3. Or fully migrate to CommandServer: Flutter → MethodChannel → Kotlin → CommandServer.start(configPath) and CommandClient for status/stats.

---

## Phase-Specific Warnings

| Phase/Task | Likely Pitfall | Severity | Mitigation |
|------------|---------------|----------|------------|
| **Config Builder** | Complete JSON incompatibility (#1) | CRITICAL | Build from scratch, don't modify XrayConfigBuilder |
| **Config Builder** | Transport differences (#7) | HIGH | Map each transport type individually, test with Xray servers |
| **Config Builder** | DNS format change (#8) | HIGH | Implement typed DNS server objects |
| **Config Builder** | Mux incompatibility with Xray servers (#9) | MEDIUM | Default mux to disabled |
| **Config Builder** | Geo data removal (#3) | CRITICAL | Use rule-sets + ip_is_private |
| **Config Builder** | Per-app moves to config (#10) | MEDIUM | Generate include/exclude_package in TUN inbound |
| **Core Manager** | libbox API completely different (#2) | CRITICAL | Implement PlatformInterface, use CommandServer |
| **Core Manager** | Socket protection callback (#6) | HIGH | Implement AutoDetectInterfaceControl in PlatformInterface |
| **VPN Service** | TUN creation inverted (#2) | CRITICAL | Implement OpenTun callback, don't pass fd to sing-box |
| **Traffic Monitor** | QueryStats doesn't exist (#5) | CRITICAL | Use CommandClient subscription model |
| **Latency Test** | MeasureDelay doesn't exist (#11) | MEDIUM | Temporary SOCKS proxy + HTTP measurement |
| **Anti-Censorship** | Fragment behavior differs (#4) | CRITICAL | Test in target regions, keep Xray fallback |
| **Build** | Library size increase (#12) | MEDIUM | Custom build tag selection |
| **Release** | No rollback plan (#15) | HIGH | Ship with dual-engine feature flag |
| **Testing** | Protocol matrix not validated (#16) | HIGH | Real server testing for all combos |

---

## Risk Summary Matrix

| # | Risk | Severity | Likelihood | Impact | Mitigation Cost |
|---|------|----------|-----------|--------|-----------------|
| 1 | Config JSON incompatible | CRITICAL | Certain | Complete rewrite of config builder | HIGH (1-2 weeks) |
| 2 | libbox API different | CRITICAL | Certain | Rewrite core manager + VPN service | HIGH (1-2 weeks) |
| 3 | Geo data format changed | CRITICAL | Certain | Routing rules broken | MEDIUM (2-3 days) |
| 4 | Fragment anti-censorship weaker | CRITICAL | High | Users in censored regions affected | HIGH (testing time) |
| 5 | Traffic stats mechanism changed | CRITICAL | Certain | Dashboard broken | MEDIUM (3-5 days) |
| 6 | Socket protection API different | HIGH | Certain | Routing loop if missed | LOW (1 day) |
| 7 | Transport differences | HIGH | High | Some server configs fail | MEDIUM (3-5 days) |
| 8 | DNS config restructured | HIGH | High | DNS resolution broken | MEDIUM (2-3 days) |
| 9 | Mux incompatible with Xray servers | MEDIUM | High | Mux feature broken | LOW (disable by default) |
| 10 | Per-app proxy moves to config | MEDIUM | High | Per-app routing broken | LOW (1-2 days) |
| 11 | Latency test architecture change | MEDIUM | Certain | Latency testing broken | MEDIUM (3-5 days) |
| 12 | Library size increase | MEDIUM | Medium | Larger APK | LOW (build tag tuning) |
| 13 | VLESS flow field location | MEDIUM | Medium | VLESS connections fail | LOW (1 hour) |
| 14 | Hysteria2 obfs format | LOW | Medium | Hy2 obfs connections fail | LOW (1 hour) |
| 15 | No rollback plan | HIGH | N/A | Stuck with broken engine | MEDIUM (dual-engine approach) |
| 16 | Insufficient testing | HIGH | High | Undetected failures in production | HIGH (test infrastructure) |
| 17 | IPC restructuring | MEDIUM | Medium | Communication issues | MEDIUM (evaluate scope) |

---

## Sources

- sing-box configuration docs: `sing-box.sagernet.org/configuration/` — verified config schema for all protocols, TUN, DNS, routing, TLS, transport — **HIGH confidence**
- sing-box `testing` branch source code: `github.com/SagerNet/sing-box/experimental/libbox/` — verified API: service.go (CommandServer), platform.go (PlatformInterface), tun.go (TunOptions), config.go (CheckConfig/FormatConfig), setup.go (Setup), command_client.go (CommandClient) — **HIGH confidence**
- sing-box `docs/migration.md`: Official breaking changes 1.8→1.14, geoip/geosite removal, DNS server format changes — **HIGH confidence**
- sing-box `docs/configuration/shared/tls.md`: TLS fragment feature details (since 1.12.0), behavior on different platforms — **HIGH confidence**
- sing-box `docs/configuration/shared/v2ray-transport.md`: Explicit differences from v2ray-core (no TCP transport, no mKCP) — **HIGH confidence**
- sing-box `docs/installation/build-from-source.md`: Build tags and their effects — **HIGH confidence**
- Arma v1.0 codebase: `XrayConfigBuilder.dart` (543 lines), `XrayCoreManager.kt` (99 lines), `ArmaVpnService.kt` (~500 lines), `TrafficMonitor.kt` (55 lines), `VpnServiceConnection.kt` (105 lines), `VpnPlatformService.dart` (128 lines), `VpnSettings.dart` (78 lines), `protocol_constants.dart` (31 lines) — **HIGH confidence** (direct code analysis)
- Hiddify (Flutter + sing-box reference): Architecture patterns for libbox + Flutter integration — **MEDIUM confidence** (inferred from known patterns, not direct code review this session)
