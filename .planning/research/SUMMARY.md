# Research Summary: Arma Proxy & VPN Client

**Domain:** Privacy-first proxy/VPN client (Xray-core based, Android)
**Researched:** 2026-04-05
**Overall Confidence:** HIGH
**Research Focus:** Stack dimension — technology choices, versions, integration patterns

## Executive Summary

The Flutter proxy/VPN client stack is well-established in 2026, with clear reference implementations to follow. V2rayNG (53k+ stars, native Kotlin) and Hiddify (57k+ stars, Flutter) prove both approaches work at scale. The critical architectural insight is that Xray-core integration is done via Go-Mobile AAR compilation, not FFI — the `2dust/AndroidLibXrayLite` project provides a battle-tested Go wrapper that compiles Xray-core into an Android AAR with clean Kotlin/Java bindings. This AAR exposes exactly the APIs we need: `StartLoop(configJson, tunFd)`, `StopLoop()`, `QueryStats()`, and `MeasureDelay()`.

The Dart/Flutter side follows standard patterns: Riverpod 3.x for state management, go_router 17.x for navigation, and hive_ce (Community Edition, NOT original Hive which is abandoned since 2022) for local storage. Code generation (freezed + json_serializable + riverpod_generator) is essential — the config model layer is complex (6+ protocols, each with different URL formats and Xray JSON structures) and hand-writing serialization would be error-prone.

The highest-risk area is the VpnService integration layer (Phase 3): the Kotlin-side code that bridges Flutter MethodChannels to the Go AAR to Android VpnService. This involves managing TUN file descriptor lifecycle, foreground service notifications, VPN permission consent flows, and connection state synchronization between three runtimes (Dart, Kotlin, Go). V2rayNG's implementation (V2RayVpnService.kt, V2RayServiceManager.kt, V2RayNativeManager.kt) provides an excellent template, but must be adapted from native Android to Flutter platform channels.

All package versions have been verified against pub.dev API as of 2026-04-05. The Go-Mobile AAR build process has been verified by cloning and inspecting AndroidLibXrayLite source code. No guesswork — every recommendation is based on verified sources.

## Key Findings

**Stack:** Flutter 3.x + Riverpod 3.3 + hive_ce 2.19 + go_router 17.2 + Xray-core v26.3.27 via Go-Mobile AAR (AndroidLibXrayLite)
**Architecture:** Three-layer bridge: Flutter (MethodChannel) → Kotlin (VpnService + AAR bridge) → Go (Xray-core AAR)
**Critical pitfall:** VpnService permission/lifecycle management — asynchronous, cross-runtime state synchronization is the #1 risk

## Implications for Roadmap

Based on research, suggested phase structure:

1. **Project Foundation** - Flutter project structure, theme, Riverpod setup, static UI
   - Addresses: Theme, navigation, component library
   - Avoids: Starting with complex native code before Dart architecture is solid
   - Risk: LOW — standard Flutter patterns

2. **Config Data Models & Parsing** - Protocol models, share link parsers, Hive storage
   - Addresses: VLESS/VMess/Trojan/SS data models, share link parsing, local persistence
   - Avoids: Coupling parsing logic to UI or native layer
   - Risk: MEDIUM — vmess:// format has many edge cases (base64 variants, optional fields)

3. **Xray-core AAR + VpnService Integration** - The hardest phase
   - Addresses: Go-Mobile AAR build, Kotlin VpnService, MethodChannel bridge, connection lifecycle
   - Avoids: Premature optimization (get basic connect/disconnect working first)
   - Risk: HIGH — three-runtime bridging, TUN fd lifecycle, permission flow state machine
   - **Likely needs deeper research during implementation** (specific Android API quirks, Android 14+ foreground service changes)

4. **Subscription, Latency & Polish** - Subscription import, ping testing, traffic stats, QR scanning
   - Addresses: Subscription management, latency testing, traffic monitoring, QR import
   - Avoids: Feature creep into routing rules or advanced settings
   - Risk: MEDIUM — subscription parsing has provider-specific variations

5. **Advanced Features** - Routing rules, per-app proxy, custom DNS, Hysteria2
   - Addresses: Power user features, advanced configuration
   - Risk: LOW-MEDIUM — well-documented patterns in V2rayNG

**Phase ordering rationale:**
- Phase 1 before Phase 2: Dart architecture must be solid before building data models on it
- Phase 2 before Phase 3: Config models must exist before the native layer can consume them (Dart → JSON → Go core)
- Phase 3 is the critical path: Everything after this depends on a working VPN connection
- Phase 4 after Phase 3: Subscription import and latency testing need a working core to be testable
- Phase 5 last: Advanced features are differentiators, not table stakes

**Research flags for phases:**
- Phase 3: **Needs deeper research** — Android 14 foreground service `SPECIAL_USE` type, hev-socks5-tunnel JNI integration details, Go Seq bridging initialization
- Phase 2: **Moderate research needed** — Hysteria2 share link format standardization, encrypted subscription formats
- Phase 1, 4, 5: Standard patterns, unlikely to need additional research

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack (packages & versions) | HIGH | All versions verified via pub.dev API. Build approach verified from AndroidLibXrayLite source. |
| Stack (Go-Mobile AAR) | HIGH | Cloned and inspected AndroidLibXrayLite. Build steps from README verified against go.mod and source. |
| Stack (VpnService patterns) | HIGH | Cloned V2rayNG, read full VpnService + ServiceManager + NativeManager source code. Patterns well documented. |
| Features | HIGH | Cross-referenced with V2rayNG, Hiddify, and spec document. Feature set is well-understood in this domain. |
| Architecture | HIGH | Three-layer bridge pattern is the industry standard. Both V2rayNG (native) and Hiddify (Flutter) use it. |
| Pitfalls | HIGH | Derived from actual source code comments (V2rayNG has inline comments about specific bugs), issue trackers, and Android documentation. |

## Gaps to Address

- **hev-socks5-tunnel integration details:** V2rayNG uses this JNI library for TUN→SOCKS5 bridging as an alternative to passing TUN fd directly. Need to determine if we use this or direct fd pass-through. Direct fd is simpler for v1.
- **Android 14+ (API 34) foreground service changes:** The `FOREGROUND_SERVICE_SPECIAL_USE` permission and type are required. Need to verify exact manifest and code changes during Phase 3.
- **Hysteria2 share link format:** Less standardized than VLESS/VMess/Trojan. May need phase-specific research when implementing in Phase 5.
- **Encrypted subscription formats:** Provider-specific. Defer research until Phase 4 implementation.
- **APK size optimization:** Full AAR + geo-data could produce 80MB+ APK. Need to research AAR ABI splitting and geo-data lazy loading during Phase 3.
- **Exact Kotlin version compatibility:** V2rayNG uses Kotlin 2.3.0. Flutter's Kotlin plugin version must be compatible. Verify during Phase 1 setup.
