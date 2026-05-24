---
phase: 08
slug: api-client-device-auth
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-24
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test -r compact` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test -r compact`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | API-01 | T-08-01 | strict DTO decode + malformed payload rejection | unit | `flutter test test/features/api/data/models -r compact` | ✅ | ✅ green |
| 08-01-02 | 01 | 1 | SEC-01 | T-08-02 | centralized API config + opaque token handling | static/unit | `flutter analyze lib/config/app_config.dart lib/features/api/domain/entities lib/features/api/data/models` | ✅ | ✅ green |
| 08-02-01 | 02 | 2 | SEC-01 | T-08-03 | encrypted auth/device persistence at rest | unit | `flutter test test/features/api/data/datasources/auth_local_datasource_test.dart -r compact` | ✅ | ✅ green |
| 08-02-02 | 02 | 2 | API-01 | T-08-04 | deterministic persisted device ID resolution | unit | `flutter test test/features/api/data/services/device_id_service_test.dart -r compact` | ✅ | ✅ green |
| 08-03-01 | 03 | 3 | API-01 | T-08-05,T-08-07 | bounded retry + typed API failure behavior | unit | `flutter test test/features/api/data/datasources/api_client_test.dart -r compact` | ✅ | ✅ green |
| 08-03-02 | 03 | 3 | API-01 | T-08-05 | token lifecycle + 401 re-auth orchestration | unit | `flutter test test/features/api/data/repositories/auth_repository_impl_test.dart -r compact` | ✅ | ✅ green |
| 08-03-03 | 03 | 3 | API-01 | T-08-06 | provider wiring with safe retryable error flow | unit | `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/api/presentation/providers/auth_provider_test.dart -r compact` | ✅ | ✅ green |
| 08-04-01 | 04 | 4 | API-01 | T-08-GAP-01 | startup bootstrap auth is idempotent | unit | `flutter test test/features/api/presentation/providers/auth_bootstrap_provider_test.dart -r compact` | ✅ | ✅ green |
| 08-04-02 | 04 | 4 | API-01 | T-08-GAP-01,T-08-GAP-02 | app lifecycle triggers bootstrap once without UI blocking | unit/analyze | `flutter test test/features/api/presentation/providers/auth_bootstrap_provider_test.dart -r compact && flutter analyze lib/app.dart lib/features/api/presentation/providers/auth_bootstrap_provider.dart` | ✅ | ✅ green |
| 08-05-01 | 05 | 4 | API-01,SEC-01 | T-08-GAP-03 | stable Android ID strategy + migration from legacy weak ID | unit | `flutter test test/features/api/data/services/device_id_service_test.dart -r compact` | ✅ | ✅ green |
| 08-05-02 | 05 | 4 | API-01,SEC-01 | T-08-GAP-04 | reinstall/update semantics proven with executable tests | unit | `flutter test test/features/api/data/services/device_id_service_test.dart test/features/api/data/services/device_id_reinstall_semantics_test.dart -r compact` | ✅ | ✅ green |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Audit 2026-05-24

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-24
