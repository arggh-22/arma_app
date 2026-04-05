# Phase 2: VPN Engine & Core Connection - Research

**Researched:** 2026-04-05
**Domain:** Android VpnService + Xray-core AAR integration via Flutter platform channels
**Confidence:** HIGH — verified against V2rayNG source code, Android developer docs, prior domain research (ARCHITECTURE.md, PITFALLS.md, STACK.md)

## Summary

Phase 2 is the highest-risk phase of the project — it bridges three runtimes (Dart, Kotlin, Go) and introduces Android VpnService lifecycle management with a separate process. The core challenge is: receive a `ServerConfig` in Dart, transform it into valid Xray JSON, pass it across a platform channel to Kotlin, which starts a VpnService in a separate process, sets up a TUN interface, and passes the config + TUN file descriptor to the Go-compiled Xray-core AAR.

The 17 requirements for this phase span: VPN engine integration (ENG-01 through ENG-05), protocol support for 4 protocol types across 4 transport types (PROTO-01 through PROTO-04, PROTO-06), dashboard UX with connection state animations (UI-02), real-time monitoring (MON-01 through MON-04), and network routing (ROUTE-01, ROUTE-06). The critical path is: AAR integration → VpnService → platform channel bridge → Xray JSON config builder → connection state management → traffic monitoring → network resilience.

The separate process architecture (D-06) means Flutter platform channels don't work directly across the process boundary. V2rayNG uses BroadcastReceiver + Messenger for this; however, Arma's CONTEXT.md (D-08) locks MethodChannel + EventChannel as the IPC mechanism. This is achievable by keeping the channel host (MainActivity) in the main process and using Android's `Messenger`/`AIDL`/`BroadcastReceiver` internally between MainActivity and the `:vpn_process` — the Flutter side only sees its standard platform channels. This two-hop pattern is the recommended approach.

