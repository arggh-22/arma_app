# Phase 2: VPN Engine & Core Connection - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 02-vpn-engine-core-connection
**Areas discussed:** Xray-core AAR strategy, Connection state UX, VpnService lifecycle, Network resilience

---

## Xray-core AAR Strategy

### Q1: How to get the Xray-core native library?

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-built AAR from AndroidLibXrayLite | Use 2dust's official releases, avoid Go build complexity entirely | ✓ |
| Custom Go-Mobile build | Build from source with gomobile bind, full control but fragile toolchain | |
| Hiddify's libcore fork | Use Hiddify's enhanced Go library (more features, heavier) | |

**User's choice:** Pre-built AAR from AndroidLibXrayLite
**Notes:** Safest path — avoids Go/gomobile/NDK version lock-step (Pitfall #2)

### Q2: Where to build Xray JSON config?

| Option | Description | Selected |
|--------|-------------|----------|
| Xray JSON config built entirely in Dart | Native side is a dumb executor, receives complete JSON | ✓ |
| Config built in Kotlin | Native side constructs Xray config from ServerConfig fields | |
| Hybrid | Dart builds template, Kotlin fills platform-specific fields | |

**User's choice:** Entirely in Dart
**Notes:** Keeps native side minimal, all logic testable in Dart

---

## Connection State UX

### Q3: Connection state visual transitions?

| Option | Description | Selected |
|--------|-------------|----------|
| Color-coded button with ring animation | Grey→pulsing teal→solid teal, Happ-style power button glow | ✓ |
| Simple state text + icon change | Minimal: button color changes, text label updates | |
| Full dashboard transformation | Background gradient shifts, card colors change, immersive | |

**User's choice:** Color-coded button with ring animation

### Q4: Duration timer placement?

| Option | Description | Selected |
|--------|-------------|----------|
| Inside the connect button circle | Timer appears below the power icon when connected | |
| Below the button | Separate text widget showing 00:00:00 elapsed time | ✓ |
| In the active server card | Timer integrated with server name and protocol badge | |

**User's choice:** Below the button

### Q5: Traffic stats display?

| Option | Description | Selected |
|--------|-------------|----------|
| Upload/Download cards below timer | Two side-by-side cards showing ↑ and ↓ speeds | ✓ |
| Single combined row | ↑ 12.5 MB/s  ↓ 45.2 MB/s in one horizontal line | |
| Minimal text only | Just numbers, no cards or decoration | |

**User's choice:** Upload/Download cards below timer

---

## VpnService Lifecycle

### Q6: Separate process for VpnService?

| Option | Description | Selected |
|--------|-------------|----------|
| Separate process | VpnService runs in :vpn_process, Go panics can't kill Flutter UI | ✓ |
| Same process | Simpler setup but Go panic = full app crash | |

**User's choice:** Separate process
**Notes:** Follows V2rayNG's :RunSoLibV2RayDaemon pattern

### Q7: Foreground notification design?

| Option | Description | Selected |
|--------|-------------|----------|
| Standard persistent notification | Shows connection status + server name + speeds, tap opens app | ✓ |
| Minimal notification | Just 'Connected' / 'Disconnected' status | |
| Rich notification with controls | Status + speeds + Disconnect button in notification | |

**User's choice:** Standard persistent notification

### Q8: Flutter ↔ VpnService communication?

| Option | Description | Selected |
|--------|-------------|----------|
| MethodChannel + EventChannel | Commands via MethodChannel, state stream via EventChannel | ✓ |
| Just MethodChannel | Polling-based: Flutter calls native periodically | |
| Messenger/AIDL | Cross-process Android IPC (more complex) | |

**User's choice:** MethodChannel + EventChannel

---

## Network Resilience

### Q9: Network change behavior?

| Option | Description | Selected |
|--------|-------------|----------|
| Automatic silent reconnect | Detect network change, restart xray-core loop automatically | ✓ |
| Reconnect with notification | Same but show 'Reconnecting...' in UI | |
| Manual reconnect | Show 'Connection lost', user taps to reconnect | |

**User's choice:** Automatic silent reconnect

### Q10: DNS leak prevention?

| Option | Description | Selected |
|--------|-------------|----------|
| Remote DNS for proxied, direct for local | Split DNS from day one, prevents leaks | ✓ |
| All DNS through tunnel | Simpler but slower for local domains | |
| Agent's discretion | Let agent decide implementation | |

**User's choice:** Split DNS from day one

---

## Agent's Discretion

- Exact Xray JSON config structure
- MethodChannel/EventChannel method names and payloads
- Foreground notification channel config
- TUN interface parameters (MTU, IP range)
- ConnectivityManager callback details
- Error handling and retry strategies

## Deferred Ideas

None — discussion stayed within phase scope
