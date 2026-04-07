# Domain Pitfalls — sing-box Engine Migration

**Domain:** Xray-core → sing-box migration in Flutter VPN Client (Android)
**Researched:** 2025-07-15 (v1.0), updated 2025-07-19 (v1.1 migration)
**Sources:** sing-box official docs (sing-box.sagernet.org), SagerNet/sing-box GitHub (libbox API, config schema, migration.md), Hiddify source code (Flutter/sing-box reference), existing v1.0 Arma codebase analysis, V2rayNG source code
**Confidence:** HIGH for config format/API differences (verified against sing-box source code), MEDIUM for operational pitfalls (inferred from API surface + community patterns)

---

## Critical Pitfalls

Mistakes that cause rewrites, crashes, or fundamental breakage. Each learned from real production issues in V2rayNG and Hiddify.

---

### Pitfall 1: VPN Service Shutdown Order — `stopSelf()` MUST Precede `mInterface.close()`

**What goes wrong:** When stopping the VPN, if you close the TUN file descriptor (`mInterface.close()`) before calling `stopSelf()`, the Xray-core process fails to stop and release its listening ports. On the next connection attempt, the core reports "port already in use" and fails to start.

**Why it happens:** The Android VPN system and Go runtime have an implicit dependency on service lifecycle. When the TUN fd closes first, the Go core's socket operations get interrupted in a way that prevents clean shutdown. The core goroutines hang instead of terminating.

**Consequences:** Users see "connection failed" after toggling VPN off and on rapidly. The only recovery is force-killing the app process. This is documented in V2rayNG source code with an explicit comment: *"stopSelf has to be called ahead of mInterface.close(). otherwise v2ray core cannot be stopped. It's strange but true."*

**Prevention:**
```kotlin
// CORRECT order — always stop service first, then close interface
private fun stopAllService() {
    isRunning = false
    // 1. Stop tun2socks FIRST
    tun2SocksService?.stopTun2Socks()
    // 2. Stop Xray core
    V2RayServiceManager.stopCoreLoop()
    // 3. Stop the Android service
    stopSelf()
    // 4. LAST: close the TUN file descriptor
    try { mInterface.close() } catch (e: Exception) { /* log */ }
}
```

**Detection:** Test by rapidly toggling VPN on/off 5-10 times in succession. If the 3rd or 4th attempt fails with port-in-use errors, this ordering bug is present.

**Phase:** Phase 3 (VpnService implementation) — get this right from the first commit.

---

### Pitfall 2: Go-Mobile AAR Build Fragility — Version Lock-Step Required

**What goes wrong:** Building Xray-core via `gomobile bind` into an AAR silently produces corrupted or non-functional binaries when Go version, gomobile version, and Android NDK version are misaligned. The AAR compiles successfully but crashes at runtime with opaque JNI errors or Go panics.

**Why it happens:** gomobile generates C bindings via cgo that depend on specific NDK toolchain versions. Go minor version changes can alter the runtime's threading model, garbage collector behavior, and cgo calling convention. Xray-core's dependency tree (especially the crypto libraries) has build constraints that silently change behavior between Go versions.

**Consequences:** Days of debugging "works on my machine" issues. The AAR builds fine in CI but crashes on specific device architectures (usually armeabi-v7a). Hiddify's most persistent issue (#1936, 48+ comments) is "failed to start background core" — often traced to Go build environment mismatches.

**Prevention:**
1. **Pin exact versions in CI:** Go 1.22.x (the version Xray-core CI uses), gomobile from `golang.org/x/mobile/cmd/gomobile@latest` at a pinned commit, NDK r26b or whatever Xray-core's CI uses.
2. **Use the same Makefile pattern as AndroidLibXrayLite:** Don't invent your own build system.
3. **Build for ALL target ABIs in CI, test on real devices for each:** `arm64-v8a` (most phones), `armeabi-v7a` (old phones), `x86_64` (emulators).
4. **Consider using pre-built AARs** from AndroidLibXrayLite releases if custom Go wrapper isn't needed immediately.

**Detection:** If the app works on emulator (x86_64) but crashes on physical device (arm64), this is almost certainly a build environment issue.