**Primary recommendation:** Build in strict dependency order: (1) AAR + gradle integration, (2) VpnService with TUN setup in separate process, (3) IPC bridge between processes, (4) Platform channels exposing IPC to Flutter, (5) Xray JSON config builder in Dart, (6) Connection state machine + UI, (7) Traffic monitoring, (8) Network resilience. Never attempt step N+1 without a verified step N.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Use pre-built AAR from AndroidLibXrayLite (2dust's official releases). Do NOT build from source with gomobile — avoids Go/gomobile/NDK version lock-step fragility (Pitfall #2).
- **D-02:** Xray JSON config is built entirely in Dart. The native Kotlin side is a dumb executor — it receives the complete JSON string and passes it to `StartLoop(json, tunFd)`. No config construction logic in Kotlin.
- **D-03:** Connect button transitions: Grey (disconnected) → Pulsing teal ring animation (connecting) → Solid teal glow (connected). Happ-style power button animation on the existing circular button from Phase 1 (D-03).
- **D-04:** Connection duration timer displayed as a separate text widget below the connect button, showing `00:00:00` elapsed time.
- **D-05:** Real-time traffic stats shown as two side-by-side cards below the timer — ↑ upload speed and ↓ download speed, updated in real-time.
- **D-06:** VpnService runs in a separate Android process (`:vpn_process`). Go panics in xray-core cannot crash the Flutter UI. This follows V2rayNG's `:RunSoLibV2RayDaemon` pattern.
- **D-07:** Foreground notification shows: connection status, server name, upload/download speeds. Tapping the notification opens the app. Standard persistent notification (not minimal, not rich-with-controls).
- **D-08:** Flutter ↔ VpnService communication via MethodChannel (commands: connect, disconnect, getStatus) + EventChannel (streaming: connection state changes, real-time traffic stats). This crosses the process boundary.
- **D-09:** VPN shutdown order follows Pitfall #1: stop tun2socks → stopSelf() → close TUN fd. Never close TUN fd before stopSelf().
- **D-10:** Automatic silent reconnect on network changes (WiFi ↔ cellular). ConnectivityManager detects changes, xray-core loop restarts automatically. No user action needed.
- **D-11:** Split DNS from day one — remote DNS for proxied domains, direct DNS for local/LAN domains. Prevents DNS leaks per research recommendations.
- **D-12:** LAN bypass enabled by default (already toggled in Phase 1 Routing screen). VpnService route configuration excludes private IP ranges (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16).

### Agent's Discretion
- Exact Xray JSON config structure and field mapping from ServerConfig
- MethodChannel/EventChannel method names and payload formats
- Foreground notification channel configuration details
- TUN interface parameters (MTU, IP range)
- ConnectivityManager callback implementation details
- Error handling and retry strategies for connection failures

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ENG-01 | App integrates Xray-core via Go-Mobile AAR with Android VpnService to capture all device traffic in TUN mode | AAR API surface documented, VpnService TUN setup pattern documented, separate process architecture |
| ENG-02 | App generates valid Xray-core JSON config from user-facing settings (inbounds, outbounds, routing, dns sections) | Complete JSON config templates for all 4 protocols × transports documented, ServerConfig→JSON field mapping |
| ENG-03 | User can connect/disconnect with a single tap from the dashboard | Platform channel contract, connection state machine, ConnectButton widget extension |
| ENG-04 | Connection state is clearly displayed: Disconnected → Connecting → Connected (with color coding) | ConnectionStatus sealed class pattern, UI animation guidance |
| ENG-05 | VPN runs as foreground service with persistent notification showing connection status | Android 14+ FOREGROUND_SERVICE_SPECIAL_USE, notification channel setup, foreground service pattern |
| PROTO-01 | VLESS protocol including Reality and XTLS-Vision support | VLESS outbound JSON template with Reality/XTLS fields, flow field handling |
| PROTO-02 | VMess protocol (AES-128-GCM/ChaCha20) | VMess outbound JSON template, security/alterId defaults |
| PROTO-03 | Trojan protocol | Trojan outbound JSON template, password field location (servers[] not vnext[]) |
| PROTO-04 | Shadowsocks protocol | Shadowsocks outbound JSON template, method field |
| PROTO-06 | All protocols support common transport types: TCP, WebSocket, gRPC, HTTP/2 | streamSettings templates for all 4 transport types |
| UI-02 | Dashboard has a prominent connect/disconnect button with satisfying visual feedback | Animation spec (grey→pulsing teal→solid teal), ConnectButton extension pattern |
| MON-01 | Dashboard shows real-time upload and download speeds (updated every 1-2 seconds) | QueryStats API, TrafficMonitor polling pattern, EventChannel streaming |
| MON-02 | Dashboard shows connection duration timer | Dart-side Timer implementation |
| MON-03 | Persistent notification displays connection status and current traffic speeds | NotificationCompat.Builder with update pattern |
| MON-04 | App auto-reconnects when network changes (WiFi ↔ cellular) | ConnectivityManager.NetworkCallback, setUnderlyingNetworks |
| ROUTE-01 | App bypasses LAN traffic by default (192.168.x.x, 10.x.x.x) | VpnService.Builder route exclusion pattern, Xray routing rules for geoip:private |
| ROUTE-06 | DNS is split: remote DNS for proxied domains, direct DNS for local domains | Xray DNS config with domain-based server selection |
</phase_requirements>

## Standard Stack

### Core (Phase 2 Additions)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AndroidLibXrayLite AAR | Latest release | Xray-core engine compiled as Android AAR | D-01 locked decision. Pre-built AAR from 2dust's releases avoids Go/gomobile/NDK build fragility (Pitfall #2). Used by V2rayNG (53k+ stars). [VERIFIED: STACK.md, ARCHITECTURE.md] |
| Android VpnService API | API 24+ | TUN interface creation, traffic capture | Official Android API. Required for capturing all device traffic. [CITED: developer.android.com/reference/android/net/VpnService] |
| Kotlin Coroutines | Latest stable | Async native-side operations | Required for offloading Go core operations from main thread (Pitfall #10). V2rayNG uses coroutines extensively. [VERIFIED: PITFALLS.md] |
| geoip.dat / geosite.dat | Loyalsoldier latest | IP/domain routing databases | Required for routing rules (LAN bypass, split DNS). Must be bundled in assets. [VERIFIED: PITFALLS.md §11, STACK.md] |

### Already in Project (from Phase 1)

| Library | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^3.3.1 | State management — ConnectionNotifier for VPN state |
| freezed / freezed_annotation | ^3.2.5 / ^3.1.0 | Immutable models — ConnectionStatus sealed class |
| gap | ^3.0.1 | Layout spacing for traffic stats cards |
| path_provider | ^2.1.5 | Asset paths for geoip.dat/geosite.dat |
| equatable | — | Failure class equality |

### Phase 2 Dart Additions

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_animate | ^4.5.2 | Connect button pulsing animation (D-03) | Button state transitions |
| connectivity_plus | ^7.1.0 | Network change detection on Dart side (fallback) | Supplement to native ConnectivityManager |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| BroadcastReceiver IPC (between processes) | gRPC local server (Hiddify approach) | gRPC adds protobuf compilation pipeline + ~2MB APK size. Overkill for v1 command/response needs. BroadcastReceiver + Messenger is simpler, proven by V2rayNG |
| AIDL for IPC | Messenger (lightweight AIDL) | AIDL is more powerful but more boilerplate. Messenger is sufficient for our needs (commands + status streaming) |
| flutter_local_notifications for foreground service | Native NotificationCompat directly | Since VpnService runs in separate process, notification MUST be created in Kotlin-side directly. Flutter notification plugin operates in Flutter process only. |

## Architecture Patterns

### Recommended Project Structure (Phase 2 additions)

```
lib/
├── features/
│   ├── connection/                     # NEW: VPN connection feature
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── connection_status.dart       # Sealed class: Disconnected/Connecting/Connected/Disconnecting
│   │   │   │   └── traffic_stats.dart           # Upload/download speed data class
│   │   │   ├── repositories/
│   │   │   │   └── vpn_repository.dart          # Interface
│   │   │   └── usecases/
│   │   │       ├── connect_vpn.dart
│   │   │       └── disconnect_vpn.dart
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   │   └── vpn_repository_impl.dart
│   │   │   └── datasources/
│   │   │       └── vpn_platform_service.dart    # MethodChannel/EventChannel wrapper
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── connection_provider.dart      # ConnectionNotifier (Riverpod)
│   │       │   └── traffic_stats_provider.dart   # TrafficStatsNotifier
│   │       └── widgets/
│   │           ├── connect_button.dart           # EXTEND existing — add animations
│   │           ├── connection_timer.dart         # Duration timer widget
│   │           └── traffic_stats_card.dart       # Real-time speed cards (replace placeholder)
│   └── dashboard/                       # EXISTING — modified
│       └── presentation/
│           └── screens/
│               └── dashboard_screen.dart         # Wire up real providers
│
├── xray/                                # NEW: Xray config generation
│   ├── xray_config_builder.dart         # ServerConfig → full Xray JSON
│   ├── models/
│   │   ├── xray_config.dart             # Top-level Xray config structure
│   │   ├── xray_inbound.dart            # Inbound config (socks proxy)
│   │   ├── xray_outbound.dart           # Protocol-specific outbound configs
│   │   ├── xray_routing.dart            # Routing rules
│   │   ├── xray_dns.dart                # DNS configuration
│   │   └── xray_stream_settings.dart    # Transport + TLS settings
│   └── formatters/
│       └── speed_formatter.dart          # Bytes → "1.2 MB/s" formatting
│
android/
├── app/
│   ├── libs/
│   │   └── libv2ray.aar                 # NEW: Pre-built Xray-core AAR
│   └── src/main/
│       ├── AndroidManifest.xml           # MODIFIED: VpnService + permissions
│       ├── assets/                       # NEW: Geo-data files
│       │   ├── geoip.dat
│       │   └── geosite.dat
│       └── kotlin/com/arma/vpn/
│           ├── MainActivity.kt           # MODIFIED: Channel registration + IPC
│           ├── service/
│           │   └── ArmaVpnService.kt     # NEW: VpnService (separate process)
│           ├── core/
│           │   └── XrayCoreManager.kt    # NEW: libv2ray AAR wrapper
│           ├── ipc/
│           │   └── ServiceConnection.kt  # NEW: IPC bridge to VPN process
│           ├── monitor/
│           │   └── TrafficMonitor.kt     # NEW: Stats polling + notification updates
│           └── notification/
│               └── VpnNotificationManager.kt  # NEW: Foreground service notification
```

### Pattern 1: Two-Hop IPC Bridge (Cross-Process Platform Channels)

**What:** D-06 requires separate process, D-08 requires MethodChannel/EventChannel. These conflict because Flutter platform channels operate within a single process. The solution is a two-hop bridge: Flutter ↔ MainActivity (MethodChannel/EventChannel in main process) ↔ ArmaVpnService (Messenger/Broadcast in VPN process).

**When to use:** Always — this is the architectural backbone of the entire phase.

**How it works:**
```
┌───────────────────────────────────┐
│     Flutter (Main Process)        │
│                                   │
│  MethodChannel ──→ MainActivity   │
│  EventChannel  ←── MainActivity   │
└───────────┬───────────────────────┘
            │ Messenger / BroadcastReceiver
            │ (standard Android IPC)
┌───────────▼───────────────────────┐
│     VPN Process (:vpn_process)    │
│                                   │
│  ArmaVpnService                   │
│    ├── XrayCoreManager            │
│    ├── TrafficMonitor             │
│    └── VpnNotificationManager     │
└───────────────────────────────────┘
```

**Implementation detail:**
```kotlin
// MainActivity.kt — Main process side
class MainActivity : FlutterActivity() {
    private val methodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, "com.arma.vpn/method")
    private var eventSink: EventChannel.EventSink? = null
    
    // Messenger to communicate with VPN process
    private var vpnServiceMessenger: Messenger? = null
    private val incomingHandler = Handler(Looper.getMainLooper()) { msg ->
        when (msg.what) {
            MSG_VPN_STATUS -> {
                val status = msg.data.getString("status")
                eventSink?.success(mapOf("type" to "status", "state" to status))
            }
            MSG_TRAFFIC_STATS -> {
                val up = msg.data.getLong("uplink")
                val down = msg.data.getLong("downlink")
                eventSink?.success(mapOf("type" to "stats", "uplink" to up, "downlink" to down))
            }
        }
        true
    }
    
    // ServiceConnection for binding to VPN process
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            vpnServiceMessenger = Messenger(service)
            // Register this process as reply target
            val msg = Message.obtain(null, MSG_REGISTER_CLIENT)
            msg.replyTo = Messenger(incomingHandler)
            vpnServiceMessenger?.send(msg)
        }
        override fun onServiceDisconnected(name: ComponentName?) {
            vpnServiceMessenger = null
        }
    }
}
```

[VERIFIED: ARCHITECTURE.md §Architectural Decision, PITFALLS.md §Pitfall 3]

### Pattern 2: Connection State Machine (Sealed Class)

**What:** Model VPN connection as an explicit state machine with defined transitions.

**When to use:** ConnectionNotifier, all UI that displays connection state.

```dart
// lib/features/connection/domain/entities/connection_status.dart
sealed class ConnectionStatus {
  const ConnectionStatus();
}

class Disconnected extends ConnectionStatus {
  final String? lastError;
  const Disconnected([this.lastError]);
}

class Connecting extends ConnectionStatus {
  final String serverName;
  const Connecting(this.serverName);
}

class Connected extends ConnectionStatus {
  final String serverName;
  final DateTime connectedAt;
  const Connected({required this.serverName, required this.connectedAt});
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

[VERIFIED: ARCHITECTURE.md §Pattern 3]

### Pattern 3: Xray JSON Config Builder (Pure Dart)

**What:** Build the complete Xray-core JSON config from `ServerConfig` entity + routing settings. D-02 mandates all config logic stays in Dart.

**When to use:** Before every connect — generate JSON, pass to native side.

**Key insight:** The builder must produce different JSON structures based on protocol and transport type. This is a matrix of: 4 protocols × 4 transports × 3 TLS modes = 48 combinations. Most combinations share the `streamSettings` pattern but differ in `outbounds[0].settings`.

[VERIFIED: ARCHITECTURE.md §Pattern 2, PITFALLS.md §Pitfall 13]

### Pattern 4: Native Side as Dumb Executor

**What:** The Kotlin side receives a complete JSON string and a command (start/stop). It never parses or modifies the JSON. It passes it directly to `CoreController.startLoop(json, tunFd)`.

**When to use:** All VPN commands from Flutter.

**Why:** Keeps testable logic in Dart. The native side is a thin bridge — easy to debug, hard to break.

[VERIFIED: CONTEXT.md D-02, ARCHITECTURE.md §Anti-Pattern 1]

### Anti-Patterns to Avoid

- **Building config in Kotlin:** D-02 explicitly forbids this. All Xray JSON construction must be in Dart.
- **Multiple MethodChannels:** Use single `com.arma.vpn/method` for all commands. Single `com.arma.vpn/vpn_status` EventChannel for all streaming data.
- **Holding VPN state in Dart only:** Native side is source of truth. On app resume, query `isRunning` via MethodChannel to re-sync. (Pitfall from ARCHITECTURE.md §Anti-Pattern 3)
- **Running VPN in main process:** D-06 forbids this. Go panics must not crash Flutter UI.
- **Closing TUN fd before stopSelf():** D-09 explicitly states shutdown order. (Pitfall #1)

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Xray protocol engine | Custom protocol implementation | AndroidLibXrayLite AAR | Battle-tested in 53k+ star V2rayNG. Protocol implementation from scratch is out of scope. |
| TUN → proxy bridging | Custom tun2socks | AAR's internal tun2socks (hev-socks5-tunnel) | The AAR handles TUN fd → SOCKS5 internally. No need for separate tun2socks binary. |
| Geo-routing databases | Custom IP/domain classification | Loyalsoldier/v2ray-rules-dat geoip.dat + geosite.dat | Community-maintained, used by V2rayNG, updated weekly. |
| Notification management (VPN process) | Flutter notification plugin | Native NotificationCompat.Builder in Kotlin | Flutter plugins run in main process; VPN notification must be in `:vpn_process`. |
| Speed formatting | Manual string formatting | Utility function with KB/MB/GB tiers | Simple but error-prone with localization. Build once, test once. |
| JSON serialization for Xray config | Manual Map construction | json_serializable with Dart model classes | Prevents typos in field names, ensures type safety. |

**Key insight:** The AAR is the biggest "don't hand-roll" — it encapsulates ~200k lines of Go code (Xray-core + dependencies). Treat it as a black box with a 6-method API.

## Xray JSON Config — Complete Reference

### Full Config Structure

```json
{
  "log": {
    "loglevel": "warning"
  },
  "stats": {},
  "policy": {
    "levels": {
      "0": {
        "statsUserUplink": true,
        "statsUserDownlink": true
      }
    },
    "system": {
      "statsOutboundUplink": true,
      "statsOutboundDownlink": true
    }
  },
  "dns": { /* see DNS section */ },
  "inbounds": [ /* see Inbounds section */ ],
  "outbounds": [ /* see Outbounds section */ ],
  "routing": { /* see Routing section */ }
}
```

**Critical:** The `stats` and `policy` sections MUST be present for `QueryStats()` to return traffic data. Without them, traffic monitoring returns 0. [VERIFIED: ARCHITECTURE.md, V2rayNG config patterns]

### Inbounds (SOCKS proxy for TUN)

```json
{
  "inbounds": [
    {
      "tag": "socks-in",
      "protocol": "socks",
      "listen": "127.0.0.1",
      "port": 10808,
      "settings": {
        "auth": "noauth",
        "udp": true,
        "userLevel": 0
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
        "metadataOnly": false,
        "routeOnly": false
      }
    }
  ]
}
```

**Note on sniffing:** `destOverride` with `["http", "tls", "quic"]` enables protocol detection to override DNS-based routing. This prevents DNS leaks (Pitfall #8) by using the actual domain from TLS ClientHello / HTTP Host header rather than the DNS-resolved IP. [ASSUMED — standard V2rayNG default, verify against current v2rayNG source]

### Protocol-Specific Outbound Configs

#### VLESS (including Reality + XTLS-Vision)

```json
{
  "tag": "proxy",
  "protocol": "vless",
  "settings": {
    "vnext": [{
      "address": "{ServerConfig.address}",
      "port": "{ServerConfig.port}",
      "users": [{
        "id": "{ServerConfig.uuid}",
        "encryption": "none",
        "flow": "{ServerConfig.flow ?? ''}"
      }]
    }]
  },
  "streamSettings": { /* see transport */ }
}
```

**VLESS-specific notes:**
- `encryption` is always `"none"` for VLESS (encryption is handled by transport layer).
- `flow`: Must be `"xtls-rprx-vision"` when using Reality or XTLS transport. Must be empty string `""` for other transports (WebSocket, gRPC, HTTP/2). Setting flow on non-XTLS transports causes connection failure.
- Reality requires `realitySettings` instead of `tlsSettings` in `streamSettings`.

[VERIFIED: PITFALLS.md §Pitfall 13, ARCHITECTURE.md]

#### VMess

```json
{
  "tag": "proxy",
  "protocol": "vmess",
  "settings": {
    "vnext": [{
      "address": "{ServerConfig.address}",
      "port": "{ServerConfig.port}",
      "users": [{
        "id": "{ServerConfig.uuid}",
        "alterId": "{ServerConfig.alterId}",
        "security": "{ServerConfig.encryption ?? 'auto'}"
      }]
    }]
  },
  "streamSettings": { /* see transport */ }
}
```

**VMess-specific notes:**
- `security`: defaults to `"auto"` which lets Xray-core choose optimal encryption.
- `alterId`: defaults to `0` for AEAD-based VMess (modern). Non-zero values use legacy encryption.

[VERIFIED: PITFALLS.md §Pitfall 13]

#### Trojan

```json
{
  "tag": "proxy",
  "protocol": "trojan",
  "settings": {
    "servers": [{
      "address": "{ServerConfig.address}",
      "port": "{ServerConfig.port}",
      "password": "{ServerConfig.password}"
    }]
  },
  "streamSettings": { /* see transport */ }
}
```

**Trojan-specific notes:**
- Uses `servers[]` NOT `vnext[]` — this is a common bug source.
- Password goes in `settings.servers[0].password`.
- Trojan typically uses TLS — `security` should default to `"tls"` if not specified.

[VERIFIED: PITFALLS.md §Pitfall 13]

#### Shadowsocks

```json
{
  "tag": "proxy",
  "protocol": "shadowsocks",
  "settings": {
    "servers": [{
      "address": "{ServerConfig.address}",
      "port": "{ServerConfig.port}",
      "method": "{ServerConfig.method}",
      "password": "{ServerConfig.password}"
    }]
  },
  "streamSettings": { /* see transport */ }
}
```

**Shadowsocks-specific notes:**
- Uses `servers[]` like Trojan.
- `method` is the encryption cipher (e.g., `"aes-256-gcm"`, `"chacha20-ietf-poly1305"`).
- Phase 1 already validates method against whitelist of 9 known ciphers.

[VERIFIED: PITFALLS.md §Pitfall 13, codebase — shadowsocks_parser.dart]

### Transport StreamSettings

All protocols share the same `streamSettings` structure. The `network` field determines which sub-config is used:

#### TCP Transport
```json
{
  "network": "tcp",
  "security": "{tls|reality|none}",
  "tlsSettings": { /* if security=tls */ },
  "realitySettings": { /* if security=reality */ },
  "tcpSettings": {
    "header": {
      "type": "none"
    }
  }
}
```

#### WebSocket Transport
```json
{
  "network": "ws",
  "security": "{tls|none}",
  "tlsSettings": { /* if security=tls */ },
  "wsSettings": {
    "path": "{ServerConfig.path ?? '/'}",
    "headers": {
      "Host": "{ServerConfig.host ?? ServerConfig.address}"
    }
  }
}
```

#### gRPC Transport
```json
{
  "network": "grpc",
  "security": "{tls|reality|none}",
  "tlsSettings": { /* if security=tls */ },
  "realitySettings": { /* if security=reality */ },
  "grpcSettings": {
    "serviceName": "{ServerConfig.serviceName ?? ''}",
    "authority": "{ServerConfig.authority ?? ''}",
    "multiMode": false
  }
}
```

#### HTTP/2 Transport
```json
{
  "network": "h2",
  "security": "tls",
  "tlsSettings": { /* always tls for h2 */ },
  "httpSettings": {
    "host": ["{ServerConfig.host ?? ServerConfig.address}"],
    "path": "{ServerConfig.path ?? '/'}"
  }
}
```

### TLS Settings

```json
{
  "tlsSettings": {
    "serverName": "{ServerConfig.sni ?? ServerConfig.address}",
    "allowInsecure": false,
    "alpn": "{ServerConfig.alpn?.split(',') ?? []}",
    "fingerprint": "{ServerConfig.fingerprint ?? 'chrome'}"
  }
}
```

### Reality Settings

```json
{
  "realitySettings": {
    "serverName": "{ServerConfig.sni ?? ServerConfig.address}",
    "fingerprint": "{ServerConfig.fingerprint ?? 'chrome'}",
    "publicKey": "{ServerConfig.publicKey}",
    "shortId": "{ServerConfig.shortId ?? ''}",
    "spiderX": "{ServerConfig.spiderX ?? ''}"
  }
}
```

### Direct and Block Outbounds

```json
[
  {
    "tag": "direct",
    "protocol": "freedom",
    "settings": {}
  },
  {
    "tag": "block",
    "protocol": "blackhole",
    "settings": {
      "response": {
        "type": "http"
      }
    }
  }
]
```

### DNS Configuration (Split DNS — D-11)

```json
{
  "dns": {
    "hosts": {
      "dns.google": "8.8.8.8"
    },
    "servers": [
      {
        "address": "https://1.1.1.1/dns-query",
        "domains": ["geosite:geolocation-!cn"],
        "expectIPs": []
      },
      {
        "address": "223.5.5.5",
        "domains": ["geosite:cn"],
        "expectIPs": ["geoip:cn"],
        "port": 53
      },
      "localhost"
    ]
  }
}
```

**Split DNS strategy:** Remote DNS (DoH via proxy) for foreign domains. Direct DNS for domestic domains. `localhost` as fallback. For Arma, since the target is general (not China-specific), use:
- Primary: `"https://1.1.1.1/dns-query"` or `"1.1.1.1"` for all proxied domains
- Direct: `"localhost"` for private/LAN domains
- This prevents DNS leaks (Pitfall #8) while keeping LAN resolution working.

[VERIFIED: PITFALLS.md §Pitfall 8, ARCHITECTURE.md]

### Routing Configuration (LAN Bypass — D-12)

```json
{
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "outboundTag": "direct",
        "ip": ["geoip:private"]
      },
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": ["geosite:private"]
      },
      {
        "type": "field",
        "outboundTag": "proxy",
        "port": "0-65535"
      }
    ]
  }
}
```

**Routing notes:**
- `domainStrategy: "IPIfNonMatch"` means: try domain-based rules first, if no match, resolve to IP and try IP rules.
- `geoip:private` covers 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16, and other RFC1918 ranges.
- `geosite:private` covers `localhost`, `.local`, `.lan` etc.
- Default: all other traffic goes through `proxy` outbound.

[VERIFIED: ARCHITECTURE.md §Pattern 2 example config]

### ServerConfig → JSON Field Mapping

| ServerConfig Field | Xray JSON Path | Condition |
|---|---|---|
| `address` | `outbounds[0].settings.vnext[0].address` or `servers[0].address` | `vnext` for VLESS/VMess, `servers` for Trojan/SS |
| `port` | `outbounds[0].settings.vnext[0].port` or `servers[0].port` | Same as above |
| `uuid` | `outbounds[0].settings.vnext[0].users[0].id` | VLESS, VMess only |
| `password` | `outbounds[0].settings.servers[0].password` | Trojan, Shadowsocks only |
| `encryption` | `outbounds[0].settings.vnext[0].users[0].security` | VMess only (default "auto") |
| `network` | `outbounds[0].streamSettings.network` | All protocols |
| `security` | `outbounds[0].streamSettings.security` | All protocols |
| `sni` | `streamSettings.tlsSettings.serverName` or `realitySettings.serverName` | When security=tls or reality |
| `host` | `wsSettings.headers.Host` or `httpSettings.host[0]` | When network=ws or h2 |
| `path` | `wsSettings.path` or `httpSettings.path` | When network=ws or h2 |
| `alpn` | `tlsSettings.alpn` (split on comma → array) | When security=tls |
| `fingerprint` | `tlsSettings.fingerprint` or `realitySettings.fingerprint` | When security=tls or reality |
| `flow` | `outbounds[0].settings.vnext[0].users[0].flow` | VLESS only, only with XTLS |
| `alterId` | `outbounds[0].settings.vnext[0].users[0].alterId` | VMess only |
| `serviceName` | `grpcSettings.serviceName` | When network=grpc |
| `authority` | `grpcSettings.authority` | When network=grpc |
| `publicKey` | `realitySettings.publicKey` | When security=reality |
| `shortId` | `realitySettings.shortId` | When security=reality |
| `spiderX` | `realitySettings.spiderX` | When security=reality |
| `method` | `outbounds[0].settings.servers[0].method` | Shadowsocks only |

## Platform Channel Contract

### MethodChannel: `com.arma.vpn/method`

| Method | Arguments | Returns | Description |
|--------|-----------|---------|-------------|
| `startVpn` | `{"config": String, "serverName": String}` | `bool` | Start VPN with Xray JSON config. serverName used for notification. |
| `stopVpn` | none | `bool` | Stop VPN, following D-09 shutdown order |
| `isRunning` | none | `bool` | Check if core is active (use on app resume to re-sync state) |
| `getVersion` | none | `String` | Xray-core version string via `Libv2ray.checkVersionX()` |
| `requestVpnPermission` | none | `bool` | Trigger VPN permission dialog (Pitfall #4 — Activity result flow) |

### EventChannel: `com.arma.vpn/vpn_status`

Single EventChannel streaming typed events as `Map<String, dynamic>`:

```dart
// Connection state changes
{"type": "status", "state": "connecting"|"connected"|"disconnected"|"error", "message": "..."}

