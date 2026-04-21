# Arma Proxy & VPN Client — UI Specification

> Visual description of every screen, widget, and interaction pattern.

## Navigation Structure

```
┌─────────────────────────────────────────┐
│              NavigationShell             │
│  ┌─────────────────────────────────────┐ │
│  │         Active Tab Content          │ │
│  │   (preserved via indexedStack)      │ │
│  └─────────────────────────────────────┘ │
│  ┌─────┬─────┬─────┬─────┐            │
│  │ 🏠  │ 🌐  │ 🔀  │ ⚙️  │            │
│  │Dash │Srvrs│Route│Setts│            │
│  └─────┴─────┴─────┴─────┘            │
└─────────────────────────────────────────┘

Standalone route (pushed over shell):
  /logs → LogViewerScreen
```

### Theme

- **Design System**: Material 3
- **Seed Color**: Teal `#00897B`
- **Modes**: System / Light / Dark
- **Cards**: 12px radius, elevation 1 (light) / 0 with outline (dark)
- **Protocol Colors**: VLESS=#00897B (teal), VMess=#1565C0 (blue), Trojan=#E65100 (orange), Shadowsocks=#6A1B9A (purple), Hysteria2=#2E7D32 (green)

---

## Screen 1: Dashboard (`/dashboard` — Tab 0)

**File:** `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
**Type:** `ConsumerWidget`

### Layout

```
┌─────────────────────────────────────┐
│  AppBar: "Arma VPN"                 │
├─────────────────────────────────────┤
│                                     │
│         ┌──────────────┐            │
│         │              │            │
│         │   ⏻  120dp   │  ← ConnectButton
│         │   animated   │    (circle with power icon)
│         │   circle     │
│         └──────────────┘            │
│                                     │
│        "Disconnected"               │  ← Status text
│        (color-coded)                │    Grey=off, Teal=connecting, Green=on
│                                     │
│         00:00:00                    │  ← ConnectionTimer (HH:MM:SS)
│                                     │
│  ┌─────────────────────────────────┐ │
│  │ 🟢 VLESS  ⚡ Server Name       │ │  ← ActiveServerCard
│  │          82.25.12.104:2053      │ │    (protocol badge + name + address)
│  └─────────────────────────────────┘ │
│                                     │
│  ┌──────────┐  ┌──────────┐        │
│  │ ↓ 0 B/s  │  │ ↑ 0 B/s  │        │  ← TrafficStatsCard
│  │ (green)  │  │ (blue)   │        │    (download / upload)
│  └──────────┘  └──────────┘        │
│                                     │
│  "2 active connections" (tappable)  │  ← Opens PerOutboundStatsSheet
│                                     │
└─────────────────────────────────────┘
```

### ConnectButton States

| State | Visual |
|---|---|
| **Disconnected** | Grey circle, white power icon |
| **Connecting** | Teal circle, pulsing animation + shimmer effect |
| **Connected** | Teal circle with outer glow, green checkmark |
| **Disconnecting** | Teal fading to grey |

### PerOutboundStatsSheet (Modal Bottom Sheet)

```
┌─────────────────────────────────────┐
│  ─── (drag handle)                  │
│  Traffic by Outbound                │
├─────────────────────────────────────┤
│  proxy    ↓ 1.2 MB  ↑ 256 KB  (3)  │
│  direct   ↓ 45 KB   ↑ 12 KB   (1)  │
└─────────────────────────────────────┘
```

---

## Screen 2: Server List (`/servers` — Tab 1)

**File:** `lib/features/server/presentation/screens/server_list_screen.dart`
**Type:** `ConsumerStatefulWidget`

### Normal Mode

```
┌─────────────────────────────────────┐
│  AppBar: "Servers"    ⚡ 📶          │  ← Best Server + Test All icons
├─────────────────────────────────────┤
│  Sort: [Name ▼]  [All] [Working] [×] │  ← SortFilterBar
├─────────────────────────────────────┤
│                                     │
│  ── Subscription: My Provider ──    │  ← ServerGroupHeader (collapsible)
│  ↻  ...  📋                         │    3-dot menu: Refresh/Delete All/Copy URL
│  ████████░░  2.1 / 5.0 GB  12d    │    Data usage bar + expiry
│  📢 Server maintenance tonight      │    Announcement banner (colored)
│                                     │
│  ┌─────────────────────────────────┐ │
│  │ 🇳🇱 NL Server                  │ │  ← ServerCard (active = left border)
│  │    Amsterdam node         VLESS │ │    Flag + name + description + protocol badge
│  │                          45ms │ │    Latency indicator (green)
│  ├─────────────────────────────────┤ │
│  │ 🇩🇪 DE Server                  │ │
│  │    Frankfurt              VLESS │ │
│  │                         120ms │ │    (orange latency)
│  ├─────────────────────────────────┤ │
│  │ 🇺🇸 US Server                  │ │
│  │    New York             VMess │ │
│  │                           ✕  │ │    (failed latency — red X)
│  └─────────────────────────────────┘ │
│                                     │
│  ── Manual Servers (3) ──           │  ← Manual group header
│  ...                                │
│                                     │
│                          [＋]       │  ← ImportFab (expandable)
└─────────────────────────────────────┘
```

### Multi-Select Mode (triggered by long-press)

```
┌─────────────────────────────────────┐
│  [✕]  3 selected   [☑ All]  [🗑]   │  ← Close, count, Select All, Delete
├─────────────────────────────────────┤
│  ☑ 🇳🇱 NL Server              VLESS │  ← Checkbox + tinted background
│  ☐ 🇩🇪 DE Server              VLESS │
│  ☑ 🇺🇸 US Server             VMess │
│  ☑ 🇫🇷 FR Server            Trojan │
└─────────────────────────────────────┘
```

### Empty State

```
┌─────────────────────────────────────┐
│                                     │
│           🌐 (64px icon)            │
│                                     │
│      No servers yet                 │
│  Import servers to get started      │
│                                     │
│   [ Import from Clipboard ]         │  ← FilledButton
│                                     │
└─────────────────────────────────────┘
```

### ImportFab (Expanded)

```
                      [📷 Scan QR]
                      [🔗 Add Subscription]
                      [📋 Paste Config]
                      [📎 Clipboard]
                          [＋] ← rotates to ✕ when expanded
