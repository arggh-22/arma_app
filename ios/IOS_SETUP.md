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
| `ios/PacketTunnel/PacketTunnelProvider.swift` | the extension; configures utun + `XrayBridge` seam | ⚠️ skeleton — Xray core not wired |
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
2. Drag `LibXray.xcframework` into the **PacketTunnel** target (Frameworks).
3. Implement the `XrayBridge` seam in `PacketTunnelProvider.swift`:
   - `start(config:packetFlow:)` — start Xray with the JSON config, and bridge
     packets between `packetFlow` (read/write) and Xray. Two common approaches:
     - **tun2socks**: run Xray with a SOCKS/HTTP inbound, run a userspace
       tun2socks (e.g. hev-socks5-tunnel) reading `packetFlow.readPackets` and
       writing to the SOCKS inbound; or
     - **Xray tun inbound**: feed the `packetFlow` to Xray's tun handling.
   - `stop()` — stop Xray and the bridge.
4. Optionally surface version/latency: implement `getXrayVersion` and
   `measureDelay` in `VpnChannel.swift` (currently return `"Unknown"`/`-1`).

## Behavior parity notes

- `requestVpnPermission` → on iOS this saves the tunnel profile, which triggers
  the system VPN-consent prompt (equivalent to Android's `prepare()`).
- `getInstalledApps` / `setPerAppConfig` → per-app routing is Android-only;
  these are no-ops on iOS (iOS has no equivalent API for 3rd-party VPNs).
- `setNotificationDetailsEnabled` → no-op; iOS shows the system VPN indicator.
- Status events (`connecting`/`connected`/`disconnected`) are emitted from
  `NEVPNStatusDidChange`. Traffic-stats (`type:"stats"`) events are not emitted
  yet — add them from the extension via the App Group if you want live counters.

## Quick local check (after a Mac build)

`flutter run -d ios`, tap connect on a server, and watch Xcode's Console for the
PacketTunnel extension (filter by process `PacketTunnel`). The UI should move
`connecting → connected`; if it stays connecting, the `XrayBridge` seam isn't
running the core yet.