**Phase:** Phase 3 — but the build environment should be set up and validated in a pre-phase or Phase 0 spike. Don't attempt VpnService work without a confirmed-working AAR.

---

### Pitfall 3: Running VPN Service in Same Process as Flutter — OOM and Crash Propagation

**What goes wrong:** When the Xray-core Go runtime and Flutter's Dart VM run in the same OS process, a Go panic (nil pointer, OOB, deadlock) crashes the entire app with no recovery. Additionally, the Go runtime's memory usage (50-150MB for Xray-core with routing rules + geosite data) combined with Flutter's memory means the process exceeds Android's per-process memory limit, triggering OOM kills.

**Why it happens:** Go's runtime uses its own memory manager, GC, and goroutine scheduler. When it panics, it calls `abort()` which kills the entire process. There's no way to catch a Go panic from the JVM/Dart side. V2rayNG explicitly runs the VPN service in a separate process: `android:process=":RunSoLibV2RayDaemon"`.

**Consequences:** App randomly "disappears" (no crash dialog) under memory pressure. Go deadlocks during network errors silently kill the app. Users report the app as "unstable."

**Prevention:**
```xml
<!-- AndroidManifest.xml -->
<service
    android:name=".service.ArmaVpnService"
    android:process=":vpn_core"
    android:permission="android.permission.BIND_VPN_SERVICE"
    android:foregroundServiceType="specialUse"
    android:exported="false">
    <intent-filter>
        <action android:name="android.net.VpnService" />
    </intent-filter>
</service>
```
**Important caveat:** When VPN runs in a separate process, Flutter platform channels don't work directly across processes. You need either:
- A Messenger/AIDL IPC bridge between the Flutter process and the VPN process
- A BroadcastReceiver pattern (what V2rayNG uses)
- Or a gRPC local server (what Hiddify uses)

**Detection:** Monitor app's PSS memory in Android profiler. If it exceeds 300MB with active VPN, OOM kills will follow on mid-range devices.

**Phase:** Phase 3 — architectural decision. Must be decided before writing any VpnService code because it determines the entire communication pattern.

---

### Pitfall 4: VPN Permission Activity Result Flow Broken in Flutter

**What goes wrong:** `VpnService.prepare(context)` returns an `Intent` that must be launched via `startActivityForResult()` to get user consent. Flutter's `MethodChannel` has no built-in mechanism for Activity results. Naive implementations either skip the permission check (crashes on first use) or implement it incorrectly (works once, breaks on subsequent calls).

**Why it happens:** Flutter's platform channel abstraction doesn't map cleanly to Android's Activity lifecycle. The Dart→Kotlin call initiates `prepare()`, but the result comes back asynchronously via `onActivityResult()` in the Activity, which must then be routed back to the Dart side.

**Consequences:** App crashes with "VPN permission not granted" on first launch. Or works on first launch but breaks when system revokes VPN permission (e.g., another VPN app takes over).

**Prevention:**
```kotlin
// In your FlutterActivity or custom Activity
class MainActivity : FlutterActivity() {
    private var vpnPermissionResult: MethodChannel.Result? = null
    
    fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            vpnPermissionResult = result
            startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
        } else {
            result.success(true) // already granted
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            vpnPermissionResult?.success(resultCode == RESULT_OK)
            vpnPermissionResult = null
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
}
```
Also handle `onRevoke()` in VpnService — Android calls this when permission is revoked, and you must clean up immediately.

**Detection:** Test on a device with another VPN app installed. Switch between apps to force permission revocation.

**Phase:** Phase 3 — implement this before the connect button works.

---

### Pitfall 5: Foreground Service Type Missing for Android 14+ (API 34+)

**What goes wrong:** Starting with Android 14, foreground services must declare a `foregroundServiceType` and the corresponding permission. Without `FOREGROUND_SERVICE_SPECIAL_USE` permission and `foregroundServiceType="specialUse"`, the service start call throws a `SecurityException` and the VPN silently fails to start.

**Why it happens:** Google tightened foreground service restrictions to prevent abuse. VPN services don't fit neatly into the predefined types (camera, location, etc.), so they must use `specialUse` with a `PROPERTY_SPECIAL_USE_FGS_SUBTYPE` metadata property.

