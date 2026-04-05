---
status: partial
phase: 02-vpn-engine-core-connection
source: [02-VERIFICATION.md]
started: 2026-04-05
updated: 2026-04-05
---

## Current Test

[awaiting human testing]

## Tests

### 1. Full VPN connection end-to-end
expected: Tap connect button with a valid server config → VPN establishes via Android VpnService → traffic tunnels through Xray-core → websites load through proxy
result: [pending]

### 2. Connect button animation quality
expected: Grey (disconnected) → pulsing teal shimmer (connecting) → solid teal glow with shadow (connected) — smooth, satisfying transitions matching D-03 spec
result: [pending]

### 3. Network change resilience
expected: Switch WiFi ↔ cellular while connected → VPN auto-reconnects silently without user action (D-10)
result: [pending]

### 4. Foreground notification rendering
expected: Persistent notification shows connection status, server name, ↑↓ traffic speeds. Tapping opens app. (D-07)
result: [pending]

### 5. Real-time traffic stats accuracy
expected: Dashboard ↑↓ cards show speeds correlating with actual network activity, updating ~1Hz (D-05)
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
