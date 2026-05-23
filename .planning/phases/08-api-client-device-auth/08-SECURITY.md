---
phase: 08
slug: api-client-device-auth
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
---

# Phase 08 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| app -> remote VPN API | Client sends auth payload and receives token/keys from untrusted network | device_id, app_version, token, server key payloads |
| secure storage -> app runtime | Secrets and identifiers restored from encrypted local storage | token, device_id, auth metadata |
| app startup lifecycle -> provider graph | Automatic bootstrap triggers remote auth flow | auth state + network errors |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-08-01 | T | API DTO mapping | mitigate | Strict typed decoding + `FormatException` on invalid payload shape (`device_auth_response.dart`, `default_server_key_model.dart`) | closed |
| T-08-02 | I | App config/token contract | mitigate | Centralized API constants in `AppConfig`; opaque token handling (no JWT parsing) | closed |
| T-08-03 | I | auth_local_datasource | mitigate | Secure-storage-backed AES key + encrypted Hive auth box initialization | closed |
| T-08-04 | S | device_id_service | mitigate | Persist/reuse resolved device ID; no caller-injected HWID path | closed |
| T-08-05 | R | API request handling | mitigate | Typed API errors + bounded retry behavior | closed |
| T-08-06 | I | provider/repository logging | mitigate | Redacted diagnostics; no plaintext token/HWID logging paths | closed |
| T-08-07 | D | retry policy | mitigate | Single retry max for transient errors; no retry for 4xx | closed |
| T-08-GAP-01 | D | startup bootstrap | mitigate | One-time startup bootstrap/idempotency guard with tests | closed |
| T-08-GAP-02 | I | bootstrap error/logging | mitigate | Bootstrap path avoids plaintext secret logging | closed |
| T-08-GAP-03 | S | device_id_service | mitigate | Stable Android ID semantics + migration from weak legacy IDs | closed |
| T-08-GAP-04 | R | reinstall claims | mitigate | Executable reinstall/update semantics tests | closed |

*Status: open · closed*  
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 11 | 11 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