// Traffic stats (emitted every 1 second while connected)
{"type": "stats", "uplink": int, "downlink": int}  // bytes per second
```

[VERIFIED: ARCHITECTURE.md §Platform Channel Contract]

## VpnService Implementation Details

### AndroidManifest.xml — Required Changes

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_SPECIAL_USE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <application ...>
        <activity android:name=".MainActivity" ... />

        <!-- VPN Service — SEPARATE PROCESS (D-06) -->
        <service
            android:name=".service.ArmaVpnService"
            android:process=":vpn_process"
            android:permission="android.permission.BIND_VPN_SERVICE"
            android:foregroundServiceType="specialUse"
            android:exported="false">
            <intent-filter>
                <action android:name="android.net.VpnService" />
            </intent-filter>
            <meta-data
                android:name="android.net.VpnService.SUPPORTS_ALWAYS_ON"
                android:value="true" />
            <property
                android:name="android.app.PROPERTY_SPECIAL_USE_FGS_SUBTYPE"
                android:value="vpn" />
        </service>
    </application>
</manifest>
```

[VERIFIED: PITFALLS.md §Pitfall 5 (Android 14+), §Pitfall 17 (Always-On)]

### TUN Interface Parameters

```kotlin
private fun configureTunInterface(): ParcelFileDescriptor {
    val builder = Builder()
    builder.setMtu(9000)                               // V2rayNG default, high MTU for performance
    builder.addAddress("26.26.26.1", 30)               // Private TUN IPv4 address
    builder.addRoute("0.0.0.0", 0)                     // Route ALL IPv4 traffic through TUN

    // LAN bypass (D-12) — done via Xray routing rules, not VPN builder
    // All traffic goes through TUN, Xray routing decides proxy vs direct

    // DNS servers (tunneled through VPN)
    builder.addDnsServer("1.1.1.1")
    builder.addDnsServer("8.8.8.8")

    // IPv6 (prevent leakage — Pitfall #21)
    builder.addAddress("da26:2626::1", 126)            // TUN IPv6 address
    builder.addRoute("::", 0)                           // Route ALL IPv6 through TUN

    builder.setSession("Arma VPN")

    // CRITICAL: Always exclude self to prevent routing loop (Pitfall #12)
    builder.addDisallowedApplication(packageName)

    return builder.establish()
        ?: throw IllegalStateException("VPN builder.establish() returned null")
}
```

