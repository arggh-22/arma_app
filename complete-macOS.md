# Completing iOS + macOS on a Mac — step by step

Everything in Dart and Swift is already written. This is the checklist to finish
the build on a **macOS machine with Xcode** and a **paid Apple Developer
account** (NetworkExtension + App Groups require both). Do it once for iOS and
once for macOS — the steps are the same, only the folder (`ios/` vs `macos/`)
and a couple of files differ.

Fixed identifiers this repo already assumes (keep them consistent everywhere):

| Thing | Value |
|---|---|
| App bundle id | `com.arma.vpn` |
| Extension bundle id | `com.arma.vpn.PacketTunnel` |
| App Group | `group.com.arma.vpn` |

---

## Phase 0 — Prerequisites (once)

1. Install Xcode from the App Store, then:
   ```sh
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -license accept
   ```
2. Install Flutter + CocoaPods + Go:
   ```sh
   brew install --cask flutter
   brew install cocoapods go
   flutter doctor            # fix anything it flags for iOS/macOS
   ```
3. In the repo root:
   ```sh
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs
   ```
4. Sign in to Xcode with your Apple Developer account:
   Xcode ▸ Settings ▸ Accounts ▸ (+) ▸ Apple ID.

---

## Phase 1 — Build the Xray core xcframework

The Android app uses `libv2ray.aar`. Apple needs the equivalent `.xcframework`.

```sh
go install golang.org/x/mobile/cmd/gomobile@latest
export PATH="$PATH:$(go env GOPATH)/bin"
gomobile init

# Clone the XTLS libXray binding and build it.
git clone https://github.com/XTLS/libXray.git
cd libXray
# iOS + iOS Simulator + macOS in one xcframework:
gomobile bind -target=ios,iossimulator,macos -o LibXray.xcframework ./
```