**Consequences:** App works on Android 13 and below but completely fails on Android 14+. Since this is the fastest-growing Android version segment, this is a launch-blocker.

**Prevention:**
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission
    android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE"
    android:minSdkVersion="34" />

<service
    android:name=".service.ArmaVpnService"
    android:foregroundServiceType="specialUse"
    ...>
    <property
        android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
        android:value="vpn" />
</service>
```
Also need `CHANGE_NETWORK_STATE` for network callback registration on Android P+.

**Detection:** Test on Android 14 emulator or device. The crash is immediate and appears in logcat as SecurityException.

**Phase:** Phase 3 — must be in the AndroidManifest from day one.

---

### Pitfall 6: Go `Seq.setContext()` Not Called Before Go Functions — JNI Crash

**What goes wrong:** The very first call to any Go-Mobile generated function crashes with a JNI null pointer exception because the Go runtime's Android context hasn't been initialized. This manifests as an opaque native crash with no useful stack trace.

**Why it happens:** gomobile generates Java bindings that internally use `go.Seq` to marshal data between JVM and Go. `Seq` requires an Android `Context` to be set before any marshaling occurs. Without it, the Go runtime can't access the filesystem, network, or other Android APIs.

**Consequences:** Crash on app startup if any Go function is called during initialization (e.g., getting the Xray core version to display in settings).

**Prevention:**
```kotlin
object XrayNativeManager {
    private val initialized = AtomicBoolean(false)
    
    fun initializeGoRuntime(context: Context) {
        if (initialized.compareAndSet(false, true)) {
            try {
                go.Seq.setContext(context.applicationContext) // MUST use applicationContext
                Libv2ray.initCoreEnv(assetPath, deviceId)
            } catch (e: Exception) {
                initialized.set(false) // allow retry
                throw e
            }
        }
    }
}
```
Use `AtomicBoolean` for thread-safe single initialization. Always pass `applicationContext`, not an Activity context (which can leak).

**Detection:** Call any Go function immediately after app launch. If it crashes, context wasn't set.

**Phase:** Phase 3 — first line of Go integration code.

---

### Pitfall 7: VMess Share Link Has Two Incompatible Formats

**What goes wrong:** VMess share links exist in two completely different formats:
1. **Legacy format:** `vmess://` + base64-encoded JSON blob (`{"v":"2","ps":"name","add":"server","port":"443","id":"uuid",...}`)
2. **Standard URI format:** `vmess://uuid@server:port?type=tcp&security=tls&...#name`

Parsing only one format means ~40-50% of user configs fail silently with "invalid configuration."

**Why it happens:** The original v2ray project defined the base64-JSON format. Later, a standardized URI format was proposed (matching VLESS/Trojan patterns). Both are widely used. V2rayNG handles this with explicit format detection: `if (str.indexOf('?') > 0 && str.indexOf('&') > 0)` routes to the standard parser, otherwise to the legacy parser.

**Consequences:** Users import configs that "work in V2rayNG" but fail in your app. The #1 category of user complaints in V2ray client apps.

**Prevention:**
```dart
ProfileItem? parseVmess(String uri) {
  final content = uri.replaceFirst('vmess://', '');
  // Check for standard URI format
  if (content.contains('?') && content.contains('&') && content.contains('@')) {
    return _parseVmessStandardUri(uri);
  }
  // Legacy base64 JSON format
  return _parseVmessBase64Json(content);
}
```
Test with configs from at least 5 different subscription providers to cover format variations.

**Detection:** Collect 20+ real-world VMess share links from different providers. If any fail to parse, the parser is incomplete.

**Phase:** Phase 2 (Configuration parsing) — get both formats right before any VPN integration.

---

### Pitfall 8: DNS Leak Through VPN Tunnel

**What goes wrong:** DNS queries bypass the proxy tunnel and go directly to the ISP's DNS server, revealing which domains the user is visiting. This completely defeats the purpose of a privacy-focused proxy app.

**Why it happens:** Three common causes:
1. Not adding DNS servers to `VpnService.Builder` — the system uses default DNS which isn't tunneled
2. Using a DNS server that's blocked in the user's country (e.g., `1.1.1.1` is blocked in some regions of Iran/China)
3. Not configuring Xray-core's internal DNS to route DNS queries through the proxy

