---
phase: 03-subscriptions-server-intelligence
plan: 05
title: "Subscription Service, QR Scanner & Config Sharing"
one_liner: "HTTP subscription service with custom UA + QR scanner/display + add subscription dialog"
status: complete
completed: "2026-04-05T17:13:00Z"
duration: "5min"
tasks_completed: 2
tasks_total: 2
subsystem: server
tags: [subscription, qr, scanner, sharing, http]
dependency_graph:
  requires: ["03-01", "03-02"]
  provides: ["subscription-service", "subscription-provider", "qr-scanner", "qr-display", "add-subscription-dialog"]
  affects: ["app.dart", "server-list"]
tech_stack:
  added: []
  patterns: ["ConsumerStatefulWidget for app-level startup hooks", "CustomPainter for QR scan overlay", "Modal bottom sheet for QR display"]
key_files:
  created:
    - lib/features/server/data/services/subscription_service.dart
    - lib/features/server/presentation/providers/subscription_provider.dart
    - lib/features/server/presentation/screens/qr_scanner_screen.dart
    - lib/features/server/presentation/widgets/qr_display_dialog.dart
    - lib/features/server/presentation/widgets/add_subscription_dialog.dart
  modified:
    - lib/app.dart
decisions:
  - "ArmaApp converted from ConsumerWidget to ConsumerStatefulWidget for one-time startup hook"
  - "serverRepo.getAllConfigs() is async (Future) — fixed plan code to await it"
metrics:
  duration: "5min"
  completed_date: "2026-04-05"
  tasks: 2
  files: 7
requirements:
  - CONF-02
  - CONF-04
  - CONF-07
  - CONF-08
  - CONF-10
---

# Phase 03 Plan 05: Subscription Service, QR Scanner & Config Sharing Summary

HTTP subscription service with custom UA, 15s timeout, 5MB limit + QR scanner with auto-detect (share link vs URL vs unknown) + QR display dialog with copy/share actions + add subscription dialog with form validation and loading state.

## Completed Tasks

### Task 1: SubscriptionService + SubscriptionNotifier provider + auto-refresh on launch
**Commit:** `811c431`

- Created `SubscriptionService` with HTTP fetch, custom User-Agent (D-05/CONF-08), 15s timeout and 5MB body size limit (T-03-15)
- Created `SubscriptionNotifier` with full lifecycle: add, refresh (D-13 replace-all), delete, and auto-refresh (D-04/CONF-07)
- D-14: Auto-selects first new server after refreshing subscription that contained active server
- D-14: Disconnects active connection before replacing servers from refreshed subscription
- Created `subscriptionRepositoryProvider` backed by Hive
- Updated `ArmaApp` from `ConsumerWidget` to `ConsumerStatefulWidget` with `addPostFrameCallback` for one-time auto-refresh trigger on launch

### Task 2: QR scanner screen + QR display dialog + Add subscription dialog
**Commit:** `f377e59`

- Created `QrScannerScreen`: full-screen camera scanner using `mobile_scanner` with `DetectionSpeed.noDuplicates`
- Auto-detect behavior (D-07): share links → import, HTTP URLs → subscription prompt, unknown → error snackbar
- T-03-12: Only known URI schemes processed (proxy share links + http/https)
- Scan overlay via `CustomPainter` with 250×250dp transparent cutout, primary-colored border
- Flash toggle (bottom-right) and camera switch (bottom-left) controls
- Created `QrDisplayDialog`: modal bottom sheet with 220×220 QR code, link preview, copy-to-clipboard and share actions
- Uses `ShareLinkGenerator.generate()` for QR data and `SharePlus.instance.share(ShareParams(text:))` for system share sheet
- Created `AddSubscriptionDialog`: form with URL (required, validated), name, User-Agent, auto-update toggle
- Loading state with `CircularProgressIndicator` during subscription fetch
- Error handling shows `subscriptionFetchError` below URL field on failure

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed async getAllConfigs() calls**
- **Found during:** Task 1
- **Issue:** Plan code used `serverRepo.getAllConfigs()` synchronously in for-loops, but `ServerRepository.getAllConfigs()` returns `Future<List<ServerConfig>>` — causes compile error
- **Fix:** Added `await` before `serverRepo.getAllConfigs()` in both `refreshSubscription()` and `deleteSubscription()` methods
- **Files modified:** `lib/features/server/presentation/providers/subscription_provider.dart`
- **Commit:** `811c431`

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-03-12 | QR scanner only processes known schemes (vless://, vmess://, trojan://, ss://, hysteria2://, http://, https://) |
| T-03-13 | Servers persist through existing ServerRepositoryImpl validation |
| T-03-14 | Default User-Agent mimics standard Chrome mobile browser |
| T-03-15 | 15s timeout + 5MB body size limit on subscription fetch |

## Self-Check: PASSED