```

### Swipe-to-Delete

```
┌───────────────────────────────┬─────┐
│ 🇳🇱 NL Server               │ 🗑  │  ← Red background revealed on swipe-left
│    Amsterdam              VLESS│     │
└───────────────────────────────┴─────┘

                  ↓ (after swipe completes)

  ┌─────────────────────────────────┐
  │ Server deleted.        [UNDO]   │  ← SnackBar with undo action
  └─────────────────────────────────┘
```

### ServerCard Detail

```
┌─ active indicator (4px teal left border, only on selected server)
│ ┌─────────────────────────────────────────┐
│ │  🇳🇱   ⚡ Турбо • Быстрый [Vision] ✅   │  ← Flag emoji + server name
│ │       Amsterdam, fast node              │  ← Description (grey, smaller)
│ │                                  VLESS  │  ← ProtocolBadge (colored pill)
│ │                                  45ms  │  ← LatencyIndicator (green/orange/red)
│ └─────────────────────────────────────────┘
```

### LatencyIndicator States

| Value | Display |
|---|---|
| `null` (untested) | `—` dash |
| `-2` (testing) | Spinner animation |
| `-1` (error) | Red ✕ icon |
| `≤150ms` | Green text |
| `151–300ms` | Orange text |
| `>300ms` | Red text |

---

## Screen 3: QR Scanner

**File:** `lib/features/server/presentation/screens/qr_scanner_screen.dart`
**Type:** `ConsumerStatefulWidget` (pushed via Navigator)

```
┌─────────────────────────────────────┐
│  ← (back)   Scan QR Code           │  ← Transparent AppBar
├─────────────────────────────────────┤
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░░░░░┌───────────────┐░░░░░░░░░░░ │
│ ░░░░░░│               │░░░░░░░░░░░ │  ← 250×250 transparent cutout
│ ░░░░░░│   📷 Camera   │░░░░░░░░░░░ │    (custom ScanOverlayPainter)
│ ░░░░░░│    Preview     │░░░░░░░░░░░ │
│ ░░░░░░│               │░░░░░░░░░░░ │
│ ░░░░░░└───────────────┘░░░░░░░░░░░ │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│  "Point camera at QR code"          │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │
│  [🔦]                        [📸]  │  ← Flash toggle, Camera switch
└─────────────────────────────────────┘
```

**Auto-detection behavior:**
- Proxy share link → import server immediately
- HTTP URL → show subscription prompt dialog
- Unknown → error snackbar

---

## Screen 4: Routing (`/routing` — Tab 2)

**File:** `lib/features/routing/presentation/screens/routing_screen.dart`
**Type:** `ConsumerStatefulWidget`

```
┌─────────────────────────────────────┐
│  AppBar: "Routing"                  │
├─────────────────────────────────────┤
│                                     │
│  Bypass LAN Traffic    [━━━━●]      │  ← SwitchListTile
│                                     │
│  ▼ Region Presets                   │  ← ExpansionTile (initially expanded)
│  ┌─────────────────────────────────┐ │
│  │ [🇮🇷 Iran] [🇨🇳 China] [🇷🇺 Russia] │  ← FilterChips (toggleable)
│  │                                 │ │
│  │ Uses bundled geo rules          │ │
│  │ [ 🔄 Update Rules ]            │ │
│  └─────────────────────────────────┘ │
│                                     │
│  ▶ Domain Rules (3)                 │  ← ExpansionTile (collapsed, badge count)
│  ┌─────────────────────────────────┐ │
│  │ 🟢 google.com    [proxy ▼] [🗑] │ │  ← DomainRuleRow
│  │ 🟢 youtube.com   [proxy ▼] [🗑] │ │    Color dot: green=direct, teal=proxy, red=block
│  │ 🔴 ads.com       [block ▼] [🗑] │ │
│  │                                 │ │
│  │  [ + Add Rule ]                 │ │  ← Opens AddDomainRuleDialog
│  └─────────────────────────────────┘ │
│                                     │
│  ▶ Per-App Proxy                    │  ← ExpansionTile
│  ┌─────────────────────────────────┐ │
│  │ Enable Per-App  [━━━━●]         │ │
│  │ Mode: [Blacklist | Whitelist]   │ │  ← SegmentedButton
│  │                                 │ │
│  │ 🔍 Search apps...              │ │
│  │ Selected: 3 apps                │ │
│  │ ┌───────────────────────────┐   │ │
│  │ │ [icon] Chrome         ☑  │   │ │  ← AppPickerList (scrollable, max 400dp)
│  │ │ [icon] YouTube        ☑  │   │ │
│  │ │ [icon] Telegram       ☑  │   │ │
│  │ │ [icon] WhatsApp       ☐  │   │ │
│  │ │ ...                      │   │ │
│  │ └───────────────────────────┘   │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### AddDomainRuleDialog