**Consequences:** In censored regions, leaked DNS queries trigger domain-based blocking, causing the proxy to appear "not working" even though the tunnel is up. Worse, it exposes user browsing to ISP monitoring.

**Prevention:**
```kotlin
// In VpnService builder
builder.addDnsServer("1.1.1.1") // gets tunneled through VPN
// In Xray config JSON
{
  "dns": {
    "servers": [
      {
        "address": "1.1.1.1", // remote DNS through proxy
        "domains": ["geosite:geolocation-!cn"] // or all non-domestic
      },
      {
        "address": "223.5.5.5", // domestic DNS direct  
        "domains": ["geosite:cn"] // only for domestic domains
      }
    ]
  }
}
```
Split DNS strategy: proxy DNS for foreign domains, direct DNS for domestic. Also enable Xray-core's sniffing feature to override DNS-based routing with actual domain detection.

**Detection:** Use a DNS leak test site (dnsleaktest.com) while connected through the proxy. Any non-proxy DNS server in results = leak.

**Phase:** Phase 3 (VpnService + Xray config) — must be correct in the first working build.

---

## Moderate Pitfalls

Mistakes that cause significant bugs but are recoverable without rewriting.

---

### Pitfall 9: Network Switch Stalls VPN Connection (Missing `setUnderlyingNetworks`)

**What goes wrong:** When the user switches from WiFi to mobile data (or vice versa), the VPN connection silently stops working. Traffic appears to flow (no error UI) but nothing actually reaches the destination. The user must manually disconnect and reconnect.

**Why it happens:** Android's `VpnService` needs to be told about the underlying physical network. Without `setUnderlyingNetworks()`, the VPN's routing decisions are based on stale network state. On Android P+ (API 28), a `ConnectivityManager.NetworkCallback` must update the underlying network.

**Prevention:**
```kotlin
// Android P+ network change handling
@RequiresApi(Build.VERSION_CODES.P)
private val networkCallback = object : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) {
        setUnderlyingNetworks(arrayOf(network))
    }
    override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
        setUnderlyingNetworks(arrayOf(network))
    }
    override fun onLost(network: Network) {
        setUnderlyingNetworks(null)
    }
}

// Register in setupVpnService(), unregister in stopService()
connectivity.requestNetwork(networkRequest, networkCallback)
```
**Important:** Use `requestNetwork` (not `registerDefaultNetworkCallback`) because the latter returns the VPN interface itself, creating a loop. V2rayNG documents this gotcha explicitly in their source.

**Detection:** Connect to VPN on WiFi, then switch to mobile data. If pages stop loading, this callback is missing.

**Phase:** Phase 3 — implement alongside VpnService setup.

---

### Pitfall 10: Platform Channel Calls Block Flutter UI Thread

**What goes wrong:** Calling Xray-core operations (start, stop, generate config, measure latency) through `MethodChannel` freezes the Flutter UI for 1-5 seconds. The connection button appears unresponsive, animations stutter, and the app feels broken.

**Why it happens:** Flutter's `MethodChannel.invokeMethod` executes handler code on the Android main thread by default. Go runtime startup, config parsing, and Xray-core initialization are CPU-intensive operations (100ms-3s). V2rayNG mitigates this by running everything in coroutines, but Flutter's default platform channel doesn't.

**Prevention:**
```kotlin
// Kotlin side — offload heavy work to coroutines
override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
        "startVpn" -> {
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val success = startXrayCore(call.argument("config")!!)
                    withContext(Dispatchers.Main) {
                        result.success(success)
                    }
                } catch (e: Exception) {
                    withContext(Dispatchers.Main) {
                        result.error("VPN_ERROR", e.message, null)
                    }
                }
            }
        }
    }
}
```
Alternatively, use `EventChannel` for streaming updates (connection state, traffic stats) and `MethodChannel` only for commands.

Consider using `BackgroundIsolateBinaryMessenger` for heavy Dart-side processing of configs.

**Detection:** Add a spinning animation to the dashboard. If it freezes during connect/disconnect, the platform channel is blocking.

**Phase:** Phase 3 — but design the channel API in Phase 2 when defining the architecture.

