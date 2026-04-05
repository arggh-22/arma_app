# Phase 4: Routing, DNS & Advanced Settings - Research

**Researched:** 2026-04-05
**Domain:** Xray-core advanced configuration (routing, DNS, anti-censorship, Hysteria2), Android VpnService per-app split tunneling, Flutter Material 3 settings UI
**Confidence:** HIGH

## Summary

Phase 4 extends the existing Xray-core configuration system with user-configurable DNS, routing rules, anti-censorship TLS tricks, and Hysteria2 protocol support. It also adds Android-native per-app split tunneling via VpnService.Builder APIs. The codebase is well-prepared: `XrayConfigBuilder` already has all the extension points, `SettingsLocalDatasource` follows a clean SharedPreferences pattern ready for new keys, and the routing screen is a skeleton placeholder waiting to be replaced. `ServerConfig` already has Hysteria2 fields (`obfs`, `obfsPassword`) with Hive model field index gaps reserved for new fields.

The primary challenge is that `XrayConfigBuilder.build()` currently takes only a `ServerConfig` parameter. Phase 4 must extend it to accept a settings object containing DNS, sniffing, mux, fragment, routing rules, and anti-censorship parameters — then wire those into the JSON config output. The per-app proxy feature requires a new MethodChannel to pass package lists from Dart to Kotlin, and modification of `configureTunInterface()` to call `addAllowedApplication()` / `addDisallowedApplication()`. Hysteria2 needs new `ServerConfig` fields (`upMbps`, `downMbps`, `insecure`) and stream settings with `network: "hysteria2"`.

**Primary recommendation:** Structure implementation as: (1) data layer first (settings model + persistence + l10n), (2) Xray config builder extensions (DNS, routing rules, mux, fragment, sniffing, Hysteria2 stream settings), (3) native Kotlin changes (per-app proxy + MethodChannel), (4) Settings screen UI sections (DNS, Engine, Anti-Censorship, Data), (5) Routing screen full UI (region presets, domain rules, per-app proxy).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Presets + simple custom rules. Region presets (Iran, China, Russia) provide one-tap domestic traffic bypass. Users can also add individual domains with Proxy/Direct/Block action.
- **D-02:** Region presets sourced from BOTH bundled defaults (hardcoded known domestic domains/IPs) AND downloadable community sources (e.g., chocolate4u/Iran-v2ray-rules on GitHub). Bundled works offline; download option keeps rules current.
- **D-03:** Custom domain rules use a simple domain list UI — user types a domain and picks Proxy/Direct/Block from a dropdown. No regex, no IP ranges, no port ranges.
- **D-04:** User chooses between blacklist mode (all apps through VPN, exclude selected) and whitelist mode (no apps through VPN, include selected). Toggle to switch modes.
- **D-05:** App picker is a scrollable list of all installed apps with icons, search filter, and checkboxes. Uses Android PackageManager to enumerate installed apps.
- **D-06:** Support three DNS protocols: DNS-over-HTTPS (DoH), DNS-over-TLS (DoT), and plain DNS. All three are configurable.
- **D-07:** DNS UI provides quick-select presets (Cloudflare, Google, Quad9, etc.) plus manual input for custom servers.
- **D-08:** Engine settings organized as a separate "Engine Settings" section in Settings screen. Contains: Sniffing toggle, Mux toggle with concurrency setting.
- **D-09:** Sniffing defaults to ON. Mux defaults to OFF.
- **D-10:** Anti-censorship settings organized as a separate "Anti-Censorship" section. Contains: Fragment toggle, TLS fragment size range, TLS sleep range, padding, mixed SNI case.
- **D-11:** Preset profiles: "Light", "Moderate", "Aggressive" that set all anti-censorship values at once. Full customization always visible.
- **D-12:** Hysteria2 bandwidth hints (upMbps/downMbps) are optional with auto-detect. If not provided, connect without hints.
- **D-13:** Salamander obfuscation supported for Hysteria2.
- **D-14:** Hysteria2 fields to add to ServerConfig: `upMbps`, `downMbps`, `insecure`. Existing `obfs` and `obfsPassword` already cover salamander.
- **D-15:** "Clear cached data" clears: geo rule cache, subscription cache, log files. Does NOT clear server configs or user preferences.