```
┌─────────────────────────────────────┐
│  Add Domain Rule                    │
│                                     │
│  Domain: [example.com          ]    │  ← Validates dot, strips http://
│                                     │
│  Action: [Proxy | Direct | Block]   │  ← SegmentedButton
│                                     │
│            [Discard]  [Add]         │
└─────────────────────────────────────┘
```

---

## Screen 5: Settings (`/settings` — Tab 3)

**File:** `lib/features/settings/presentation/screens/settings_screen.dart`
**Type:** `ConsumerWidget`

```
┌─────────────────────────────────────┐
│  AppBar: "Settings"                 │
├─────────────────────────────────────┤
│                                     │
│  ── GENERAL ──                      │  ← Colored section header
│  Theme   [System | Light | Dark]    │  ← SegmentedButton
│  Language  English              ▶   │  ← Opens language bottom sheet
│                                     │
│  ── DNS ──                          │
│  Protocol  [DoH | DoT | Plain]      │  ← SegmentedButton
│  Remote DNS  Cloudflare         ▶   │  ← Opens DnsPickerSheet
│  Direct DNS  Cloudflare         ▶   │
│  FakeIP DNS    [━━━━●]             │
│    CIDR: [198.18.0.0/15    ]       │  ← Animated expand when FakeIP on
│                                     │
│  ── ENGINE ──                       │
│  DNS Sniffing  [━━━━●]             │
│  Multiplexing  [━━━━●]             │
│    Concurrency:  [━━━━━●━━] 4      │  ← Slider 1-8 (animated expand)
│                                     │
│  ── ANTI-CENSORSHIP ──              │
│  Profile [None|Light|Moderate|Aggr] │  ← SegmentedButton
│  "Moderate: Fragment + Padding"     │  ← Description text
│  TLS Fragment  [━━━━●]             │
│    Size: [50] - [100]              │  ← Two fields (animated expand)
│    Sleep: [10] - [50] ms           │
│  TLS Padding   [━━━━●]             │
│  Mixed SNI     [━━━━●]             │
│                                     │
│  ── DIAGNOSTICS ──                  │
│  View Logs                      ▶   │  ← Pushes /logs route
│                                     │
│  ── DATA ──                         │
│  Clear cached data              ▶   │  ← Shows confirmation AlertDialog
│                                     │
│  ── ABOUT ──                        │
│  Version 1.2.0                      │
│  Open Source Licenses           ▶   │
│                                     │
└─────────────────────────────────────┘
```

### Language Bottom Sheet

```
┌─────────────────────────────────────┐
│  ─── (drag handle)                  │
│  Select Language                    │
├─────────────────────────────────────┤
│  ◉ English                          │
│  ○ فارسی                            │  ← RTL
│  ○ Русский                          │
│  ○ 中文                             │
└─────────────────────────────────────┘
```

### DnsPickerSheet

```
┌─────────────────────────────────────┐
│  ─── (drag handle)                  │
│  Select DNS Server                  │
├─────────────────────────────────────┤
│  ◉ Cloudflare    https://1.1.1.1/.. │
│  ○ Google        https://8.8.8.8/.. │
│  ○ Quad9         https://9.9.9.9/.. │
│  ○ AdGuard       https://94.140...   │
│  ○ Electro       https://electro...  │
│  ○ Custom...                         │
│    [https://my-dns.example.com ]    │  ← TextField (when Custom selected)
└─────────────────────────────────────┘
```