---

### Pitfall 11: GeoIP/GeoSite Data Files Missing or Stale

**What goes wrong:** Xray-core's routing rules depend on `geoip.dat` and `geosite.dat` files. Without them, routing rules like `geosite:cn` or `geoip:private` silently fail, causing ALL traffic to either be proxied (slow, wasteful) or direct (defeats purpose).

**Why it happens:** These files must be bundled with the app or downloaded on first launch. They're large (geoip.dat ≈ 4-11MB, geosite.dat ≈ 3-8MB) and need periodic updates as IP ranges change. The files must be placed in a specific directory that Xray-core's `initCoreEnv` is configured to read from.

**Consequences:** Users in China/Iran/Russia report "everything is slow" because domestic traffic is being routed through the proxy unnecessarily, or "nothing works" because critical infrastructure domains are being blocked.

**Prevention:**
1. Bundle minimal geoip/geosite in APK assets (increases APK size by ~15MB)
2. Copy to app's internal storage on first launch: `context.filesDir/assets/`
3. Pass this path to `Libv2ray.initCoreEnv(assetPath, ...)`
4. Implement background update from GitHub releases (Loyalsoldier/v2ray-rules-dat)
5. Show last-updated timestamp in Settings so users know when data was refreshed

**Detection:** Enable routing rules "bypass LAN and mainland." If domestic websites become slow or inaccessible, geo data is missing/stale.

**Phase:** Phase 3 (core integration) for bundling, Phase 4 (polish) for update mechanism.

---

### Pitfall 12: Per-App Proxy Self-Inclusion Creates Routing Loop

**What goes wrong:** When implementing per-app VPN (allow/disallow specific apps), failing to exclude the VPN app itself from the tunnel creates a routing loop. All of the app's own traffic (including the proxy connection to the server) gets routed back into the VPN tunnel, creating an infinite loop that hangs the connection.

**Why it happens:** The VPN tunnel captures ALL device traffic by default. The proxy app needs to send traffic directly to the proxy server outside the tunnel. Android's `VpnService.protect(socket)` is one solution (protects specific sockets from the tunnel), but `addDisallowedApplication(selfPackageName)` is the standard approach.

**Prevention:**
```kotlin
// ALWAYS exclude self when configuring VPN builder
builder.addDisallowedApplication(BuildConfig.APPLICATION_ID)
```
V2rayNG does this in every code path — even when per-app proxy is disabled, even when no apps are selected. There is NO scenario where the VPN app should tunnel its own traffic.

Additionally, Xray-core's `VpnService.protect(socket)` must be implemented through the Go callback interface so the core can protect its own outbound sockets.

**Detection:** Remove the self-exclusion and try to connect. The connection will hang at "Connecting..." forever.

**Phase:** Phase 3 — part of VPN builder configuration, first implementation.

---

### Pitfall 13: Xray JSON Config Generation — The Iceberg Problem

**What goes wrong:** The Dart model → Xray JSON config translation has subtle bugs that are invisible until a specific protocol + transport + TLS combination is used. Each protocol (VLESS, VMess, Trojan, Shadowsocks, Hysteria2) has a different JSON structure with different required/optional fields, stream settings, and TLS configurations.

**Why it happens:** Xray-core's JSON config has ~200+ possible fields across all protocol/transport combinations. The documentation is in Chinese and often incomplete. Real-world configs use combinations like "VLESS + WebSocket + TLS + CDN" or "VLESS + gRPC + Reality" that each require specific JSON structures.

**Consequences:** "Works for VLESS but not VMess" or "works with TCP but not WebSocket" reports that are individually easy to fix but collectively represent weeks of whack-a-mole debugging.

**Prevention:**
1. **Start from V2rayNG's config templates:** Copy their known-working JSON templates as your base config structure
2. **Test with real subscription providers:** Get test subscriptions that include all protocol types
3. **Implement a "Show Generated JSON" debug feature** early so power users can compare with V2rayNG's output
4. **Key fields to watch:**
   - VLESS: `flow` field must be `"xtls-rprx-vision"` for Reality, empty for others
   - VMess: `security` field defaults to `"auto"`, `alterId` defaults to `0`
   - Trojan: password goes in `settings.servers[0].password`, not `settings.vnext`
   - Hysteria2: completely different config structure, uses `hysteria2` outbound type
   - Stream settings: `network`, `security`, `tlsSettings`/`realitySettings` must match
   - SNI: must be correctly populated from hostname or explicit setting