### Agent's Discretion
- Custom rule UI layout details (spacing, card vs list tile for rules)
- How frequently downloadable rule sets are checked for updates
- Exact TLS trick default values for each preset profile
- Hysteria2 `_buildStreamSettings` implementation details

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROTO-05 | User can connect via Hysteria2 protocol (UDP/QUIC) | Xray-core Hysteria2 outbound config format, ServerConfig new fields, stream settings with `network: "hysteria2"` |
| ROUTE-02 | User can configure custom DNS servers (DoH/DoT supported) | Xray-core DNS config format with DoH/DoT URLs, DNS presets data, SettingsLocalDatasource keys |
| ROUTE-03 | User can set per-domain routing rules: Proxy, Direct, or Block | Xray-core routing rules format (domain-based), Hive persistence for rules, routing config builder extension |
| ROUTE-04 | User can enable per-app proxy (split tunneling) | Android VpnService.Builder addAllowedApplication/addDisallowedApplication, MethodChannel for app list + selected apps |
| ROUTE-05 | App provides region-specific bypass presets (Iran, China, Russia) | Bundled domain/IP lists, chocolate4u/Iran-v2ray-rules format, geosite/geoip categories |
| UI-04 | Settings screen includes Xray toggles: Sniffing, Mux, Fragment | Xray-core sniffing/mux/fragment JSON config, settings persistence, UI section in settings screen |
| UI-05 | Settings screen includes TLS tricks: fragment size/sleep, padding, mixed SNI | Xray-core sockopt fragment config, TLS padding/mixed SNI settings |
| UI-06 | User can clear cached data and export app logs from settings | Cache file locations, clear operation implementation, log export (already exists — add clear) |

</phase_requirements>

## Project Constraints (from copilot-instructions.md)

- **Tech stack**: Flutter (Dart) with Clean Architecture + MVVM, Riverpod for state management, Hive for local storage, go_router for navigation
- **Platform**: Android-only for v1 (API 21+ / Android 5.0+)
- **Engine**: Xray-core compiled via Go-Mobile, integrated through Kotlin platform channels and Android VpnService
- **No backend**: All data stored locally on device
- **Privacy**: No analytics, no tracking, no data collection
- **Coding conventions**: snake_case.dart files, PascalCase classes, Dart 3 features (switch expressions, records, sealed classes), `@Riverpod(keepAlive: true)` for persisted state, Material 3 `ListTile` + `SwitchListTile` patterns
- **Error handling**: AsyncValue for Riverpod, custom exceptions for domain errors
- **No print()**: Use debugPrint() — avoid_print lint enforced

## Standard Stack

### Core (Already Installed — No New Dependencies)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_riverpod | ^3.3.1 | State management for all new settings providers | Already in pubspec.yaml [VERIFIED: codebase] |
| riverpod_annotation | ^4.0.2 | Code generation for Riverpod notifiers | Already in pubspec.yaml [VERIFIED: codebase] |
| shared_preferences | ^2.5.5 | Lightweight settings persistence (toggles, DNS, engine settings) | Already in pubspec.yaml [VERIFIED: codebase] |
| hive_ce | ^2.19.3 | Structured data persistence (domain rules, ServerConfig fields) | Already in pubspec.yaml [VERIFIED: codebase] |
| hive_ce_flutter | ^2.3.4 | Flutter Hive integration | Already in pubspec.yaml [VERIFIED: codebase] |
| freezed_annotation | ^3.1.0 | Immutable data classes (ServerConfig extension) | Already in pubspec.yaml [VERIFIED: codebase] |
| http | ^1.6.0 | HTTP client for downloading community rule sets | Already in pubspec.yaml [VERIFIED: codebase] |
| path_provider | ^2.1.5 | File system access for cache clearing | Already in pubspec.yaml [VERIFIED: codebase] |

### Supporting (Already Available)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| riverpod_generator | ^4.0.3 | Code generation for providers | Dev dependency, run build_runner [VERIFIED: codebase] |
| build_runner | ^2.13.1 | Code generation runner | Run after model/provider changes [VERIFIED: codebase] |
| gap | ^3.0.1 | Spacing widget between elements | UI spacing [VERIFIED: codebase] |

**No new packages required.** Phase 4 uses only existing dependencies. [VERIFIED: codebase + 04-UI-SPEC.md Registry Safety]

## Architecture Patterns