**Why route ALL traffic (including LAN) through TUN and let Xray routing handle bypass:**
- VPN builder `addRoute` exclusions are coarse and can't be changed without restarting VPN.
- Xray routing rules can be fine-grained and are part of the JSON config built in Dart.
- D-12 LAN bypass is implemented via `geoip:private → direct` routing rule in Xray config.

**Alternative approach (VPN builder-level LAN bypass):** If we wanted to bypass LAN at the TUN level instead:
```kotlin
// Instead of addRoute("0.0.0.0", 0), add specific routes excluding LAN:
builder.addRoute("1.0.0.0", 8)     // 1.x.x.x
builder.addRoute("2.0.0.0", 7)     // 2-3.x.x.x
// ... many more routes to cover 0.0.0.0/0 minus private ranges
```
This is more complex and V2rayNG handles it by routing all and letting Xray decide. [ASSUMED — recommend the simpler approach]

### VPN Shutdown Order (D-09)

```kotlin
private fun stopAllServices() {
    isRunning = false
    
    // 1. Stop xray-core loop FIRST
    coreController?.stopLoop()
    
    // 2. Stop the Android service (calls onDestroy)
    stopSelf()
    
    // 3. LAST: close the TUN file descriptor
    try {
        tunInterface?.close()
    } catch (e: Exception) {
        Log.w(TAG, "Error closing TUN interface", e)
    }
    tunInterface = null
}
```