**Detection:** Build a test matrix: 6 protocols × 5 transports × 3 TLS modes = 90 combinations. Automate testing against a local Xray server.

**Phase:** Phase 2 (models) and Phase 3 (config generation). This is ongoing work throughout the project.

---

### Pitfall 14: Subscription Base64 Decoding Edge Cases

**What goes wrong:** Subscription URLs return base64-encoded content that fails to decode due to:
1. URL-safe base64 (`-_` instead of `+/`) vs standard base64
2. Missing padding (`=` characters)
3. BOM (byte order mark) at start of content
4. Mixed line endings (`\r\n` vs `\n`)
5. Extra whitespace or trailing newlines

**Why it happens:** There's no formal standard for V2ray subscription format. Different providers use different base64 variants, encodings, and line separators. Some providers serve content with HTTP headers that change the encoding.

**Prevention:**
```dart
String decodeSubscription(String raw) {
  // Remove BOM
  raw = raw.replaceAll('\uFEFF', '');
  // Normalize line endings
  raw = raw.trim();
  // Handle URL-safe base64
  raw = raw.replaceAll('-', '+').replaceAll('_', '/');
  // Add padding if missing
  while (raw.length % 4 != 0) {
    raw += '=';
  }
  return utf8.decode(base64.decode(raw));
}

List<String> splitShareLinks(String decoded) {
  return decoded
      .split(RegExp(r'[\r\n]+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
}
```
Also handle: subscription response being JSON (some providers wrap links in JSON), gzip-compressed responses, and custom User-Agent requirements (some providers block default Dart HTTP client UA).

**Detection:** Collect subscription URLs from 10+ different providers. If any fail to parse, the decoder needs hardening.

**Phase:** Phase 2 (subscription parsing).

---

### Pitfall 15: StrictMode Violation in VPN Service Process

**What goes wrong:** The Go runtime performs network operations during initialization that violate Android's `StrictMode` on the main thread. In debug builds, this causes crashes. In release builds, it causes ANR (Application Not Responding) dialogs.

**Why it happens:** Go's runtime initializer may resolve DNS or make network checks. When the VPN service starts on the main thread (via `onStartCommand`), these operations trigger StrictMode violations.

**Prevention:**
```kotlin
override fun onCreate() {
    super.onCreate()
    // V2rayNG does this explicitly
    val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
    StrictMode.setThreadPolicy(policy)
}
```
This is a necessary evil in the VPN service process. Don't apply this to the main Flutter process.

**Detection:** Run in debug mode with StrictMode enabled. ANR dialog or crash during VPN start.

**Phase:** Phase 3 — boilerplate for VPN service.

---

## Minor Pitfalls

Issues that cause inconvenience but have straightforward fixes.

---

### Pitfall 16: Notification Channel Missing for Android 8+ Foreground Service

**What goes wrong:** Foreground service fails to start on Android 8+ because no notification channel was created. The exception is `BadNotificationException: invalid channel for service notification`.

**Prevention:** Create the notification channel in `Application.onCreate()` or before the first `startForeground()` call. Use a persistent, non-dismissible notification with connection status.

**Phase:** Phase 3.

---

### Pitfall 17: Always-On VPN Meta-Data Missing

**What goes wrong:** Users can't enable "Always-On VPN" in Android system settings for your app because the `SUPPORTS_ALWAYS_ON` meta-data is missing from the manifest.

**Prevention:**
```xml
<meta-data
    android:name="android.net.VpnService.SUPPORTS_ALWAYS_ON"
    android:value="true" />
```

**Phase:** Phase 3 — one line in AndroidManifest.

---

### Pitfall 18: Latency Test URL Blocked in Target Regions

**What goes wrong:** Using `https://www.gstatic.com/generate_204` for latency testing (the standard approach) fails in China because Google domains are blocked. Users see all nodes showing `-1ms` latency, making the feature useless.

