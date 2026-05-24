---
phase: 09
slug: default-servers-home-screen-display
status: partial
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-24
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Flutter test |
| **Config file** | `pubspec.yaml` |
| **Quick run command** | `flutter test -r compact` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~120 seconds |

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
| 09-01-01 | 01 | 1 | API-02,REL-01 | T-09-01 | cache parse/persistence tolerant to corrupt payloads | unit | `flutter test test/features/api/data/models/default_server_cache_model_test.dart test/features/api/data/datasources/default_server_cache_datasource_test.dart -r compact` | ✅ | ✅ green |
| 09-01-02 | 01 | 1 | API-02,UI-01 | T-09-02,T-09-03 | deterministic server-item mapping with guarded parse path | unit | `flutter test test/features/dashboard/data/mappers/default_server_item_mapper_test.dart -r compact` | ✅ | ✅ green |
| 09-02-01 | 02 | 2 | API-02,API-03,REL-01 | T-09-04,T-09-05,T-09-06 | provider state machine with typed error mapping and cache fallback | unit | `flutter test test/features/dashboard/presentation/providers/default_servers_provider_test.dart -r compact` | ✅ | ✅ green |
| 09-02-02 | 02 | 2 | REL-01 | T-09-04 | queued refresh retries are bounded/backoff-controlled | unit | `flutter test test/features/dashboard/presentation/providers/default_servers_provider_test.dart -r compact` | ✅ | ✅ green |
| 09-03-01 | 03 | 3 | UI-01,UI-02,API-03 | T-09-07,T-09-08 | dashboard section renders top-3/show-all/refresh/error contracts | widget | `flutter test test/features/dashboard/presentation/widgets/default_servers_section_test.dart -r compact` | ✅ | ✅ green |
| 09-03-02 | 03 | 3 | UI-01,REL-01 | T-09-09 | tap-to-connect behavior through active/connection providers | widget | `flutter test test/features/dashboard/presentation/widgets/default_servers_section_test.dart -r compact` | ✅ | ✅ green |
| 09-04-01 | 04 | 4 | API-03,REL-01 | T-09-GAP-01 | startup bootstraps required Hive boxes before provider reads | unit | `flutter test test/core/storage/app_hive_bootstrap_test.dart -r compact` | ✅ | ✅ green |
| 09-04-02 | 04 | 4 | API-03,REL-01 | T-09-GAP-02,T-09-GAP-03 | regression prevents ProviderException/HiveError crash path | unit | `flutter test test/features/dashboard/presentation/providers/default_servers_startup_regression_test.dart -r compact` | ✅ | ✅ green |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Validate final visual placement/spacing hierarchy against UI-SPEC on real device and RTL | UI-01 | subjective visual quality across device sizes/locales | Open dashboard on target devices/locales and compare with `09-UI-SPEC.md` |
| End-to-end reconnect behavior against real VPN runtime/server | UI-01, REL-01 | requires real platform VPN state transitions | Connect to one server, switch to another default server while connected, verify tunnel/server switch |
| Runtime failure UX under real network/backend conditions | API-03, REL-01 | mocked tests cannot fully replicate all transport/backend conditions | Simulate offline/timeout/401/5xx and confirm localized snackbar + cache fallback behavior |

---

## Validation Audit 2026-05-24

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated to manual-only | 3 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** partial 2026-05-24