**The shutdown order is critical.** V2rayNG source code has an explicit comment: *"stopSelf has to be called ahead of mInterface.close(). otherwise v2ray core cannot be stopped."* [VERIFIED: PITFALLS.md §Pitfall 1]

### Go Runtime Initialization

```kotlin
// MUST be called before any Libv2ray function (Pitfall #6)
object XrayCoreInitializer {
    private val initialized = AtomicBoolean(false)
    
    fun initialize(context: Context) {
        if (initialized.compareAndSet(false, true)) {
            try {
                // Set Android context for Go runtime JNI
                go.Seq.setContext(context.applicationContext)
                
                // Copy geo assets from APK to internal storage
                val assetPath = copyAssetsToInternal(context)
                
                // Initialize Xray-core environment
                Libv2ray.initCoreEnv(assetPath, "")
            } catch (e: Exception) {
                initialized.set(false)
                throw RuntimeException("Failed to initialize Xray core", e)
            }
        }
    }
    
    private fun copyAssetsToInternal(context: Context): String {
        val targetDir = File(context.filesDir, "xray-assets")
        targetDir.mkdirs()
        for (file in listOf("geoip.dat", "geosite.dat")) {
            val target = File(targetDir, file)
            if (!target.exists()) {
                context.assets.open(file).use { input ->
                    FileOutputStream(target).use { output ->
                        input.copyTo(output)
                    }
                }
            }
        }
        return targetDir.absolutePath
    }
}
```

[VERIFIED: PITFALLS.md §Pitfall 6, STACK.md §AAR API]

### VPN Permission Flow (Pitfall #4)

```kotlin
class MainActivity : FlutterActivity() {
    private var vpnPermissionResult: MethodChannel.Result? = null
    
    private fun requestVpnPermission(result: MethodChannel.Result) {
        val intent = VpnService.prepare(this)
        if (intent != null) {
            vpnPermissionResult = result
            startActivityForResult(intent, VPN_PERMISSION_REQUEST_CODE)
        } else {
            // Permission already granted
            result.success(true)
        }
    }
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == VPN_PERMISSION_REQUEST_CODE) {
            vpnPermissionResult?.success(resultCode == RESULT_OK)
            vpnPermissionResult = null
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }
    
    companion object {
        private const val VPN_PERMISSION_REQUEST_CODE = 24
    }
}
```

[VERIFIED: PITFALLS.md §Pitfall 4]

### Network Change Detection (D-10, MON-04)

```kotlin
// In ArmaVpnService (VPN process)
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
        // Trigger reconnect — restart xray-core loop
        reconnect()
    }
}

private fun registerNetworkCallback() {
    val connectivityManager = getSystemService(ConnectivityManager::class.java)
    val request = NetworkRequest.Builder()
        .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        .addCapability(NetworkCapabilities.NET_CAPABILITY_NOT_VPN)  // Important: exclude VPN itself!
        .build()
    // Use requestNetwork, NOT registerDefaultNetworkCallback
    // (default callback returns VPN interface itself → loop)
    connectivityManager.requestNetwork(request, networkCallback)
}
```

**Critical:** Use `requestNetwork` with `NET_CAPABILITY_NOT_VPN`, NOT `registerDefaultNetworkCallback`. The default callback returns the VPN interface itself, creating a loop. [VERIFIED: PITFALLS.md §Pitfall 9]

### Foreground Notification

```kotlin
object VpnNotificationManager {
    private const val CHANNEL_ID = "arma_vpn_service"
    private const val NOTIFICATION_ID = 1
    
    fun createNotificationChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            "VPN Service",
            NotificationManager.IMPORTANCE_LOW  // Low = no sound, shows in status bar
        ).apply {
            description = "Shows VPN connection status"
            setShowBadge(false)
        }
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }
    
    fun buildNotification(
        context: Context,
        status: String,
        serverName: String,
        uploadSpeed: String = "",
        downloadSpeed: String = ""
    ): Notification {
        val pendingIntent = PendingIntent.getActivity(
            context, 0,
            context.packageManager.getLaunchIntentForPackage(context.packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val contentText = if (uploadSpeed.isNotEmpty()) {
            "↓ $downloadSpeed  ↑ $uploadSpeed"
        } else {
            status
        }
        
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_vpn_key)  // Need to add this drawable
            .setContentTitle("Arma VPN — $serverName")
            .setContentText(contentText)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }
}
```