**Prevention:** Allow configurable test URL. V2rayNG defaults to `gstatic.com/generate_204` but allows users to set custom URLs. For Iran/Russia, `gstatic.com` works; for China, use `http://cp.cloudflare.com/generate_204` or a custom endpoint. The latency test must go THROUGH the proxy, not directly.

**Phase:** Phase 4 (latency testing).

---

### Pitfall 19: Hive Schema Migration Not Planned From Start

**What goes wrong:** After v1 release, adding fields to data models (e.g., new protocol options, user preferences) corrupts existing Hive boxes because Hive doesn't support automatic schema migration. Users must reinstall the app, losing all their configurations.

**Prevention:**
- Use `@HiveField(index)` annotations with explicit indices from day one
- Never reorder or remove field indices in updates
- Reserve index gaps for future fields (e.g., use 0, 1, 2, 5, 10, 15 instead of 0, 1, 2, 3, 4, 5)
- Implement a version field in each box for manual migration logic
- **Alternative:** Consider `drift` (SQLite) instead of Hive — it has proper migration support. Hiddify switched from Hive-like storage to `drift`.

**Phase:** Phase 1 (data modeling) — decisions here lock you in for the entire project lifecycle.

---

### Pitfall 20: URI/Share Link Encoding Edge Cases

**What goes wrong:** Share links containing non-ASCII server remarks (Chinese, Farsi, Russian names), IDN hostnames (internationalized domain names), or special characters in passwords fail to parse or produce garbled config names.

**Prevention:**
```dart
// Always decode URI components properly
final remarks = Uri.decodeComponent(fragment);
// Handle IDN hostnames
final host = uri.host; // Dart's Uri handles punycode
// Base64 in VMess may have non-ASCII
final decoded = utf8.decode(base64.decode(content), allowMalformed: true);
```
V2rayNG has a dedicated `Utils.fixIllegalUrl()` function and `idnHost` extension specifically for this.

**Phase:** Phase 2 (config parsing).

---

### Pitfall 21: IPv6 Route Leakage

**What goes wrong:** When IPv6 is enabled on the device but not configured in the VPN tunnel, IPv6 traffic bypasses the tunnel entirely. Websites with AAAA records are accessed directly, leaking the user's real IPv6 address.

**Prevention:** Either:
1. Add IPv6 routes to VPN builder when IPv6 is enabled: `builder.addRoute("::", 0)`
2. Or explicitly block IPv6 by not adding any IPv6 route (traffic falls through to tunnel and gets dropped)

V2rayNG adds specific IPv6 routes:
```kotlin
builder.addAddress(ipv6Client, 126) // VPN IPv6 address
builder.addRoute("2000::", 3)       // All global unicast IPv6
builder.addRoute("fc00::", 18)      // Xray FakeIPv6 pool
```

**Phase:** Phase 3.

---

### Pitfall 22: EventChannel for Traffic Stats Creates Memory Pressure

**What goes wrong:** Using Flutter `EventChannel` to stream real-time traffic stats (upload/download speed) at high frequency (10+ times per second) creates excessive GC pressure on both Dart and Kotlin sides, causing UI jank.

**Prevention:** Throttle traffic stat updates to 1-2 times per second maximum. Use a `Timer` on the Kotlin side to batch-read traffic counters from Xray-core and emit a single combined update. Don't stream individual byte counts.

**Phase:** Phase 4 (traffic monitoring).

---

## Phase-Specific Warnings

