---
phase: 17
slug: dashboard-35-65-layout-refresh
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
---

# Phase 17 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test (`flutter_test`) |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~180 seconds |

## Sampling Rate

- After each task commit: targeted widget tests for modified dashboard widgets
- After each plan wave: `flutter test`
- Before `/gsd-verify-work`: run phase-targeted dashboard test suite

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| 17-01-01 | 01 | 1 | DLAY-01, DLAY-02 | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_layout_grouping_test.dart` | ⬜ pending |
| 17-01-02 | 01 | 1 | DLAY-03 | widget | `flutter test test/features/dashboard/presentation/screens/dashboard_screen_announcement_section_test.dart` | ⬜ pending |
| 17-01-03 | 01 | 1 | DLAY-04 | widget | `flutter test test/features/dashboard/presentation/widgets/active_server_card_parked_style_test.dart` | ⬜ pending |

## Wave 0 Requirements

Add missing layout/parked-style dashboard tests before implementation turns green.

## Manual-Only Verifications

Manual UAT needed for final subjective 35/65 visual perception on real device sizes.

## Validation Sign-Off

- [x] Validation strategy exists before planning
- [x] Requirements mapped to planned automated checks
- [x] Nyquist artifact present for checker gate

**Approval:** pending phase execution
