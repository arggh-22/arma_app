---
phase: 09
slug: default-servers-home-screen-display
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
---

# Phase 09 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| API fetch -> dashboard provider | Untrusted remote key payload enters UI state layer | status, traffic values, key metadata |
| local cache -> provider/UI | Persisted cache used on offline/failure paths | default server snapshots |
| dashboard taps -> connection flow | UI interaction triggers active server selection and reconnect path | selected server identity, connection state |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-09-01 | T | default server cache model/datasource | mitigate | strict model parse + corrupt fallback handling | closed |
| T-09-02 | D | default server mapper | mitigate | guarded malformed `keyBody` parse path | closed |
| T-09-03 | S | mapper id normalization | mitigate | deterministic `default-api-{id}` identity strategy | closed |
| T-09-04 | D | default servers provider retry | mitigate | bounded exponential retry schedule | closed |
| T-09-05 | R | failure classification | mitigate | explicit `ApiClientException.type` -> typed UI failure mapping | closed |
| T-09-06 | E | unauthorized recovery path | mitigate | one-shot re-auth then explicit auth failure | closed |
| T-09-07 | E | tap-to-connect handler | mitigate | connectability gate + provider-based connect path | closed |
| T-09-08 | I | error/snackbar copy | mitigate | typed message mapping avoids raw exception leakage | closed |
| T-09-09 | D | reconnect branch | mitigate | reconnect only when connected and server differs | closed |
| T-09-GAP-01 | D | startup storage init | mitigate | open `default_server_cache` before provider graph starts | closed |
| T-09-GAP-02 | R | regression reproducibility | mitigate | deterministic startup regression test coverage | closed |
| T-09-GAP-03 | I | provider error propagation | mitigate | provider returns typed failure state instead of crash | closed |

---

## Accepted Risks Log

No accepted risks.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 12 | 12 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24