| Phase | Likely Pitfall | Mitigation |
|-------|---------------|------------|
| **Phase 1: Project Setup** | Hive schema locking (#19) | Use explicit field indices with gaps, or switch to drift/SQLite |
| **Phase 1: Project Setup** | Riverpod architecture not fitting VPN state | VPN state lives in the native layer, not Riverpod. Use Riverpod for UI state, platform channels for VPN state |
| **Phase 2: Config Parsing** | VMess dual format (#7) | Implement both parsers from day one, test with real-world configs |
| **Phase 2: Config Parsing** | Subscription encoding chaos (#14) | Handle URL-safe base64, missing padding, BOM, mixed line endings |
| **Phase 2: Config Parsing** | URI edge cases (#20) | Use proper URI decoding, handle non-ASCII remarks |
| **Phase 3: VpnService** | Shutdown order (#1) | Copy V2rayNG's exact shutdown sequence |
| **Phase 3: VpnService** | Go-Mobile build (#2) | Validate AAR on real devices before writing any VPN code |
| **Phase 3: VpnService** | Same-process OOM (#3) | Decide separate process vs same process early; separate is safer |
| **Phase 3: VpnService** | VPN permission flow (#4) | Implement Activity result bridge for VpnService.prepare() |
| **Phase 3: VpnService** | Android 14 foreground service (#5) | Include all permissions and meta-data from first commit |
| **Phase 3: VpnService** | Go context init (#6) | Call Seq.setContext() before any Go function |
| **Phase 3: VpnService** | DNS leak (#8) | Configure split DNS in Xray config, test with leak detector |
| **Phase 3: VpnService** | Network switch (#9) | Implement NetworkCallback for setUnderlyingNetworks |
| **Phase 3: VpnService** | UI freeze (#10) | Run all Go calls on Dispatchers.IO, not main thread |
| **Phase 3: VpnService** | Geo data missing (#11) | Bundle geoip.dat/geosite.dat in assets |
| **Phase 3: VpnService** | Self-routing loop (#12) | Always addDisallowedApplication(self) |
| **Phase 3: VpnService** | Config generation bugs (#13) | Copy V2rayNG's JSON templates, test all protocol combos |
| **Phase 4: Polish** | Latency test URL blocked (#18) | Make test URL configurable |
| **Phase 4: Polish** | Traffic stats jank (#22) | Throttle EventChannel to 1-2 Hz |

---

## Architectural Decision: Communication Pattern for Separate Process VPN

This is the highest-impact architectural decision. Three proven patterns exist:

### Option A: BroadcastReceiver IPC (V2rayNG approach)
- **Pros:** Simple, well-understood, no extra dependencies
- **Cons:** Limited data throughput, no streaming, broadcast ordering issues
- **Best for:** Simple command/response (start/stop/status)

### Option B: gRPC Local Server (Hiddify approach)
- **Pros:** Bidirectional streaming, type-safe protobuf, works across processes
- **Cons:** Complex setup, proto compilation pipeline, larger APK size
- **Best for:** Rich communication (config management, status streaming, traffic stats)

### Option C: AIDL/Messenger (Android standard)
- **Pros:** Android-native, efficient, supports callbacks
- **Cons:** Verbose boilerplate, Kotlin-only (no Dart-side type safety)
- **Best for:** Moderate communication needs

**Recommendation for Arma:** Start with BroadcastReceiver (Option A) for v1. It's proven by V2rayNG and sufficient for start/stop/status. Migrate to gRPC (Option B) if you need rich streaming features later. The key insight from Hiddify is that gRPC is worth the complexity ONLY when you need real-time bidirectional communication (traffic stats, log streaming, config hot-reload).

---

## Sources

- V2rayNG source code: `github.com/2dust/v2rayNG` — Kotlin reference implementation, VpnService lifecycle, Go-Mobile integration patterns (reviewed: V2RayVpnService.kt, V2RayServiceManager.kt, V2RayNativeManager.kt, AppConfig.kt, VlessFmt.kt, VmessFmt.kt, TProxyService.kt, AndroidManifest.xml) — **HIGH confidence**
- Hiddify source code: `github.com/hiddify/hiddify-app` — Flutter reference implementation, gRPC bridge pattern, pubspec dependencies — **HIGH confidence**
- Hiddify issue #1936: "failed to start background core" — persistent Go build/runtime issue with 48+ comments — **HIGH confidence**
- V2rayNG issue #268: "io read/write on closed pipe" — file descriptor lifecycle issue — **HIGH confidence**
- V2rayNG issue #4438: "ColorOS 15 VPN not working" — Android 14+ foreground service issue — **MEDIUM confidence**
- V2rayNG issue #4520: "badvpn low performance" — tun2socks performance issues — **MEDIUM confidence**
- Android VpnService documentation: `developer.android.com/reference/android/net/VpnService` — **HIGH confidence**
- V2rayNG shutdown order comment in source code (V2RayVpnService.kt line ~340) — **HIGH confidence** (direct code evidence)