### Recommended Project Structure (New/Modified Files)
```
lib/
├── features/
│   ├── routing/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── routing_local_datasource.dart    # NEW: Hive-backed domain rules
│   │   │   └── models/
│   │   │       └── domain_rule_model.dart            # NEW: Hive model for rules
│   │   ├── domain/
│   │   │   └── entities/
│   │   │       └── domain_rule.dart                  # NEW: Freezed entity
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── routing_settings_provider.dart    # NEW: routing state
│   │       │   └── installed_apps_provider.dart      # NEW: Android app list
│   │       ├── screens/
│   │       │   └── routing_screen.dart               # REPLACE skeleton
│   │       └── widgets/
│   │           ├── region_presets_section.dart        # NEW
│   │           ├── domain_rule_row.dart               # NEW
│   │           ├── add_domain_rule_dialog.dart        # NEW
│   │           └── app_picker_list.dart               # NEW
│   ├── settings/
│   │   ├── data/
│   │   │   └── datasources/
│   │   │       └── settings_local_datasource.dart    # EXTEND: new keys
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── engine_settings_provider.dart      # NEW
│   │       │   ├── anti_censorship_provider.dart      # NEW
│   │       │   └── dns_settings_provider.dart         # NEW
│   │       ├── screens/
│   │       │   └── settings_screen.dart              # EXTEND: 4 new sections
│   │       └── widgets/
│   │           └── dns_picker_sheet.dart              # NEW
│   └── server/
│       └── domain/
│           └── entities/
│               └── server_config.dart                # EXTEND: 3 new fields
├── xray/
│   └── xray_config_builder.dart                      # EXTEND: settings param
└── core/
    └── l10n/
        ├── app_en.arb                                # EXTEND: ~40 new keys
        ├── app_fa.arb                                # EXTEND
        ├── app_ru.arb                                # EXTEND
        └── app_zh.arb                                # EXTEND

android/app/src/main/kotlin/com/arma/vpn/
├── service/
│   └── ArmaVpnService.kt                            # MODIFY: per-app proxy in configureTunInterface()
└── MainActivity.kt                                  # EXTEND: new MethodChannel methods
```

### Pattern 1: Settings Provider with SharedPreferences (Established)
**What:** Riverpod `@Riverpod(keepAlive: true)` notifier that reads initial state from SharedPreferences and writes back on changes. Auto-saves on every toggle/selection.
**When to use:** All new settings (DNS, engine, anti-censorship).
**Example:**
```dart
// Source: Existing pattern from theme_provider.dart [VERIFIED: codebase]
@Riverpod(keepAlive: true)
class EngineSettingsNotifier extends _$EngineSettingsNotifier {
  late SettingsLocalDatasource _datasource;

  @override
  EngineSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    _datasource = SettingsLocalDatasource(prefs);
    return EngineSettings(
      sniffingEnabled: _datasource.getSniffingEnabled(),
      muxEnabled: _datasource.getMuxEnabled(),
      muxConcurrency: _datasource.getMuxConcurrency(),
    );
  }

  Future<void> setSniffing(bool enabled) async {
    await _datasource.setSniffingEnabled(enabled);
    state = state.copyWith(sniffingEnabled: enabled);
  }
}
```

### Pattern 2: Hive-Backed Data for Structured Lists (Established)
**What:** Hive box with `@HiveType` model for structured persistent data (domain rules).
**When to use:** Domain routing rules — list of {domain, action} pairs that need structured persistence.
**Example:**
```dart
// Source: Pattern from server_config_model.dart [VERIFIED: codebase]
@HiveType(typeId: 2) // typeId 0=ServerConfig, 1=Subscription, 2=DomainRule
class DomainRuleModel extends HiveObject {
  @HiveField(0)
  final String domain;

  @HiveField(1)
  final int actionIndex; // 0=proxy, 1=direct, 2=block

  DomainRuleModel({required this.domain, required this.actionIndex});
}
```

### Pattern 3: MethodChannel for Native Communication (Established)
**What:** Flutter MethodChannel for Dart→Kotlin calls, returning structured data.
**When to use:** Per-app proxy — getting installed app list from Android PackageManager, passing selected apps to VPN service.
**Example:**
```dart
// Source: Pattern from vpn_platform_service.dart [VERIFIED: codebase]
// New methods to add:
Future<List<Map<String, dynamic>>> getInstalledApps() async {
  final result = await _methodChannel.invokeListMethod<Map>('getInstalledApps');
  return result?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
}
```

### Pattern 4: XrayConfigBuilder Extension (Existing Static Methods)
**What:** Extend `XrayConfigBuilder.build()` to accept a settings parameter alongside `ServerConfig`.
**When to use:** All Phase 4 config builder changes.
**Example:**
```dart
// Source: Existing pattern from xray_config_builder.dart [VERIFIED: codebase]
// Current: static String build(ServerConfig server)
// New:     static String build(ServerConfig server, {VpnSettings? settings})
// VpnSettings is a new data class holding all Phase 4 user settings
```

