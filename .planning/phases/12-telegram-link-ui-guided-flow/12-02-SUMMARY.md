---
phase: 12-telegram-link-ui-guided-flow
plan: 02
subsystem: dashboard
tags: [flutter, riverpod, ui, telegram]
requires:
  - phase: 12-telegram-link-ui-guided-flow
    provides: Route and dashboard entrypoint from 12-01
provides:
  - Full Telegram guided linking screen
  - Bot-link open CTA and paste action
  - Submit outcome UX mapping with success pop and unauthorized re-login prompt
  - Widget coverage for guided flow behaviors
affects: [phase-12, telegram-link-ui]
tech-stack:
  added: [url_launcher]
  patterns: [provider-driven submit, outcome-based snackbar feedback]
key-files:
  created:
    - lib/features/dashboard/presentation/screens/telegram_link_guide_screen.dart
    - lib/features/dashboard/presentation/widgets/telegram_link_step_card.dart
    - test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart
  modified:
    - lib/core/l10n/app_en.arb
    - lib/core/l10n/app_fa.arb
    - lib/core/l10n/app_hy.arb
    - lib/core/l10n/app_ru.arb
    - lib/core/l10n/app_zh.arb
requirements-completed: [TGUI-02]
completed: 2026-05-24
---

# Phase 12 Plan 02 Summary

Implemented the end-to-end Telegram guide flow: open bot, follow steps, paste Telegram ID, submit link, and handle typed outcomes with required navigation behavior.

## Self-Check: PASSED
