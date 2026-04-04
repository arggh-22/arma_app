# External Integrations

**Analysis Date:** 2025-07-14

## Project Status

**No external integrations exist yet.** The project is at the default Flutter template stage. This document captures the **planned** integrations from `happ_clone_specs.md` and marks what needs to be implemented.

## APIs & External Services

### Currently Implemented

None. The app has no network calls, API clients, or external service connections.

### Planned (from `happ_clone_specs.md`)

**Proxy/VPN Protocol Servers (user-provided, not app-provided):**
- The app acts as a **client** for user-supplied proxy configurations
- Supported protocols (to implement): VLESS, VMess, Trojan, Shadowsocks, Socks, HTTP, Hysteria2
- No centralized API server — configurations come from user input
- SDK/Client: Xray-core (native binary via FFI or Android Platform Channels)

**Subscription URL Fetching:**
- HTTP GET requests to user-provided subscription URLs
- Responses are base64-encoded server configurations
- Custom User-Agent header support planned
- No specific HTTP client package chosen yet (likely `http` or `dio`)

**Latency Testing:**
- HTTP ping to `gstatic.com/generate_204` (or similar)
- TCPing to proxy server addresses
- Implementation: Custom Dart/native code

## Data Storage

**Databases:**
- Currently: None
- Planned: `Hive` or `Isar` (NoSQL, local on-device)
  - Purpose: Store proxy configurations, subscription data, routing rules, app settings
  - Connection: Local file-based, no remote database
  - No env vars needed

**File Storage:**
- Local filesystem only
- Xray-core configuration JSON files (generated at runtime, passed to native engine)

**Caching:**
- None currently
- Planned: Local cache of subscription configs in Hive/Isar

## Authentication & Identity

**Auth Provider:**
- None — The app has no user accounts or authentication
- The app is a local utility; no login, registration, or auth flows
- Proxy server authentication is per-config (UUID, passwords embedded in config strings)

## Monitoring & Observability

**Error Tracking:**
- None configured
- No Sentry, Crashlytics, or similar service

**Logs:**
- No logging framework
- Planned: Xray-core engine logs (exportable from Settings screen per spec)
- Default Dart `print()` / `debugPrint()` only

**Analytics:**
- None — privacy-first app per spec

## CI/CD & Deployment

**Hosting:**
- Not configured
- Planned targets: Google Play Store, direct APK distribution

**CI Pipeline:**
- None configured
- `.github/` directory contains GSD tooling config but no CI/CD workflows (no `.github/workflows/`)

## Environment Configuration

**Required env vars:**
- None currently required
- `android/local.properties` — Local SDK paths (not committed, developer-specific)

**Secrets location:**
- No secrets management
- Android release signing: Not configured (uses debug keys)
- `android/app/build.gradle.kts` contains TODO for release signing config

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None

## Planned Native Platform Integrations

These are critical integrations that will require platform-specific native code:

**Android VpnService (highest priority):**
- Purpose: Capture device traffic and route through proxy
- Location: `android/app/src/main/kotlin/com/example/arma_proxy_vpn_client/`
- Current state: Only default `MainActivity.kt` (extends `FlutterActivity`, no custom code)
- Requirements:
  - `android.permission.INTERNET` — needs to be added to `AndroidManifest.xml`
  - `android.net.VpnService` — needs to be declared in manifest
  - Kotlin platform channel implementation for Dart ↔ native communication
  - Compiled Xray-core Android binary (AAR) or Go-Mobile bindings

**Xray-core Engine:**
- Purpose: Core proxy/VPN engine
- Integration method: FFI or Android Platform Channels
- Binary source: `libv2ray` or custom Go-Mobile compiled AAR
- Config format: JSON (generated from Dart data models)

**QR Code Scanner:**
- Purpose: Import proxy configurations via camera
- Planned package: `mobile_scanner`
- Requires camera permissions on Android/iOS

**Traffic Monitoring:**
- Purpose: Real-time upload/download speed display
- Source: Native bytes sent/received from VpnService
- Communication: Platform channel events (stream) from native to Dart

## Third-Party Package Integrations (Planned)

| Package | Purpose | Status |
|---------|---------|--------|
| `flutter_riverpod` | State management | Not added |
| `go_router` | Navigation/routing | Not added |
| `hive` or `isar` | Local database | Not added |
| `mobile_scanner` | QR code scanning | Not added |
| `http` or `dio` | HTTP client for subscriptions | Not added |

## Integration Risks

**Xray-core native integration:**
- Most complex integration — requires Go cross-compilation for Android
- No existing Flutter package for Xray-core; must be built custom
- Will need separate AAR/framework per platform architecture (arm64, x86_64)

**VpnService:**
- Android-specific API; iOS equivalent (NetworkExtension) has different requirements
- Requires foreground service notification on Android 14+

**Subscription parsing:**
- Multiple URL/config formats to support (vless://, vmess://, trojan://, ss://)
- Base64 decoding, JSON parsing, custom encrypted formats
- No standard library exists — must implement custom parsers

---

*Integration audit: 2025-07-14*