### Anti-Patterns to Avoid
- **Don't nest ScrollViews:** Per-App Proxy list inside routing ListView — use `Column` with `shrinkWrap` or `SliverList`, NOT a nested `ListView`. [CITED: 04-UI-SPEC.md line 202]
- **Don't share EventChannel broadcast streams across multiple receivers:** Create one shared broadcast stream — multiple `receiveBroadcastStream()` calls overwrite the native handler. [VERIFIED: codebase vpn_platform_service.dart]
- **Don't use setState for settings state:** All settings MUST use Riverpod providers for consistency with the existing architecture. The current routing screen uses `setState` (Phase 1 skeleton) and must be converted to `ConsumerStatefulWidget`. [VERIFIED: codebase routing_screen.dart]
- **Don't hardcode Xray config fragments:** All dynamic config values (DNS addresses, routing rules, sniffing/mux toggles) must flow through the VpnSettings parameter to `XrayConfigBuilder.build()`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DNS preset data | Custom DNS provider lookup | Hardcoded preset list with known URLs | DNS presets are static data (Cloudflare, Google, Quad9, AdGuard, Electro) — no runtime discovery needed [CITED: D-07] |
| Region bypass rules | Custom domain classification | Bundled lists + chocolate4u/Iran-v2ray-rules community format | These are maintained community lists with thousands of entries — impossible to compile manually [CITED: D-02] |
| Android app enumeration | Custom process scanning | `PackageManager.getInstalledApplications()` | Standard Android API, handles all edge cases [VERIFIED: Android docs] |
| Per-app VPN routing | Custom traffic routing | `VpnService.Builder.addAllowedApplication()` / `addDisallowedApplication()` | OS-level implementation — kernel-enforced routing that works with all apps [VERIFIED: Android VpnService API] |
| TLS fragment/sleep config | Custom TLS interception | Xray-core `sockopt.fragment` in stream settings | Xray-core handles this natively — fragment, sleep, padding are built-in sockopt features [ASSUMED] |

**Key insight:** Xray-core already implements all the anti-censorship tricks (fragment, padding, mixed SNI) — we only need to expose the JSON config knobs through the UI. The VPN system service handles per-app routing at the kernel level.

## Common Pitfalls

### Pitfall 1: Hysteria2 Stream Settings Differ from TCP-Based Protocols
**What goes wrong:** Using the standard TCP/WS/gRPC stream settings for Hysteria2 causes connection failure. Hysteria2 uses QUIC internally with its own transport.
**Why it happens:** The existing `_buildStreamSettings()` dispatches on `server.network` (tcp/ws/grpc/h2) — Hysteria2 doesn't fit this pattern.
**How to avoid:** For Hysteria2 protocol, set `streamSettings.network` to `"hysteria2"` and provide TLS settings with `allowInsecure` from the new `insecure` field. Do NOT include transport-specific settings (tcpSettings, wsSettings, etc.). [ASSUMED — needs verification against Xray-core docs]
**Warning signs:** "transport not found" or "unknown network" errors in Xray-core logs.

### Pitfall 2: VpnService.Builder Per-App Methods Require Exact Package Names
**What goes wrong:** Calling `addAllowedApplication()` or `addDisallowedApplication()` with an invalid or uninstalled package name throws `PackageManager.NameNotFoundException`.
**Why it happens:** The API validates package names at build time.
**How to avoid:** Wrap each `addAllowedApplication()` / `addDisallowedApplication()` call in a try-catch. Filter the saved package list against currently installed apps before passing to the VPN service. [VERIFIED: Android VpnService API documentation]
**Warning signs:** VPN fails to start after an app is uninstalled that was in the per-app list.

### Pitfall 3: Cannot Use Both addAllowedApplication AND addDisallowedApplication
**What goes wrong:** VpnService.Builder only supports one mode — either whitelist OR blacklist, never both.
**Why it happens:** Calling both `addAllowedApplication()` and `addDisallowedApplication()` on the same Builder throws an exception.
**How to avoid:** Based on the user's mode selection (D-04), call ONLY `addAllowedApplication()` (whitelist) or ONLY `addDisallowedApplication()` (blacklist). The existing `addDisallowedApplication(packageName)` self-exclusion must always be applied regardless of mode. [VERIFIED: Android VpnService.Builder docs]
**Warning signs:** Runtime crash when building TUN interface.