---

## Screen 6: Log Viewer (`/logs` — Standalone)

**File:** `lib/features/log/presentation/screens/log_viewer_screen.dart`
**Type:** `ConsumerStatefulWidget`

```
┌─────────────────────────────────────┐
│  ← AppBar: "View Logs"         [📤] │  ← Share/export button
├─────────────────────────────────────┤
│  Level: [All ▼]  🔍 [Search...   ] │  ← Filter dropdown + search field
├─────────────────────────────────────┤
│  12:05:01 INFO  sing-box started    │  ← Monospace 12sp
│  12:05:01 INFO  TUN created fd=102  │    Color-coded by level:
│  12:05:02 INFO  DNS: 1.1.1.1       │    - Red = error
│  12:05:02 WARN  slow DNS response   │    - Orange = warning
│  12:05:03 ERROR connection refused  │    - Dim = timestamp prefix
│  12:05:03 INFO  retry attempt 2     │
│  ...                                │
│  (auto-scrolls to bottom)           │
│  (disables auto-scroll on manual    │
│   scroll up >50px)                  │
├─────────────────────────────────────┤
│  128 lines    Auto-scroll [━━━●]    │  ← Status bar + toggle
└─────────────────────────────────────┘
```

### Empty State

```
┌─────────────────────────────────────┐
│                                     │
│           No logs yet               │
│                                     │
└─────────────────────────────────────┘
```

---

## Dialogs & Modals

### AddSubscriptionDialog

```
┌─────────────────────────────────────┐
│  Add Subscription                   │
│                                     │
│  URL *  [https://sub.example.com ]  │  ← Required, validated
│  Name   [My Provider            ]   │  ← Optional
│  User-Agent [                   ]   │  ← Optional
│  ☑ Auto-update (default on)         │
│                                     │
│  [Cancel]              [Add ●]      │  ← Loading spinner on submit
└─────────────────────────────────────┘
```

### PasteConfigDialog (Full-Screen)

```
┌─────────────────────────────────────┐
│  ✕  Paste Configuration     [Import]│  ← Full-screen scaffold
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐ │
│  │ vless://uuid@host:port?...      │ │  ← Multiline TextField (autofocus)
│  │ vmess://base64...               │ │    Paste one or more share links
│  │                                 │ │
│  │                                 │ │
│  └─────────────────────────────────┘ │
│  Validates links, checks duplicates  │
└─────────────────────────────────────┘
```

### QrDisplayDialog (Modal Bottom Sheet)

```
┌─────────────────────────────────────┐
│  ─── (drag handle)                  │
│  Share Server                       │
├─────────────────────────────────────┤
│  ┌───────────────────────┐          │
│  │ ██████████████████████ │          │
│  │ ██  QR CODE 220×220 ██ │          │
│  │ ██████████████████████ │          │
│  └───────────────────────┘          │
│                                     │
│  vless://uuid@host:port?params...   │  ← Share link preview (truncated)
│                                     │
│  [📋 Copy Link]    [📤 Share Link]  │
└─────────────────────────────────────┘
```

### Delete Confirmation Dialog

```
┌─────────────────────────────────────┐
│  Delete 3 servers?                  │
│                                     │
│  This action cannot be undone.      │
│                                     │
│           [Cancel]  [Delete]        │  ← Delete button in red
└─────────────────────────────────────┘
```

---

## Provider → Screen Mapping

| Provider | Screens |
|---|---|
| `connectionProvider` | Dashboard, ConnectButton, ConnectionTimer |
| `activeServerProvider` | Dashboard, ConnectButton, ActiveServerCard, ServerList |
| `trafficStatsProvider` | TrafficStatsCard, PerOutboundStatsSheet |
| `serverListProvider` | ServerList, QrScanner, PasteConfigDialog |
| `subscriptionProvider` | ArmaApp (auto-refresh), ServerList, AddSubscriptionDialog |
| `multiSelectProvider` | ServerList |
| `latencyProvider` | ServerList |
| `sortFilterProvider` | ServerList, SortFilterBar |
| `groupCollapseProvider` | ServerList |
| `bestServerProvider` | ServerList |
| `networkConnectivityProvider` | ServerList |
| `routingSettingsProvider` | Routing, RegionPresetsSection, AppPickerList |
| `installedAppsProvider` | AppPickerList |
| `themeProvider` | ArmaApp, Settings |
| `localeProvider` | ArmaApp, Settings |
| `dnsSettingsProvider` | Settings |
| `engineSettingsProvider` | Settings |
| `antiCensorshipProvider` | Settings |
| `logLinesProvider` / `logServiceProvider` | LogViewer |