**Notes:**
- `IMPORTANCE_LOW` prevents notification sound on every speed update.
- `setOngoing(true)` makes notification persistent (can't swipe away).
- Must call `startForeground(NOTIFICATION_ID, notification)` within 5 seconds of service start.
- Notification channel must be created before first notification (Pitfall #16).

[VERIFIED: PITFALLS.md §Pitfall 16, ARCHITECTURE.md §Foreground Service Notification]

### Gradle Configuration for AAR

```kotlin
// android/app/build.gradle.kts
android {
    // ... existing config
    
    packaging {
        jniLibs {
            useLegacyPackaging = true  // Required for Go native libs in AAR
        }
    }
}

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
}
```

**AAR placement:** `android/app/libs/libv2ray.aar`

The `useLegacyPackaging = true` is needed because Go's gomobile compiles native `.so` files that must be extracted at install time rather than loaded from the APK. [ASSUMED — based on typical gomobile AAR behavior]

### StrictMode in VPN Process

```kotlin
// In ArmaVpnService.onCreate()
override fun onCreate() {
    super.onCreate()
    // Go runtime performs network operations during init (Pitfall #15)
    val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
    StrictMode.setThreadPolicy(policy)
}
```

[VERIFIED: PITFALLS.md §Pitfall 15]

## Dart-Side Implementation Patterns

### VpnPlatformService

```dart
/// Single point of contact for all native VPN operations.
class VpnPlatformService {
  static const _methodChannel = MethodChannel('com.arma.vpn/method');
  static const _eventChannel = EventChannel('com.arma.vpn/vpn_status');

  Future<bool> startVpn(String configJson, String serverName) async {
    return await _methodChannel.invokeMethod<bool>(
      'startVpn', {'config': configJson, 'serverName': serverName}
    ) ?? false;
  }

  Future<bool> stopVpn() async {
    return await _methodChannel.invokeMethod<bool>('stopVpn') ?? false;
  }

  Future<bool> get isRunning async {
    return await _methodChannel.invokeMethod<bool>('isRunning') ?? false;
  }
  
  Future<bool> requestVpnPermission() async {
    return await _methodChannel.invokeMethod<bool>('requestVpnPermission') ?? false;
  }

  Stream<Map<String, dynamic>> get vpnEvents {
    return _eventChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
  }
}
```

### ConnectionNotifier (Riverpod)

```dart
@riverpod
class ConnectionNotifier extends _$ConnectionNotifier {
  late final VpnPlatformService _platformService;

  @override
  ConnectionStatus build() {
    _platformService = VpnPlatformService();
    
    // Listen to native events and update state
    _platformService.vpnEvents
        .where((e) => e['type'] == 'status')
        .listen(_handleStatusEvent);
    
    // Re-sync on build (app resume)
    _syncWithNative();
    
    return const Disconnected();
  }

  Future<void> connect(ServerConfig server) async {
    if (state is Connecting || state is Connected) return;
    
    state = Connecting(server.name);
    
    // 1. Request permission if needed
    final hasPermission = await _platformService.requestVpnPermission();
    if (!hasPermission) {
      state = const Disconnected('VPN permission denied');
      return;
    }
    
    // 2. Build Xray JSON config
    final configJson = XrayConfigBuilder.build(server);
    
    // 3. Start VPN
    final started = await _platformService.startVpn(configJson, server.name);
    if (!started) {
      state = const Disconnected('Failed to start VPN');
    }
    // Connected state will be set by EventChannel callback
  }

  Future<void> disconnect() async {
    if (state is Disconnected || state is Disconnecting) return;
    state = const Disconnecting();
    await _platformService.stopVpn();
    // Disconnected state will be set by EventChannel callback
  }
  
  Future<void> _syncWithNative() async {
    final running = await _platformService.isRunning;
    if (running && state is Disconnected) {
      // App was killed and restored — VPN is still running
      state = Connected(serverName: 'Active', connectedAt: DateTime.now());
    }
  }
}
```

### Speed Formatter Utility

```dart
/// Formats bytes per second into human-readable speed string.
String formatSpeed(int bytesPerSecond) {
  if (bytesPerSecond < 1024) {
    return '$bytesPerSecond B/s';
  } else if (bytesPerSecond < 1024 * 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
  } else if (bytesPerSecond < 1024 * 1024 * 1024) {
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  } else {
    return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }
}
```

### Connect Button Animation (D-03)

```dart
/// Extended ConnectButton with state-based animations.
/// Grey circle (disconnected) → Pulsing teal ring (connecting) → Solid teal glow (connected).
class ConnectButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionProvider);
    final colorScheme = Theme.of(context).colorScheme;
    
    final (color, isAnimating) = switch (status) {
      Disconnected() => (Colors.grey, false),
      Connecting() => (AppColors.teal, true),    // Pulsing animation
      Connected() => (AppColors.teal, false),     // Solid glow
      Disconnecting() => (Colors.grey, false),
    };
    
    return GestureDetector(
      onTap: () => _handleTap(ref, status),
      child: Container(
        width: 120, height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: status is Connected
            ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 5)]
            : null,
        ),
        child: Icon(Icons.power_settings_new, color: Colors.white, size: 48),
      )
      .animate(target: isAnimating ? 1 : 0)
      .shimmer(duration: 1.5.seconds, color: AppColors.teal.withValues(alpha: 0.3))
      .then()
      .animate(onPlay: (c) => c.repeat())
      .scale(begin: Offset(1.0, 1.0), end: Offset(1.05, 1.05), duration: 800.ms)
      .then()
      .scale(begin: Offset(1.05, 1.05), end: Offset(1.0, 1.0), duration: 800.ms),
    );
  }
}
```

## Traffic Monitoring

### QueryStats API

The AAR's `CoreController.queryStats(tag, direction)` returns cumulative bytes and resets the counter. This means:
- Call `queryStats("proxy", "uplink")` → returns bytes uploaded since last call
- Call `queryStats("proxy", "downlink")` → returns bytes downloaded since last call
- The tag `"proxy"` must match the outbound tag in the Xray JSON config
- Polling interval: 1 second (D-05 says "real-time", Pitfall #22 says max 1-2 Hz)

```kotlin
// TrafficMonitor.kt — runs in VPN process
class TrafficMonitor(
    private val controller: CoreController,
    private val onStats: (uplink: Long, downlink: Long) -> Unit
) {
    private var timer: Timer? = null
    
    fun start() {
        timer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    val up = controller.queryStats("proxy", "uplink")
                    val down = controller.queryStats("proxy", "downlink")
                    onStats(up, down)
                }
            }, 0, 1000)  // Every 1 second
        }
    }
    
    fun stop() {
        timer?.cancel()
        timer = null
    }
}
```

**Critical:** The `stats` and `policy` sections in Xray JSON config MUST be present for QueryStats to work. Without `"statsOutboundUplink": true`, QueryStats returns 0. [VERIFIED: Xray-core documentation pattern]

## AAR Integration

### Obtaining the AAR (D-01)

Per D-01, use pre-built AAR from AndroidLibXrayLite releases. Steps:

1. **Download:** Get `libv2ray.aar` from https://github.com/ArmavVPN/AndroidLibXrayLite/releases (or fall back to https://github.com/2dust/AndroidLibXrayLite/releases)
2. **Place:** `android/app/libs/libv2ray.aar`
3. **Configure gradle:** Add `implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))` to dependencies
4. **Verify:** Build project, import `libv2ray.Libv2ray` in Kotlin — should compile

**If no release exists at ArmavVPN fork**, build from 2dust's source:
```bash
git clone https://github.com/2dust/AndroidLibXrayLite.git
cd AndroidLibXrayLite
go mod tidy -v
gomobile bind -v -androidapi 21 -ldflags='-s -w' ./
# Output: libv2ray.aar (~30-50MB)
```

[VERIFIED: STACK.md §AAR Build Steps]

### AAR API Surface

```kotlin
import libv2ray.CoreController
import libv2ray.CoreCallbackHandler
import libv2ray.Libv2ray

// Initialize (call once)
Libv2ray.initCoreEnv(assetPath: String, xudpKey: String)

// Create controller with callbacks
val controller = Libv2ray.newCoreController(object : CoreCallbackHandler {
    override fun onEmitStatus(p0: Long, p1: String?): Long {
        // p0 = status code, p1 = status message
        // Emit to Flutter via Messenger/Broadcast
        return 0
    }
    // ... other callbacks
})

// Start with config + TUN fd
controller.startLoop(configJson: String, tunFd: Int)

// Stop
controller.stopLoop()

// Query stats (returns bytes, resets counter)
controller.queryStats(tag: String, direction: String): Long

// Measure latency
controller.measureDelay(url: String): Long

// Check running
controller.isRunning: Boolean

// Static utilities
Libv2ray.checkVersionX(): String
Libv2ray.measureOutboundDelay(configJson: String, url: String): Long
```

[VERIFIED: STACK.md §Go-to-Kotlin API Surface]

### Geo-Data Asset Files

Two files must be bundled in `android/app/src/main/assets/`:

| File | Size | Source | Purpose |
|------|------|--------|---------|
| `geoip.dat` | ~18 MB | Loyalsoldier/v2ray-rules-dat releases | IP-based routing (LAN bypass, country routing) |
| `geosite.dat` | ~8.6 MB | Loyalsoldier/v2ray-rules-dat releases | Domain-based routing (split DNS) |

These are copied from APK assets to internal storage at first launch via `XrayCoreInitializer`. The path is passed to `Libv2ray.initCoreEnv()`.

**APK size impact:** +~27 MB. This is acceptable for a VPN app. V2rayNG bundles these files. [VERIFIED: PITFALLS.md §Pitfall 11, STACK.md]

## Common Pitfalls

### Pitfall 1: VPN Service Shutdown Order
**What goes wrong:** Closing TUN fd before stopSelf() causes port-in-use errors on next connect.
**Why it happens:** Go core's socket operations get interrupted preventing clean shutdown.
**How to avoid:** Always: stopLoop() → stopSelf() → close TUN fd. (D-09)
**Warning signs:** Rapid toggle on/off fails on 3rd-4th attempt.
[VERIFIED: PITFALLS.md §Pitfall 1]

### Pitfall 2: Cross-Process Platform Channels
**What goes wrong:** MethodChannel/EventChannel silently fail when VpnService runs in separate process.
**Why it happens:** Platform channels are per-process. Flutter engine only exists in main process.
**How to avoid:** Two-hop bridge: Flutter ↔ MainActivity (channels) ↔ VpnService (Messenger/Broadcast).
**Warning signs:** `invokeMethod` returns null or throws MissingPluginException for VPN commands.
[VERIFIED: PITFALLS.md §Pitfall 3, ARCHITECTURE.md §Architectural Decision]

### Pitfall 3: Android 14+ Foreground Service Permissions
**What goes wrong:** SecurityException on Android 14+ when starting foreground service.
**Why it happens:** Missing FOREGROUND_SERVICE_SPECIAL_USE permission and foregroundServiceType.
**How to avoid:** Add all three: permission, foregroundServiceType="specialUse", PROPERTY_SPECIAL_USE_FGS_SUBTYPE metadata.
**Warning signs:** Works on Android 13, crashes on Android 14.
[VERIFIED: PITFALLS.md §Pitfall 5]

### Pitfall 4: Go Seq.setContext() Not Called
**What goes wrong:** JNI null pointer crash on first Go function call.
**Why it happens:** Go runtime needs Android context before any JNI marshaling.
**How to avoid:** Call `go.Seq.setContext(applicationContext)` before any Libv2ray call. Use AtomicBoolean for thread-safe single init.
**Warning signs:** Opaque native crash with no useful stack trace at app startup.
[VERIFIED: PITFALLS.md §Pitfall 6]

### Pitfall 5: VLESS Flow Field Misconfiguration
**What goes wrong:** VLESS connections fail silently when `flow` is set for non-XTLS transports.
**Why it happens:** `xtls-rprx-vision` flow only works with TCP transport + TLS/Reality. Setting it on WS/gRPC/H2 causes handshake failure.
**How to avoid:** Only set `flow` when protocol=VLESS AND network=tcp AND (security=tls OR security=reality).
**Warning signs:** VLESS+TCP works but VLESS+WS fails.
[VERIFIED: PITFALLS.md §Pitfall 13]

### Pitfall 6: Missing stats/policy Config Sections
**What goes wrong:** Traffic monitoring always shows 0 bytes.
**Why it happens:** QueryStats API requires `stats: {}` and `policy.system.statsOutboundUplink/Downlink: true` in Xray config.
**How to avoid:** Always include stats and policy sections in generated JSON config.
**Warning signs:** Connection works but speed displays show "0 B/s".
[VERIFIED: Xray-core config documentation]

### Pitfall 7: DNS Leak Through VPN
**What goes wrong:** DNS queries bypass proxy, revealing browsing to ISP.
**Why it happens:** Not configuring Xray DNS section or not adding DNS servers to VpnService.Builder.
**How to avoid:** Split DNS config (D-11) + sniffing enabled + addDnsServer in VPN builder.
**Warning signs:** DNS leak test shows ISP DNS servers.
[VERIFIED: PITFALLS.md §Pitfall 8]

### Pitfall 8: Network Switch Stalls Connection
**What goes wrong:** VPN silently stops working when switching WiFi ↔ cellular.
**Why it happens:** Missing `setUnderlyingNetworks()` call in ConnectivityManager callback.
**How to avoid:** Register NetworkCallback with NET_CAPABILITY_NOT_VPN, call setUnderlyingNetworks on every change.
**Warning signs:** Must manually reconnect after network switch.
[VERIFIED: PITFALLS.md §Pitfall 9]

### Pitfall 9: Self-Routing Loop
**What goes wrong:** Connection hangs forever at "Connecting..."
**Why it happens:** VPN app's own traffic gets routed through TUN → back to itself.
**How to avoid:** Always call `builder.addDisallowedApplication(packageName)`.
**Warning signs:** Connection never establishes, CPU usage spikes.
[VERIFIED: PITFALLS.md §Pitfall 12]

### Pitfall 10: Trojan Config Uses servers[] Not vnext[]
**What goes wrong:** Trojan connections fail with "invalid configuration" error.
**Why it happens:** Trojan and Shadowsocks use `settings.servers[]` array, unlike VLESS/VMess which use `settings.vnext[]`.
**How to avoid:** Config builder must check protocol type and use correct settings structure.
**Warning signs:** VLESS/VMess work but Trojan/SS fail.
[VERIFIED: PITFALLS.md §Pitfall 13]

## Code Examples

### Complete XrayConfigBuilder (Dart)

```dart
/// Builds complete Xray-core JSON configuration from ServerConfig.
class XrayConfigBuilder {
  XrayConfigBuilder._();

  static String build(ServerConfig server) {
    final config = {
      'log': {'loglevel': 'warning'},
      'stats': {},
      'policy': _buildPolicy(),
      'dns': _buildDns(),
      'inbounds': [_buildSocksInbound()],
      'outbounds': [
        _buildProxyOutbound(server),
        _buildDirectOutbound(),
        _buildBlockOutbound(),
      ],
      'routing': _buildRouting(),
    };
    return jsonEncode(config);
  }

  static Map<String, dynamic> _buildPolicy() => {
    'levels': {'0': {'statsUserUplink': true, 'statsUserDownlink': true}},
    'system': {'statsOutboundUplink': true, 'statsOutboundDownlink': true},
  };

  static Map<String, dynamic> _buildProxyOutbound(ServerConfig server) {
    return {
      'tag': 'proxy',
      'protocol': server.protocol.scheme == 'ss' ? 'shadowsocks' : server.protocol.scheme,
      'settings': _buildProtocolSettings(server),
      'streamSettings': _buildStreamSettings(server),
    };
  }

  static Map<String, dynamic> _buildProtocolSettings(ServerConfig server) {
    return switch (server.protocol) {
      ProtocolType.vless => {
        'vnext': [{'address': server.address, 'port': server.port, 'users': [
          {'id': server.uuid, 'encryption': 'none', 'flow': _resolveFlow(server)}
        ]}]
      },
      ProtocolType.vmess => {
        'vnext': [{'address': server.address, 'port': server.port, 'users': [
          {'id': server.uuid, 'alterId': server.alterId, 'security': server.encryption == 'none' ? 'auto' : server.encryption}
        ]}]
      },
      ProtocolType.trojan => {
        'servers': [{'address': server.address, 'port': server.port, 'password': server.password}]
      },
      ProtocolType.shadowsocks => {
        'servers': [{'address': server.address, 'port': server.port, 'method': server.method, 'password': server.password}]
      },
      ProtocolType.hysteria2 => {
        'servers': [{'address': server.address, 'port': server.port, 'password': server.password}]
      },
    };
  }

  static String _resolveFlow(ServerConfig server) {
    // Flow only applies to VLESS + TCP + (TLS or Reality)
    if (server.protocol != ProtocolType.vless) return '';
    if (server.network != 'tcp') return '';
    if (server.security != 'tls' && server.security != 'reality') return '';
    return server.flow ?? '';
  }
}
```

### ArmaVpnService Complete Skeleton (Kotlin)

```kotlin
class ArmaVpnService : VpnService() {
    private var tunInterface: ParcelFileDescriptor? = null
    private var coreController: CoreController? = null
    private var trafficMonitor: TrafficMonitor? = null
    private val incomingMessenger = Messenger(IncomingHandler())
    
    override fun onCreate() {
        super.onCreate()
        StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.Builder().permitAll().build())
        VpnNotificationManager.createNotificationChannel(this)
        XrayCoreInitializer.initialize(this)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action
        when (action) {
            ACTION_START -> {
                val config = intent.getStringExtra(EXTRA_CONFIG) ?: return START_NOT_STICKY
                val serverName = intent.getStringExtra(EXTRA_SERVER_NAME) ?: "Unknown"
                startVpn(config, serverName)
            }
            ACTION_STOP -> stopVpn()
        }
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder {
        // Return Messenger binder for IPC from main process
        return incomingMessenger.binder
    }
    
    override fun onRevoke() {
        // System revoked VPN permission
        stopVpn()
        super.onRevoke()
    }
    
    private fun startVpn(config: String, serverName: String) {
        // 1. Start foreground service with notification
        val notification = VpnNotificationManager.buildNotification(this, "Connecting...", serverName)
        startForeground(1, notification)
        
        // 2. Set up TUN interface
        tunInterface = configureTunInterface()
        
        // 3. Create and start Xray core
        coreController = Libv2ray.newCoreController(coreCallback)
        coreController?.startLoop(config, tunInterface!!.fd)
        
        // 4. Start traffic monitoring
        trafficMonitor = TrafficMonitor(coreController!!) { up, down ->
            sendStatsToMainProcess(up, down)
            updateNotification(serverName, up, down)
        }
        trafficMonitor?.start()
        
        // 5. Register network callback for auto-reconnect
        registerNetworkCallback()
        
        // 6. Notify main process of connected state
        sendStatusToMainProcess("connected")
    }
    
    private fun stopVpn() {
        trafficMonitor?.stop()
        coreController?.stopLoop()   // 1. Stop core
        stopSelf()                    // 2. Stop service
        tunInterface?.close()         // 3. LAST: close TUN
        tunInterface = null
        sendStatusToMainProcess("disconnected")
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| tun2socks external binary | hev-socks5-tunnel JNI / TUN fd pass-through | V2rayNG ~2023 | No separate process spawn, cleaner lifecycle |
| Single process VPN | Separate `:vpn_process` | V2rayNG pattern, standard | Go panics don't crash UI |
| `FOREGROUND_SERVICE` only | `FOREGROUND_SERVICE_SPECIAL_USE` | Android 14 (API 34) | Must add new permission + metadata |
| `registerDefaultNetworkCallback` | `requestNetwork` with NOT_VPN | V2rayNG fix | Prevents VPN-to-VPN routing loop |
| Xray-core separate from Go wrapper | AndroidLibXrayLite unified AAR | 2dust pattern | Single AAR includes xray-core + tun2socks + bindings |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | AAR `useLegacyPackaging = true` is required for Go native libs | Gradle Configuration | Build may fail or crash at runtime if Go .so files aren't extracted correctly |
| A2 | sniffing `destOverride: ["http", "tls", "quic"]` is the correct default for anti-DNS-leak | Inbounds Config | DNS leaks if sniffing config is wrong |
| A3 | VPN builder should route ALL traffic through TUN and let Xray routing handle LAN bypass | TUN Interface Parameters | Slight overhead routing LAN through TUN then back via direct outbound; negligible |
| A4 | `flutter_animate` is sufficient for the pulsing teal ring animation (D-03) | Connect Button Animation | May need custom AnimationController if flutter_animate lacks the exact effect |
| A5 | Pre-built AAR exists at ArmavVPN/AndroidLibXrayLite releases | AAR Integration | If no release exists, must build from 2dust's source or fork |

## Open Questions

1. **AAR Source — ArmavVPN Fork vs 2dust Original**
   - What we know: D-01 says "AndroidLibXrayLite" without specifying fork vs original
   - What's unclear: Whether ArmavVPN/AndroidLibXrayLite has pre-built release assets, or whether to use 2dust/AndroidLibXrayLite releases
   - Recommendation: Try ArmavVPN fork first, fall back to 2dust releases. Document the source URL in build instructions.

2. **Messenger vs BroadcastReceiver for Cross-Process IPC**
   - What we know: D-08 locks MethodChannel/EventChannel for Flutter-facing API. Internal IPC between processes is agent's discretion.
   - What's unclear: Whether Messenger (bound service) or BroadcastReceiver (intent-based) is more reliable for streaming traffic stats at 1 Hz.
   - Recommendation: Use Messenger (ServiceConnection + Handler) for bidirectional communication. It's lower overhead than Broadcast for high-frequency stats updates and provides a callback channel for the VPN process to push events.

3. **Notification Icon Drawable**
   - What we know: Notification requires a small icon (R.drawable.ic_vpn_key or similar).
   - What's unclear: Whether there's an existing drawable or need to create one.
   - Recommendation: Use Android's built-in `android.R.drawable.ic_lock_idle_lock` as placeholder, then replace with custom vector drawable.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Framework | ✓ | Stable | — |
| Kotlin | Android native layer | ✓ | 2.2.20 | — |
| Android SDK | Build | ✓ | compileSdk from flutter | — |
| Android NDK | AAR native libs | ✓ | From flutter.ndkVersion | — |
| Go (if building AAR) | AAR from source | — | Not checked | Use pre-built AAR (D-01) |
| gomobile (if building AAR) | AAR from source | — | Not checked | Use pre-built AAR (D-01) |
| geoip.dat | Routing rules | ✗ | Not bundled yet | Must download from Loyalsoldier releases |
| geosite.dat | Domain routing | ✗ | Not bundled yet | Must download from Loyalsoldier releases |
| libv2ray.aar | Xray-core engine | ✗ | Not in libs/ yet | Must download from AndroidLibXrayLite releases |

**Missing dependencies with no fallback:**
- `libv2ray.aar` — must be obtained before any VPN functionality works
- `geoip.dat` / `geosite.dat` — must be bundled for routing rules to work

**Missing dependencies with fallback:**
- Go/gomobile — not needed if using pre-built AAR (D-01 decision)

## Sources

### Primary (HIGH confidence)
- `.planning/research/ARCHITECTURE.md` — Complete architecture, platform channel contract, data flows, directory structure
- `.planning/research/PITFALLS.md` — 22 pitfalls with prevention code, all critical ones referenced
- `.planning/research/STACK.md` — AAR API surface, build steps, version pins
- `.planning/research/FEATURES.md` — Feature landscape and prioritization
- Android VpnService official docs — developer.android.com/reference/android/net/VpnService
- V2rayNG source code patterns — github.com/2dust/v2rayNG

### Secondary (MEDIUM confidence)
- Existing codebase analysis — ServerConfig entity, ConnectButton, dashboard layout, protocol parsers
- Xray-core config format — derived from V2rayNG config templates + Xray documentation

### Tertiary (LOW confidence)
- flutter_animate animation patterns — need to verify specific API for pulsing ring effect
- `useLegacyPackaging` gradle flag — commonly needed for Go native libs but not verified for this specific AAR

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified against prior research (STACK.md, ARCHITECTURE.md)
- Architecture: HIGH — two-hop IPC bridge pattern well-documented in V2rayNG
- Xray JSON config: HIGH — field mapping verified from ServerConfig entity + protocol parser sources
- Pitfalls: HIGH — all 10 listed pitfalls verified from PITFALLS.md with code samples
- Connect button animation: MEDIUM — flutter_animate API assumed, may need adjustment
- Cross-process IPC: MEDIUM — Messenger pattern is standard but implementation details need testing

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (30 days — VpnService API and Xray-core AAR are stable)