### Pitfall 4: DNS Config Format Differences Between Protocols
**What goes wrong:** Xray-core DNS section expects different address formats for different protocols.
**Why it happens:** DoH uses `https://` URLs, DoT uses `tls://` prefix, plain DNS uses bare IP addresses. Using wrong format silently fails DNS resolution.
**How to avoid:** Use correct format per protocol: `"https://1.1.1.1/dns-query"` for DoH, `"tls://1.1.1.1"` for DoT, `"1.1.1.1"` for plain. The UI preset picker should auto-format the correct URL. [ASSUMED — based on Xray-core documentation patterns]
**Warning signs:** DNS resolution fails silently — sites don't load but no error is shown.

### Pitfall 5: Xray-core Fragment Config Lives in sockopt, NOT Transport Settings
**What goes wrong:** Putting fragment settings in the wrong location in the JSON config makes them silently ignored.
**Why it happens:** Fragment/sleep/padding are TCP socket options (`sockopt`), not transport-layer settings.
**How to avoid:** Place fragment config under `streamSettings.sockopt`:
```json
"sockopt": {
  "tcpKeepAliveIdle": 100,
  "tcpNoDelay": true,
  "dialerProxy": "",
  "fragment": {
    "packets": "tlshello",
    "length": "10-100",
    "interval": "10-50"
  }
}
```
[ASSUMED — based on Xray-core v1.8.x documentation patterns. Verify exact field names.]
**Warning signs:** Anti-censorship settings have no effect on connection behavior.

### Pitfall 6: Hive typeId Collision
**What goes wrong:** Using the same `@HiveType(typeId)` as an existing model causes runtime crash on box open.
**Why it happens:** Current models use typeId 0 (ServerConfigModel) and typeId 1 (SubscriptionModel).
**How to avoid:** New DomainRuleModel MUST use typeId 2. Verify no collisions by checking `hive_registrar.g.dart`. [VERIFIED: codebase — typeId 0 and 1 are taken]
**Warning signs:** Hive throws `HiveError: Type already registered` on startup.

### Pitfall 7: Per-App Config Must Be Passed to VPN Service Before TUN Creation
**What goes wrong:** The per-app proxy selection is configured in Dart but needs to be applied in Kotlin when `configureTunInterface()` runs.
**Why it happens:** The current IPC only passes `config` (JSON string) and `serverName` to the VPN service. Per-app package lists need a separate mechanism.
**How to avoid:** Either (a) pass per-app config as additional Intent extras alongside config/serverName, or (b) use SharedPreferences in the Android side (VPN process can read from the same SharedPreferences). Option (a) is cleaner — add `allowedApps` and `disallowedApps` as string array extras. [VERIFIED: codebase — ArmaVpnService receives config via Intent extras]
**Warning signs:** Per-app settings don't take effect even when configured in UI.

### Pitfall 8: Sniffing Config Already Hardcoded in TUN Inbound
**What goes wrong:** Adding a sniffing toggle but not modifying the inbound config means sniffing is always ON regardless of the toggle.
**Why it happens:** `_buildTunInbound()` currently hardcodes `'enabled': true` for sniffing. [VERIFIED: codebase line 107-111]
**How to avoid:** The sniffing toggle must modify the `sniffing.enabled` field in the TUN inbound config. Pass the setting through to `_buildTunInbound()`.
**Warning signs:** Toggling sniffing off has no effect.

## Code Examples

### Xray-core DNS Configuration with DoH/DoT
```dart
// Source: Xray-core JSON format [ASSUMED — based on Xray-core documentation]
static Map<String, dynamic> _buildDns({
  String remoteDns = 'https://1.1.1.1/dns-query',
  String directDns = 'localhost',
}) {
  return {
    'servers': [
      {
        'address': remoteDns, // DoH: "https://...", DoT: "tls://...", Plain: "1.1.1.1"
        'domains': <String>[],
        'port': 53,
      },
      directDns, // "localhost" for system DNS
    ],
  };
}
```