- If `gomobile bind` errors on the module path, build the package that exposes
  the `LibXray*` functions (check the repo's README for the exact import path).
- Alternatively grab a **prebuilt `LibXray.xcframework`** from the XTLS
  ecosystem (e.g. a release asset) instead of building it yourself.
- Keep the resulting `LibXray.xcframework` somewhere handy; you'll drag it into
  Xcode in Phase 4.

Also download **`geoip.dat`** and **`geosite.dat`** (from the v2fly/Loyalsoldier
releases) — needed so routing rules like `geoip:ru` work. You'll add them to the
extension bundle in Phase 4.

---

## Phase 2 — Open the workspace

```sh
cd ios      # (or: cd macos)
pod install
open Runner.xcworkspace     # ALWAYS the .xcworkspace, not .xcodeproj
```

> `pod install` will warn that the `PacketTunnel` target doesn't exist yet —
> that's expected. Re-run it after Phase 3.

---

## Phase 3 — Add the Packet Tunnel extension target

1. Xcode ▸ **File ▸ New ▸ Target…**
2. Choose **Network Extension** → **Packet Tunnel Provider** → Next.
3. Name it exactly **`PacketTunnel`**. Language: Swift. Finish.
   (If asked to activate the scheme, click **Activate**.)
4. Xcode generates a `PacketTunnel/` folder with its own
   `PacketTunnelProvider.swift`, `Info.plist`, `PacketTunnel.entitlements`.
   **Delete the three generated files** (Move to Trash) — you'll use the repo's.

---

## Phase 4 — Wire the source files into the targets

In Xcode's left panel, right-click the target's group ▸ **Add Files to
"Runner"…**, and add (uncheck "Copy items if needed" — reference in place):

**To the `PacketTunnel` target** (tick only PacketTunnel in "Add to targets"):
- `ios/PacketTunnel/PacketTunnelProvider.swift`
- `ios/PacketTunnel/TunnelConfig.swift`
- `ios/PacketTunnel/XrayTunnel.swift`
- `ios/PacketTunnel/XrayCore.swift`
- `ios/PacketTunnel/Tun2SocksBridge.swift`
- `ios/PacketTunnel/Info.plist`  → then set it as the target's Info.plist
  (target ▸ Build Settings ▸ *Info.plist File*).
- `ios/PacketTunnel/PacketTunnel.entitlements` → target ▸ Build Settings ▸
  *Code Signing Entitlements* = `PacketTunnel/PacketTunnel.entitlements`.
- `geoip.dat`, `geosite.dat` (from Phase 1) → tick PacketTunnel (Copy Bundle
  Resources).

**To the `Runner` target** (should already be there for iOS; add for macOS):
- `ios/Runner/VpnChannel.swift`
- `ios/Runner/XrayProbe.swift`

> **macOS note:** the `macos/Runner` target reuses `ios/Runner/VpnChannel.swift`
> and `ios/Runner/XrayProbe.swift` (VpnChannel switches to `FlutterMacOS`
> automatically), and the `macos/PacketTunnel` target reuses the same
> `ios/PacketTunnel/*.swift`. Use `macos/PacketTunnel/Info.plist` +
> `macos/PacketTunnel/PacketTunnel.entitlements` for that target.

**Drag `LibXray.xcframework`** into the project and, in its *File inspector* ▸
*Target Membership*, tick **both** `Runner` and `PacketTunnel`. For each target:
General ▸ *Frameworks, Libraries, and Embedded Content* → set `LibXray` to
**Embed & Sign**.

Then re-run pods:
```sh
pod install
```

---

## Phase 5 — Bundle IDs, App Group, capabilities

For **both** the `Runner` and `PacketTunnel` targets (Signing & Capabilities tab):

1. **Team**: pick your Apple Developer team. Turn on *Automatically manage
   signing*.
2. **Bundle Identifier**:
   - Runner → `com.arma.vpn`
   - PacketTunnel → `com.arma.vpn.PacketTunnel`
     (must equal `tunnelBundleId` in `VpnChannel.swift`).
3. **+ Capability ▸ App Groups** → add `group.com.arma.vpn` to **both** targets.
4. **+ Capability ▸ Network Extensions** → tick **Packet Tunnel** on **both**
   targets.
5. Confirm each target's *Code Signing Entitlements* points at the repo's
   `.entitlements` file (iOS: `Runner/Runner.entitlements` /
   `PacketTunnel/PacketTunnel.entitlements`; macOS: the ones under
   `macos/Runner/` and `macos/PacketTunnel/`).
6. macOS only: keep **App Sandbox** on (it already coexists with the entitlements
   in the repo files).

If signing fails, create the App ID + App Group + a provisioning profile with
the **Network Extensions** entitlement in the Apple Developer portal, then let
Xcode download them.

---

## Phase 6 — Fill the Xray-core call seams

The packet plumbing, config transform, tun2socks bridge, and stats are already
written. Only the actual framework calls are stubbed. Open each file and:

1. Uncomment the framework import at the top:
   - `XrayCore.swift`, `XrayProbe.swift`: `import LibXray`
   - `Tun2SocksBridge.swift`: `import HevSocks5Tunnel`
2. Replace every line marked `// ← real call` (and remove the `notLinked()`
   placeholder it points at) with your framework's real function. Examples
   (names depend on your libXray version — check its headers):

   `XrayCore.swift`
   ```swift
   func run(configJson: String) throws {
     … // build the base64 request as written
     let response = LibXrayRunXray(reqB64)          // ← was notLinked()
     try Self.throwIfFailed(response, context: "runXray")
   }
   func stop() { _ = LibXrayStopXray() }             // ← was notLinked()
   func stats() -> Stats { … LibXrayQueryStats("") … }
   func version() -> String { … LibXrayXrayVersion() … }
   func measureDelay(...) -> Int { … LibXrayTestXray(reqB64) … }
   ```

   `Tun2SocksBridge.swift` (inside `start` and `stop`)
   ```swift
   HevSocks5Tunnel.start(withConfigString: config, fileDescriptor: fd)   // start
   HevSocks5Tunnel.quit()                                                // stop
   ```

   `XrayProbe.swift` — same two calls as `XrayCore.version()` /
   `measureDelay()`.
3. If your libXray build needs a different request shape than the base64-JSON
   `{datDir,configPath,maxMemory}` used here, adjust the dictionaries in
   `XrayCore.run` / `measureDelay` accordingly.

---

## Phase 7 — Build & run

```sh
# iOS device (a real device is required — the Network Extension needs it):
flutter run -d <your-iphone>

# macOS:
flutter run -d macos
```

Then in the app: pick a server → tap connect. First connect shows the system
**"ArmaVPN would like to add VPN configurations"** prompt → Allow.

Watch the extension logs in **Console.app** (filter process = `PacketTunnel`)
or Xcode ▸ Debug ▸ Attach to Process ▸ PacketTunnel. Success looks like:
```
tunnel  startTunnel: dns=… mtu=1500
xray    XrayTunnel started (socks 127.0.0.1:10808)
core    core running (config=…)
tun2socks starting tun2socks on fd=… → 127.0.0.1:10808
```

---

## Phase 8 — Verify parity

- Status pill goes **connecting → connected**; real traffic flows.
- Traffic counters update (extension writes `vpn.stats.up`/`down` to the App
  Group every second).
- Per-server latency: the **TCP** ping type works immediately (pure Dart). The
  **HTTP** ping uses `measureDelay` via libXray (Phase 6).
- Server list / subscriptions / notices / support-renew all work unchanged
  (shared Dart layer).

---

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Stays "connecting", log shows `LibXray.xcframework not linked` | Phase 6 not done, or framework not embedded in the **PacketTunnel** target. |
| `could not resolve utun fd` | `Tun2SocksBridge.tunnelFileDescriptor` didn't find the utun; ensure `setTunnelNetworkSettings` completed before tun2socks starts (it does in the current code) — verify the extension actually loaded. |
| Consent prompt never appears | App Group / NetworkExtension capability missing on the **Runner** target, or bundle ids don't match. |
| Connects but no traffic | Xray started but tun2socks calls are still commented, or the config's outbound is unreachable. Check the `tun2socks` log line. |
| `geoip:*/geosite:*` routing errors in log | `geoip.dat`/`geosite.dat` not in the extension bundle, or `XrayCore.assetDir()` points at the wrong dir. |
| macOS build: entitlement errors | Keep App Sandbox on AND include `network.client` + the NetworkExtension + App Group keys (already in `macos/Runner/*.entitlements`). |

Reference docs already in the repo: `ios/IOS_SETUP.md`, `macos/MACOS_SETUP.md`.
