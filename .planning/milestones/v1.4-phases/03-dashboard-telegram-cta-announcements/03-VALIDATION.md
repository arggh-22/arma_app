---
phase: 03
slug: dashboard-telegram-cta-announcements
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (package:flutter_test) |
| **Config file** | `pubspec.yaml` (no dedicated test config file) |
| **Quick run command** | `flutter test test/features/api/presentation/providers/auth_bootstrap_provider_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run targeted `flutter test` command(s) for modified behavior
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** UAT plus targeted automated checks must be green
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | TGANN-01 | T-03-02 | Announcement fields parsed/mapped with strict type validation | unit | `flutter test test/features/api/data/models/device_auth_response_test.dart` | ✅ | ✅ green |
| 03-01-02 | 01 | 1 | TGCTA-01, TGCTA-02 | T-03-01, T-03-06 | Guest/linked CTA branch uses fixed bot URI and auth guest flag | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_telegram_link_fab_test.dart` | ✅ | ✅ green |
| 03-01-03 | 01 | 1 | TGANN-01, TGANN-02 | T-03-05 | Announcement matrix/read-more behavior plus FAB scroll regression behavior | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart` | ✅ | ✅ green |
| 03-02-01 | 02 | 2 | TGANN-01 | T-03-07, T-03-08 | App-open bootstrap forces `/auth/device/` refresh and preserves prewarm sequencing | provider | `flutter analyze lib/features/api/presentation/providers/auth_bootstrap_provider.dart lib/app.dart` | ✅ | ✅ green |
| 03-02-02 | 02 | 2 | TGANN-02 | T-03-09 | Bootstrap tests assert refresh/prewarm call counts and rerun behavior | provider | `flutter test test/features/api/presentation/providers/auth_bootstrap_provider_test.dart` | ✅ | ✅ green |

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
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-24

## Validation Audit 2026-05-24

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
