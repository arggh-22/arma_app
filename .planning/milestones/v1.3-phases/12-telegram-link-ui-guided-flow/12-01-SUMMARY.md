---
phase: 12-telegram-link-ui-guided-flow
plan: 01
subsystem: dashboard
tags: [flutter, go-router, ui, navigation]
requires:
  - phase: 11-telegram-link-api-integration
    provides: Telegram link provider/outcome contract
provides:
  - Dashboard Link FAB with Telegram icon
  - Scroll-direction hide/show behavior for Link FAB
  - /telegram-link route wiring from Dashboard
affects: [phase-12, telegram-link-ui]
tech-stack:
  added: [font_awesome_flutter]
  patterns: [go_router push route, scroll notification visibility toggle]
key-files:
  created:
    - test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart
  modified:
    - lib/core/router/app_router.dart
    - lib/features/dashboard/presentation/screens/dashboard_screen.dart
requirements-completed: [TGUI-01]
completed: 2026-05-24
---

# Phase 12 Plan 01 Summary

Dashboard now exposes a floating `Link` action with Telegram icon, hides it on downward scroll, shows it on upward scroll, and opens the Telegram guide route.

## Self-Check: PASSED
