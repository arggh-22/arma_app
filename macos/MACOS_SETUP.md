# macOS implementation — setup & status

macOS uses the **same** `NEPacketTunnelProvider` stack as iOS. The Swift engine
files are shared verbatim; only the app entry point, entitlements, Info.plist,
and Xcode target wiring differ.

> ⚠️ Build/test on **macOS + Xcode** with a **paid Apple Developer account**
> (NetworkExtension + App Groups). None of this can be built on Linux.

## What's already in the repo

| File | Role | State |
|---|---|---|
| `macos/Runner/MainFlutterWindow.swift` | registers `VpnChannel` on the Flutter engine | ✅ |
| `macos/Runner/Release.entitlements` / `DebugProfile.entitlements` | app-sandbox + NetworkExtension + App Group + network client | ✅ |
| `macos/PacketTunnel/Info.plist` | declares the packet-tunnel provider class | ✅ |
| `macos/PacketTunnel/PacketTunnel.entitlements` | sandbox + NetworkExtension + App Group | ✅ |
| **shared** `ios/Runner/VpnChannel.swift` | Flutter ⇄ `NETunnelProviderManager` (conditional `Flutter`/`FlutterMacOS` import) | ✅ |
| **shared** `ios/Runner/XrayProbe.swift` | in-app version/latency probe | ⚠️ 2 core calls |
| **shared** `ios/PacketTunnel/*.swift` | provider + `XrayTunnel` + `XrayCore` + `TunnelConfig` + `Tun2SocksBridge` | ✅ / ⚠️ core seams |

## Manual steps on macOS (Xcode GUI)

1. **Add the Runner sources**: add `ios/Runner/VpnChannel.swift` and
   `ios/Runner/XrayProbe.swift` to the **macOS Runner** target (they compile on
   macOS unchanged — `VpnChannel` already switches to `FlutterMacOS`).
2. **Add the extension target**: File ▸ New ▸ Target ▸ **Network Extension**
   (Packet Tunnel), name `PacketTunnel`. Replace Xcode's generated
   `Info.plist`/`*.entitlements`/provider with the files in `macos/PacketTunnel/`,
   and add the shared `ios/PacketTunnel/*.swift` files to this target.
3. **Bundle IDs**: app `com.arma.vpn`, extension `com.arma.vpn.PacketTunnel`
   (must equal `tunnelBundleId` in `VpnChannel.swift`).
4. **App Group** `group.com.arma.vpn` on both targets (matches the entitlements
   and `appGroup` in `VpnChannel.swift`).
5. **Capabilities**: Network Extensions on both targets; provisioning profiles
   must carry the NetworkExtension entitlement.
6. **Xray core**: build/obtain `LibXray.xcframework` (`gomobile bind
   -target=macos …`) and add it to **both** the Runner and PacketTunnel targets.
   `pod install` (the macOS Podfile declares `HevSocks5Tunnel` for PacketTunnel).
7. **Fill the core seams**: uncomment `import LibXray` / `import HevSocks5Tunnel`
   and the `// ← real call` lines in `XrayCore.swift`, `Tun2SocksBridge.swift`,
   `XrayProbe.swift` (identical to iOS — see `ios/IOS_SETUP.md`).

## Parity notes (macOS)

- App-sandbox stays **on**; the NetworkExtension + App Group + `network.client`
  entitlements are what let the tunnel run inside the sandbox.
- Per-app routing / installed-apps → no-ops (Android-only), same as iOS.
- The shared Dart layer is unchanged; `osType` is sent as `ios` for both iOS
  and macOS (the backend treats Apple platforms alike).