### Xray-core Routing Rules with Domain Rules
```dart
// Source: Existing _buildRouting pattern [VERIFIED: codebase]
// Add custom domain rules BEFORE the catch-all proxy rule:
static Map<String, dynamic> _buildRouting({
  required String serverAddress,
  List<DomainRule> customRules = const [],
  Set<String> enabledRegions = const {},
}) {
  final rules = <Map<String, dynamic>>[];
  
  // 1. Server bypass (existing — must always be first)
  rules.add(_buildServerBypassRule(serverAddress));
  
  // 2. LAN bypass (existing)
  rules.add({'type': 'field', 'outboundTag': 'direct', 'ip': ['geoip:private']});
  rules.add({'type': 'field', 'outboundTag': 'direct', 'domain': ['geosite:private']});
  
  // 3. Region preset rules (NEW)
  if (enabledRegions.contains('iran')) {
    rules.add({'type': 'field', 'outboundTag': 'direct', 'domain': ['geosite:category-ir']});
    rules.add({'type': 'field', 'outboundTag': 'direct', 'ip': ['geoip:ir']});
  }
  // Similar for 'china' → geosite:cn, geoip:cn, and 'russia' → geosite:category-ru, geoip:ru
  
  // 4. Custom domain rules (NEW)
  final proxyDomains = customRules.where((r) => r.action == 'proxy').map((r) => 'domain:${r.domain}').toList();
  final directDomains = customRules.where((r) => r.action == 'direct').map((r) => 'domain:${r.domain}').toList();
  final blockDomains = customRules.where((r) => r.action == 'block').map((r) => 'domain:${r.domain}').toList();
  
  if (directDomains.isNotEmpty) rules.add({'type': 'field', 'outboundTag': 'direct', 'domain': directDomains});
  if (blockDomains.isNotEmpty) rules.add({'type': 'field', 'outboundTag': 'block', 'domain': blockDomains});
  if (proxyDomains.isNotEmpty) rules.add({'type': 'field', 'outboundTag': 'proxy', 'domain': proxyDomains});
  
  // 5. Catch-all proxy (existing — must always be last)
  rules.add({'type': 'field', 'outboundTag': 'proxy', 'port': '0-65535'});
  
  return {'domainStrategy': 'IPIfNonMatch', 'rules': rules};
}
```

### Xray-core Mux Configuration
```dart
// Source: Xray-core mux config [ASSUMED — based on Xray-core documentation]
// Add 'mux' key to the proxy outbound when mux is enabled:
static Map<String, dynamic> _buildProxyOutbound(ServerConfig server, {
  bool muxEnabled = false,
  int muxConcurrency = 4,
}) {
  final outbound = <String, dynamic>{
    'tag': 'proxy',
    'protocol': protocol,
    'settings': _buildProtocolSettings(server),
    'streamSettings': _buildStreamSettings(server),
  };
  
  if (muxEnabled) {
    outbound['mux'] = {
      'enabled': true,
      'concurrency': muxConcurrency,
    };
  }
  
  return outbound;
}
```

### Xray-core Fragment (Anti-Censorship) via sockopt
```dart
// Source: Xray-core sockopt config [ASSUMED — based on Xray-core documentation]
// Add 'sockopt' to streamSettings when fragment is enabled:
if (fragmentEnabled) {
  streamSettings['sockopt'] = {
    'fragment': {
      'packets': 'tlshello',
      'length': '$fragmentMin-$fragmentMax', // e.g., "10-100"
      'interval': '$sleepMin-$sleepMax',     // e.g., "10-50" ms
    },
  };
}
```

### Hysteria2 Stream Settings
```dart
// Source: Xray-core Hysteria2 config [ASSUMED — needs verification]
// Hysteria2 uses its own network type in streamSettings:
if (server.protocol == ProtocolType.hysteria2) {
  return <String, dynamic>{
    'network': 'hysteria2',
    'security': 'tls',
    'tlsSettings': {
      'serverName': server.sni ?? server.address,
      'allowInsecure': server.insecure ?? false,
      'fingerprint': server.fingerprint ?? 'chrome',
    },
  };
}
```

### Android Per-App Proxy (Kotlin)
```kotlin
// Source: Android VpnService.Builder API [VERIFIED: Android docs]
private fun configureTunInterface(
    perAppMode: String?, // "blacklist" or "whitelist" or null
    selectedApps: List<String>? // package names
): ParcelFileDescriptor {
    val builder = Builder()
    builder.setMtu(9000)
    builder.addAddress("26.26.26.1", 30)
    builder.addRoute("0.0.0.0", 0)
    builder.addDnsServer("1.1.1.1")
    builder.addDnsServer("8.8.8.8")
    builder.addAddress("da26:2626::1", 126)
    builder.addRoute("::", 0)
    builder.setSession("Arma VPN")
    
    // Self-exclusion — ALWAYS apply regardless of mode (Pitfall #12 from Phase 2)
    builder.addDisallowedApplication(packageName)
    
    // Per-app routing (NEW)
    if (perAppMode == "whitelist" && selectedApps != null) {
        for (pkg in selectedApps) {
            try {
                builder.addAllowedApplication(pkg)
            } catch (e: Exception) {
                Log.w(TAG, "Skipping uninstalled app: $pkg")
            }
        }
    } else if (perAppMode == "blacklist" && selectedApps != null) {
        for (pkg in selectedApps) {
            try {
                builder.addDisallowedApplication(pkg)
            } catch (e: Exception) {
                Log.w(TAG, "Skipping uninstalled app: $pkg")
            }
        }
    }
    
    return builder.establish()
        ?: throw IllegalStateException("VPN builder.establish() returned null")
}
```

