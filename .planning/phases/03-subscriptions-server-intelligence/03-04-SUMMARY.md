---
phase: 03-subscriptions-server-intelligence
plan: 04
subsystem: log-viewer
tags: [logs, diagnostics, ring-buffer, share-plus, monitoring]
dependency_graph:
  requires: ["03-01"]
  provides: ["log-viewer", "log-export", "diagnostics-settings"]
  affects: ["settings-screen", "app-router"]
tech_stack:
  added: []
  patterns: ["ring-buffer", "stream-broadcast", "auto-scroll-detection"]
key_files:
  created:
    - lib/features/log/data/services/log_service.dart
    - lib/features/log/presentation/providers/log_provider.dart
    - lib/features/log/presentation/providers/log_provider.g.dart
    - lib/features/log/presentation/screens/log_viewer_screen.dart
  modified:
    - lib/features/settings/presentation/screens/settings_screen.dart
    - lib/core/router/app_router.dart
decisions:
  - "Ring buffer uses in-memory List<String> with removeAt(0) eviction — simple and sufficient for 5000 lines"
  - "share_plus 12.x API: SharePlus.instance.share(ShareParams(files: [XFile(...)]))"
  - "Riverpod 4.x shortened provider name: logLinesProvider (not logLinesNotifierProvider)"
metrics:
  duration: 11min
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 2
  completed: "2026-04-05T17:06:00Z"
---

# Phase 03 Plan 04: Log Viewer & Export Summary

Ring buffer LogService capturing Xray debug events via EventChannel, monospace log viewer screen with level filtering/search/auto-scroll/export, and Settings entry point under Diagnostics section.

## One-liner

5000-line ring buffer log service streaming VPN debug events to a filterable monospace viewer with share_plus file export.

## What Was Built

### Task 1: LogService + LogProvider (a04d0b7)

**LogService** (`lib/features/log/data/services/log_service.dart`):
- Ring buffer with `static const int maxLines = 5000` and `removeAt(0)` eviction
- `StreamController<String>.broadcast()` for live log line streaming
- `addLine()` prepends `[HH:MM:SS]` timestamp to each line
- `exportAndShare()` writes buffer to timestamped `.txt` file in app documents directory, then shares via `SharePlus.instance.share(ShareParams(files: [XFile(...)]))` 
- `clear()` and `dispose()` for lifecycle management

**LogProvider** (`lib/features/log/presentation/providers/log_provider.dart`):
- `logServiceProvider` (keepAlive) — singleton LogService that subscribes to `VpnPlatformService.vpnEvents` filtered by `type == 'debug'`
- `LogLinesNotifier` (keepAlive) — reactive `List<String>` state rebuilt on each new log line via stream subscription

### Task 2: LogViewerScreen + Settings Entry + Route (768f780)

**LogViewerScreen** (`lib/features/log/presentation/screens/log_viewer_screen.dart`):
- Full-screen pushed route (not a tab)
- AppBar with "View Logs" title and export `IconButton(Icons.upload_file)` 
- Filter bar: `DropdownButton` (All/Info/Warning/Error) + search `TextField` with `Icons.search`
- `ListView.builder` with monospace font (`fontFamily: 'monospace'`, 12sp)
- Color-coded log lines: error lines in `colorScheme.error`, warning lines in `Colors.orange`, timestamp prefix in `onSurfaceVariant`
- Auto-scroll: enabled by default, disables when user scrolls up >50px from bottom, re-enableable via `Switch` in status bar
- Status bar: line count (`linesCount`) + auto-scroll toggle
- Empty state: centered "No logs yet" with subtitle

**Settings Integration** (`lib/features/settings/presentation/screens/settings_screen.dart`):
- New "Diagnostics" section between General and About
- "View Logs" `ListTile` with `Icons.article_outlined` and `context.push('/logs')`

**Router** (`lib/core/router/app_router.dart`):
- `/logs` `GoRoute` registered outside `StatefulShellRoute.indexedStack`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed unused import in log_service.dart**
- **Found during:** Task 1
- **Issue:** `package:flutter/foundation.dart` was imported but not used
- **Fix:** Removed the unused import
- **Files modified:** `lib/features/log/data/services/log_service.dart`
- **Commit:** a04d0b7

**2. [Rule 1 - Bug] Fixed generated provider name mismatch**
- **Found during:** Task 2
- **Issue:** Plan used `logLinesNotifierProvider` but Riverpod 4.x generates `logLinesProvider` (shortened name convention)
- **Fix:** Changed to `logLinesProvider` in log_viewer_screen.dart
- **Files modified:** `lib/features/log/presentation/screens/log_viewer_screen.dart`
- **Commit:** 768f780

## Verification Results

- `flutter analyze --no-fatal-infos`: 0 errors, 0 new warnings (only pre-existing avoid_print/unused_element)
- All acceptance criteria verified via grep:
  - LogService: class, maxLines=5000, logStream, exportAndShare, ring buffer eviction
  - LogProvider: logServiceProvider, debug event filtering, LogLinesNotifier
  - LogViewerScreen: class, monospace, DropdownButton, ScrollController, export, l10n keys
  - Settings: diagnosticsSection, viewLogs, context.push('/logs')
  - Router: '/logs', LogViewerScreen

## Threat Surface

| Threat ID | Status | Mitigation |
|-----------|--------|------------|
| T-03-10 | ✅ Mitigated | Export only via explicit user action (export button → share sheet), never automatic |
| T-03-11 | ✅ Mitigated | Ring buffer capped at 5000 lines with removeAt(0) eviction |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | a04d0b7 | LogService ring buffer + LogProvider for VPN debug events |
| 2 | 768f780 | LogViewerScreen with filtering, search, auto-scroll + Settings entry |

## Self-Check: PASSED
