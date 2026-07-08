# iOS implementation — setup & status

The iOS VPN is built on a **NEPacketTunnelProvider** app extension that runs the
Xray core, controlled from Flutter through the existing
`com.arma.vpn/method` + `com.arma.vpn/vpn_status` channels. The shared Dart layer
needs **no changes** — the iOS native side implements the same contract as Android.

> ⚠️ iOS can only be built on **macOS + Xcode** with a **paid Apple Developer
> account** (NetworkExtension + App Groups are not available on free accounts).
> None of this can be built/tested on the current Linux machine.

## What's already scaffolded (in this repo)

| File | Role | State |
|---|---|---|
| `ios/Runner/VpnChannel.swift` | Flutter ↔ `NETunnelProviderManager` bridge (start/stop/isRunning/permission/status events) | ✅ complete, core-independent |
| `ios/Runner/AppDelegate.swift` | registers `VpnChannel` on the Flutter engine | ✅ |
| `ios/Runner/Runner.entitlements` | NetworkExtension + App Group for the app | ✅ (edit App Group if needed) |
| `ios/PacketTunnel/PacketTunnelProvider.swift` | extension lifecycle; builds utun settings; starts `XrayTunnel` | ✅ complete |
| `ios/PacketTunnel/TunnelConfig.swift` | parses DNS/MTU from the Xray JSON → `NEPacketTunnelNetworkSettings` | ✅ |
| `ios/PacketTunnel/XrayTunnel.swift` | orchestrates core + tun2socks; rewrites the tun inbound → SOCKS; stats via App Group | ✅ |
| `ios/PacketTunnel/XrayCore.swift` | Xray-core (`LibXray`) seam — run/stop/stats/version/measureDelay | ⚠️ 4 calls to uncomment once the xcframework is linked |
| `ios/PacketTunnel/Tun2SocksBridge.swift` | utun ⇄ SOCKS bridge (`HevSocks5Tunnel`) + utun-fd discovery | ⚠️ 2 calls to uncomment once the pod is linked |
| `ios/Runner/XrayProbe.swift` | in-app version + latency probe (`getXrayVersion`/`measureDelay`) | ⚠️ 2 calls to uncomment |
| `ios/PacketTunnel/Info.plist` | declares the packet-tunnel provider class | ✅ |
| `ios/PacketTunnel/PacketTunnel.entitlements` | NetworkExtension + App Group for the extension | ✅ |

## Manual steps required on macOS (Xcode GUI — cannot be scripted safely)

1. **Set real bundle IDs** (currently `com.example.armaProxyVpnClient`). Suggested:
   - App: `com.arma.vpn`
   - Extension: `com.arma.vpn.PacketTunnel`  ← must equal `tunnelBundleId` in `VpnChannel.swift`
2. **Add the extension target**: Xcode → File → New → Target → *Network Extension*
   (Packet Tunnel). Name it `PacketTunnel`. Then replace the generated
   `Info.plist`/`*.entitlements`/provider with the files already in
   `ios/PacketTunnel/` (add them to the new target; remove Xcode's duplicates).
3. **App Group**: in *Signing & Capabilities* add **App Groups** →
   `group.com.arma.vpn` to **both** the Runner and PacketTunnel targets
   (must match `appGroup` in `VpnChannel.swift` and the two `.entitlements`).
4. **Network Extensions capability**: add the *Personal VPN* / *Network
   Extensions* capability to both targets; ensure provisioning profiles include
   the NetworkExtension entitlement (Apple Developer portal).
5. **Min iOS**: deployment target is `13.0`; NEPacketTunnelProvider is fine there.

## Wiring the Xray core (the remaining engineering work)

The Android side uses `libv2ray.aar` (Xray-core via gomobile). iOS needs the
equivalent **xcframework**:

1. On macOS with Go + gomobile:
   ```sh
   go install golang.org/x/mobile/cmd/gomobile@latest
   gomobile init
   # Build an iOS xcframework from your Xray binding (e.g. XTLS/libXray):
   gomobile bind -target=ios -o LibXray.xcframework github.com/xtls/libxray/...
   ```
   (Or use a prebuilt `LibXray.xcframework` from the XTLS ecosystem.)
2. Drag `LibXray.xcframework` into **both** the **PacketTunnel** target (needed
   to run the tunnel) and the **Runner** target (for `getXrayVersion` /
   `measureDelay`) — Frameworks, Embed & Sign.
3. `pod install` (the Podfile now declares `HevSocks5Tunnel` for the
   PacketTunnel target — the utun⇄SOCKS bridge).
4. The tunnel is **already implemented** (no packet plumbing left to write):
   - `PacketTunnelProvider` → `TunnelConfig` (utun settings) → `XrayTunnel`
     (rewrites the tun inbound to a local SOCKS inbound, starts the core, runs
     tun2socks over the utun fd, reports stats through the App Group).
   - The only edits are the **framework calls** marked `// ← real call` in
     `XrayCore.swift` (4), `Tun2SocksBridge.swift` (2) and `XrayProbe.swift` (2).
     Uncomment the `import LibXray` / `import HevSocks5Tunnel` lines and replace
     the placeholder `notLinked()` / commented calls with your framework's
     actual functions. Names vary by libXray version — the request/response is
     libXray's base64-JSON `CallResponse`.
5. Ship `geoip.dat` / `geosite.dat` in the extension bundle (so routing rules
   like `geoip:ru` resolve). `XrayCore.assetDir()` points at the bundle
   `resourcePath`; adjust if you place them elsewhere (e.g. the App Group).

## Behavior parity notes

- `requestVpnPermission` → on iOS this saves the tunnel profile, which triggers
  the system VPN-consent prompt (equivalent to Android's `prepare()`).
- `getInstalledApps` / `setPerAppConfig` → per-app routing is Android-only;
  these are no-ops on iOS (iOS has no equivalent API for 3rd-party VPNs).
- `setNotificationDetailsEnabled` → no-op; iOS shows the system VPN indicator.
- Status events (`connecting`/`connected`/`disconnected`) are emitted from
  `NEVPNStatusDidChange`. Traffic stats are written to the App Group by the
  extension (`vpn.stats.up`/`down`) and can also be pulled via
  `session.sendProviderMessage("stats")`.

## Quick local check (after a Mac build)

`flutter run -d ios`, tap connect on a server, and watch Xcode's Console for the
PacketTunnel extension (filter by process `PacketTunnel`). The UI should move
`connecting → connected`; if it stays connecting, the core/tun2socks calls in
`XrayCore.swift` / `Tun2SocksBridge.swift` are still the placeholders (look for
the `os_log` "core running" / "starting tun2socks" lines and a
"LibXray.xcframework not linked" error).