### MethodChannel for Installed Apps (Kotlin)
```kotlin
// Source: Android PackageManager API [VERIFIED: Android docs]
"getInstalledApps" -> {
    CoroutineScope(Dispatchers.IO).launch {
        val pm = applicationContext.packageManager
        val apps = pm.getInstalledApplications(0)
            .filter { it.flags and ApplicationInfo.FLAG_SYSTEM == 0 } // user apps only
            .map { appInfo ->
                mapOf(
                    "packageName" to appInfo.packageName,
                    "appName" to (pm.getApplicationLabel(appInfo)?.toString() ?: appInfo.packageName),
                    "icon" to encodeIconToBase64(pm, appInfo) // optional: base64 PNG
                )
            }
            .sortedBy { it["appName"] as String }
        withContext(Dispatchers.Main) {
            result.success(apps)
        }
    }
}
```

### SettingsLocalDatasource Extension
```dart
// Source: Existing pattern [VERIFIED: codebase]
// New keys for Phase 4 settings:
static const _sniffingKey = 'sniffing_enabled';
static const _muxEnabledKey = 'mux_enabled';
static const _muxConcurrencyKey = 'mux_concurrency';
static const _fragmentEnabledKey = 'fragment_enabled';
static const _fragmentMinKey = 'fragment_min';
static const _fragmentMaxKey = 'fragment_max';
static const _sleepMinKey = 'sleep_min';
static const _sleepMaxKey = 'sleep_max';
static const _paddingEnabledKey = 'padding_enabled';
static const _mixedSniKey = 'mixed_sni_enabled';
static const _antiCensorshipProfileKey = 'anti_censorship_profile';
static const _dnsProtocolKey = 'dns_protocol';
static const _remoteDnsKey = 'remote_dns';
static const _directDnsKey = 'direct_dns';
static const _perAppModeKey = 'per_app_mode';
static const _perAppEnabledKey = 'per_app_enabled';
static const _selectedAppsKey = 'selected_apps'; // JSON-encoded list
static const _enabledRegionsKey = 'enabled_regions'; // JSON-encoded set
static const _bypassLanKey = 'bypass_lan';

// Defaults:
bool getSniffingEnabled() => _prefs.getBool(_sniffingKey) ?? true; // D-09: ON
bool getMuxEnabled() => _prefs.getBool(_muxEnabledKey) ?? false;   // D-09: OFF
int getMuxConcurrency() => _prefs.getInt(_muxConcurrencyKey) ?? 4;
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate Hysteria binary | Xray-core built-in Hysteria2 | Xray-core v1.8.6 (2023) | No separate binary needed — same AAR handles Hysteria2 [ASSUMED] |
| tun2socks for traffic capture | Xray-core native TUN handler | Xray-core v1.8+ | Already implemented — TUN inbound in config [VERIFIED: codebase] |
| Manual geoip/geosite matching | Xray-core `geoip:xx`/`geosite:category-xx` syntax | Xray-core v1.5+ | Use built-in geo matching for region presets [ASSUMED] |

**Deprecated/outdated:**
- `Libv2ray.startLoop()` with separate tun2socks binary — replaced by Xray-core's built-in TUN protocol handler [VERIFIED: codebase uses TUN inbound directly]
- `withOpacity()` in Flutter — use `withValues(alpha:)` instead [VERIFIED: codebase decision from Phase 1]

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this
> section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Hysteria2 stream settings use `network: "hysteria2"` in Xray-core JSON config | Pitfall 1, Code Examples | Config builder generates wrong JSON → Hysteria2 connections fail. Implementer must verify against actual AAR behavior or Xray-core docs. |
| A2 | Fragment/sleep settings go in `streamSettings.sockopt.fragment` with `packets`, `length`, `interval` fields | Pitfall 5, Code Examples | Anti-censorship settings silently ignored. Verify field names from Xray-core source. |
| A3 | DNS DoH uses `https://` URL format, DoT uses `tls://` prefix in Xray-core DNS config | Pitfall 4, Code Examples | DNS resolution fails. Verify against Xray-core DNS documentation. |
| A4 | Xray-core v1.8.6+ in the AndroidLibXrayLite AAR includes Hysteria2 support | State of the Art | Hysteria2 protocol may not be available at all. Check AAR version via `Libv2ray.checkVersionX()`. |
| A5 | Region preset geosite categories are `geosite:category-ir`, `geosite:cn`, `geosite:category-ru` | Code Examples | Region bypass rules don't match any domains. Verify exact category names in geosite.dat. |
| A6 | TLS padding and mixed SNI case are configurable via Xray-core sockopt or TLS settings | UI-05 | These may require different config locations or may not be supported by the AAR version. |

