---
phase: 13
slug: telegram-link-ux-hardening-validation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter `flutter_test` |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart` |
| **Full suite command** | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart test/features/api/presentation/providers/telegram_link_provider_test.dart test/features/api/data/repositories/telegram_link_repository_impl_test.dart` |
| **Estimated runtime** | ~3 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart`
- **After every plan wave:** Run `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart test/features/api/presentation/providers/telegram_link_provider_test.dart test/features/api/data/repositories/telegram_link_repository_impl_test.dart`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | TGUI-03 | T-13-01 / T-13-02 | In-flight disables controls, deterministic feedback, retry-ready submit path | widget | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart` | ✅ | ✅ green |
| 13-02-01 | 02 | 2 | TGREL-01 | T-13-04 | Provider enforces validation + duplicate-submit guard and recovers after fallback | unit | `flutter test test/features/api/presentation/providers/telegram_link_provider_test.dart` | ✅ | ✅ green |
| 13-02-02 | 02 | 2 | TGREL-01 | T-13-03 | Repository maps typed/unexpected failures to stable outcomes | unit | `flutter test test/features/api/data/repositories/telegram_link_repository_impl_test.dart` | ✅ | ✅ green |
| 13-02-03 | 02 | 2 | TGUI-03 / TGREL-01 | T-13-01 / T-13-02 / T-13-03 / T-13-04 | Cross-surface regression matrix remains green | integration | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart test/features/api/presentation/providers/telegram_link_provider_test.dart test/features/api/data/repositories/telegram_link_repository_impl_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-24
