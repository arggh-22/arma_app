---
phase: 02-vpn-engine-core-connection
plan: 05
subsystem: ui
tags: [connect-button, animation, flutter-animate, connection-timer, traffic-stats, dashboard, riverpod]

# Dependency graph
requires:
  - phase: 02-04
    provides: "ConnectionNotifier, TrafficStatsNotifier, ConnectionStatus sealed class, TrafficStats"
  - phase: 02-02
    provides: "formatSpeed() speed formatter"
provides:
  - "ConnectButton: animated ConsumerWidget with 4 visual states (grey/pulsing-teal/teal-glow/grey)"
  - "ConnectionTimer: ConsumerStatefulWidget showing HH:MM:SS elapsed connection time"
  - "TrafficStatsCard: real-time ↓ download / ↑ upload speed display cards"
  - "DashboardScreen: fully wired with live Riverpod providers, no placeholders"
affects: []

# Tech tracking
tech-stack:
  added: [flutter_animate ^4.5.2]
  patterns: [flutter_animate shimmer + scale chaining, ConsumerStatefulWidget with Timer.periodic, Dart 3 switch expression for sealed class rendering]

key-files:
  created:
    - lib/features/connection/presentation/widgets/connection_timer.dart
    - lib/features/connection/presentation/widgets/traffic_stats_card.dart
  modified:
    - pubspec.yaml
    - lib/features/dashboard/presentation/widgets/connect_button.dart
    - lib/features/dashboard/presentation/screens/dashboard_screen.dart
    - lib/core/l10n/app_en.arb
    - lib/core/l10n/app_ru.arb
    - lib/core/l10n/app_fa.arb
    - lib/core/l10n/app_zh.arb
    - lib/core/l10n/app_localizations.dart
    - lib/core/l10n/app_localizations_en.dart
    - lib/core/l10n/app_localizations_fa.dart
    - lib/core/l10n/app_localizations_ru.dart
    - lib/core/l10n/app_localizations_zh.dart

key-decisions:
  - "flutter_animate used for pulsing scale + shimmer animation on connecting state (D-03)"
  - "AnimatedContainer handles color/shadow transitions between states for smooth visual feedback"
  - "ConnectionTimer uses DateTime.now().difference(connectedAt) for drift-free elapsed time"
  - "l10n keys 'connecting' and 'connected' added to all 4 locales (EN/RU/FA/ZH)"

patterns-established:
  - "Switch expression on sealed ConnectionStatus for widget rendering (4-way visual switch)"
  - "ConsumerStatefulWidget + ref.listen + Timer.periodic for periodic UI updates"

requirements-completed: [UI-02, MON-01, MON-02]

# Metrics
duration: 4min
completed: 2026-04-05
---

# Phase 02 Plan 05: Dashboard UI — Animated Connect Button, Timer & Traffic Stats Summary

**Animated connect button with D-03 state transitions (grey→pulsing teal→teal glow), HH:MM:SS connection timer, and real-time ↑↓ traffic speed cards using flutter_animate — dashboard fully wired with live Riverpod providers, all Phase 1 placeholders replaced**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-05T11:12:30Z
- **Completed:** 2026-04-05T11:16:12Z
- **Tasks:** 2
- **Files modified:** 13

## Accomplishments
- ConnectButton rewritten as ConsumerWidget with 4 visual states: grey (disconnected) → pulsing teal with shimmer (connecting) → solid teal glow with BoxShadow (connected) → grey (disconnecting)
- flutter_animate ^4.5.2 added for scale + shimmer animation chaining during connecting state
- AnimatedContainer provides smooth 300ms color/shadow transitions between all states
- Tap calls ConnectionNotifier.connect(activeServer) on disconnected, disconnect() on connected, ignored during transitions (D-03, T-02-17)
- ConnectionTimer as ConsumerStatefulWidget showing HH:MM:SS elapsed time with Timer.periodic (D-04)
- Timer calculates elapsed from Connected.connectedAt for drift-free accuracy across app resume
- TrafficStatsCard with two side-by-side Card widgets: ↓ download (green) and ↑ upload (blue) speeds using formatSpeed() from Plan 02-02 (D-05)
- DashboardScreen fully wired: ConnectButton → status text (color-coded) → ConnectionTimer → ActiveServerCard → TrafficStatsCard
- TrafficStatsPlaceholder no longer imported (replaced by TrafficStatsCard)
- l10n keys "connecting" and "connected" added to all 4 locales (EN, RU, FA, ZH)
- flutter analyze passes with no issues on all modified files
- flutter build apk --debug compiles successfully

## Task Commits

Each task was committed atomically:

1. **Task 1: Animated ConnectButton + ConnectionTimer** - `e5226a9` (feat)
2. **Task 2: TrafficStatsCard + wire DashboardScreen** - `c21f07e` (feat)

## Files Created/Modified
- `pubspec.yaml` - Added flutter_animate ^4.5.2 dependency
- `lib/features/dashboard/presentation/widgets/connect_button.dart` - Rewritten: ConsumerWidget with 4-state animation
- `lib/features/connection/presentation/widgets/connection_timer.dart` - New: HH:MM:SS elapsed timer
- `lib/features/connection/presentation/widgets/traffic_stats_card.dart` - New: ↓↑ real-time traffic cards
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` - Rewritten: live providers, no placeholders
- `lib/core/l10n/app_en.arb` - Added connecting, connected keys
- `lib/core/l10n/app_ru.arb` - Added connecting, connected keys
- `lib/core/l10n/app_fa.arb` - Added connecting, connected keys
- `lib/core/l10n/app_zh.arb` - Added connecting, connected keys
- `lib/core/l10n/app_localizations*.dart` - Regenerated with new keys

## Decisions Made
- **flutter_animate for connecting animation:** Used scale + shimmer chaining with repeat for the pulsing teal effect. AnimatedContainer handles the static transitions (color/shadow changes). This gives a satisfying Happ-style connecting feel.
- **Drift-free timer:** ConnectionTimer uses `DateTime.now().difference(connectedAt)` on each tick rather than incrementing a counter, ensuring accuracy even after app resume.
- **l10n completeness:** Added connecting/connected translations to all 4 locale files rather than hardcoding English strings.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing l10n] Added l10n keys to all locales**
- **Found during:** Task 2
- **Issue:** Plan suggested hardcoded strings if l10n setup was complex; ARB files were straightforward
- **Fix:** Added "connecting" and "connected" keys to all 4 ARB files (EN/RU/FA/ZH) and regenerated
- **Files modified:** 4 ARB files + 5 generated l10n files
- **Commit:** c21f07e

## Issues Encountered
None.

## User Setup Required
None.

## Next Phase Readiness
- Phase 02 (VPN Engine & Core Connection) is now COMPLETE
- All 5 plans executed: AAR integration → config builder → VPN service → platform channels → dashboard UI
- Dashboard is a fully interactive VPN control interface with animated connect button, live timer, and real-time traffic stats
- Ready for Phase 03 (Subscriptions & Advanced Config) or Phase transition

---
*Phase: 02-vpn-engine-core-connection*
*Completed: 2026-04-05*

## Self-Check: PASSED

All 4 key files verified present. Both task commits (e5226a9, c21f07e) verified in git log. flutter analyze clean, APK build successful.