## Open Questions

1. **Xray-core Hysteria2 Exact Config Format**
   - What we know: Xray-core v1.8.6+ supports Hysteria2 as a protocol. The existing config builder already handles `ProtocolType.hysteria2` in `_buildProtocolSettings()` with servers array format.
   - What's unclear: The exact `streamSettings` format for Hysteria2 — does it use `network: "hysteria2"` or something else? Does it need TLS settings? How are `upMbps`/`downMbps` bandwidth hints passed?
   - Recommendation: Check `Libv2ray.checkVersionX()` to confirm AAR version, then test with a minimal Hysteria2 config. If the AAR doesn't support Hysteria2, this requirement may need to be descoped or deferred.

2. **Xray-core Fragment/Padding/Mixed SNI Exact Field Names**
   - What we know: Xray-core supports TCP fragmentation via sockopt. The general structure is `sockopt.fragment`.
   - What's unclear: Exact field names for padding and mixed SNI case. Are these part of `sockopt` or `tlsSettings`?
   - Recommendation: Implementer should check Xray-core source code or test with sample configs to verify exact field placement.

3. **Region Geosite Category Names**
   - What we know: Geosite data includes country-specific domain lists. Iran domains are commonly accessed via `geosite:category-ir` in v2ray-rules-dat.
   - What's unclear: The exact category names available in the bundled `geosite.dat` — they depend on which dat file is bundled.
   - Recommendation: Check the bundled `geosite.dat` source (likely from Loyalsoldier/v2ray-rules-dat or v2fly/domain-list-community). The chocolate4u/Iran-v2ray-rules project provides Iran-specific enhanced geosite.dat files.

4. **App Icon Encoding for MethodChannel**
   - What we know: Android PackageManager provides app icons as Drawable objects.
   - What's unclear: Best approach for sending app icons from Kotlin to Dart — base64 PNG via MethodChannel works but may be slow for 100+ apps.
   - Recommendation: Use base64-encoded PNG at reduced resolution (48x48dp) to minimize data size. Cache the result. Consider loading icons lazily.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: `xray_config_builder.dart`, `server_config.dart`, `server_config_model.dart`, `settings_local_datasource.dart`, `ArmaVpnService.kt`, `MainActivity.kt`, `vpn_platform_service.dart`, `routing_screen.dart`, `settings_screen.dart` — verified current state of all extension points
- 04-CONTEXT.md — 15 locked decisions (D-01 through D-15)
- 04-UI-SPEC.md — Complete UI design contract with widget specs, l10n keys, interaction contracts

### Secondary (MEDIUM confidence)
- Android VpnService.Builder API — `addAllowedApplication()`, `addDisallowedApplication()` for per-app split tunneling [CITED: developer.android.com/reference/android/net/VpnService.Builder]
- Android PackageManager API — `getInstalledApplications()` for app enumeration

### Tertiary (LOW confidence)
- Xray-core Hysteria2 config format — based on training data about Xray-core v1.8.x, not verified against current AAR version
- Xray-core sockopt fragment config — based on training data, field names may differ
- Xray-core DNS DoH/DoT format — based on training data about Xray-core DNS config

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies needed, all existing packages verified in codebase
- Architecture: HIGH — follows established patterns from Phases 1-3 (Riverpod providers, Hive models, MethodChannel, config builder)
- Xray config format (DNS/routing/mux/sniffing): MEDIUM — patterns are well-established but exact field names for newer features (Hysteria2, fragment) need runtime verification
- Anti-censorship config: LOW — exact sockopt field names for fragment/padding/mixed SNI not verified against actual AAR version
- Per-app proxy: HIGH — Android VpnService API is well-documented and straightforward
- Pitfalls: HIGH — identified from codebase analysis and Android API documentation

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (stable — no external dependency changes expected)
