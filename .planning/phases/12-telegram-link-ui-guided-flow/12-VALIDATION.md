---
phase: 12
slug: telegram-link-ui-guided-flow
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test |
| **Config file** | `analysis_options.yaml` (project-level; Flutter default test discovery) |
| **Quick run command** | `flutter test test/features/dashboard/presentation/screens` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/features/dashboard/presentation/screens`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | TGUI-01 | — | Navigation only from explicit user action; no hidden redirects | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart -r compact` | ✅ | ✅ green |
| 12-01-02 | 02 | 2 | TGUI-02 | — | External bot link launch failure is surfaced to user with actionable feedback | widget | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart -r compact` | ✅ | ✅ green |
| 12-01-03 | 02 | 2 | TGUI-02 | — | Unauthorized outcome keeps user on screen and prompts re-login | widget | `flutter test test/features/dashboard/presentation/screens/telegram_link_guide_screen_test.dart -r compact` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Telegram app deep-link/open behavior differences across devices | TGUI-02 | Device environment impacts external app routing | Run app on device/emulator, tap `Open Telegram Bot`, confirm bot page opens or actionable fallback appears |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verified 2026-05-24

---

## Validation Audit 2026-05-24

| Metric | Count |
|--------|-------|
| Gaps found | 3 |
| Resolved | 3 |
| Escalated | 0 |
