---
phase: 1
slug: telegram-link-status-refresh
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-24
---

# Phase 1 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test |
| **Config file** | none |
| **Quick run command** | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds |

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | TGSTAT-01 | — | Step-3 status refresh uses auth pipeline and updates UI states | widget | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart` | ✅ | ⬜ pending |
| 01-01-02 | 01 | 1 | TGVER-01 | — | Auth payload app version uses shared Settings source | unit | `flutter test test/features/api/presentation/providers/auth_provider_test.dart` | ✅ | ⬜ pending |

## Wave 0 Requirements

- [ ] `test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart` — add Step-3 status-check coverage
- [ ] `test/features/api/presentation/providers/auth_provider_test.dart` — add app-version source wiring assertion

## Manual-Only Verifications

All phase behaviors have automated verification.

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
