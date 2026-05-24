---
status: partial
phase: 09-default-servers-home-screen-display
source: [09-VERIFICATION.md]
started: 2026-05-24T00:00:00Z
updated: 2026-05-24T03:55:00Z
---

## Current Test

number: 2
name: Real end-to-end connect flow
expected: Disconnected tap selects default server; connected tap switches server via disconnect/reconnect path.
awaiting: user response

## Tests

### 1. Visual placement & UX contract
expected: Dashboard placement and visual behavior match UI-SPEC (bottom-half section, top-3 preview, show-all sheet, badge/progress visuals).
result: issue
severity: blocker
reported: "Unhandled ProviderException on dashboard load: HiveError 'Box not found. Did you forget to call Hive.openBox()?' in defaultServerCacheDatasourceProvider; default servers flow crashes before UI validation."

### 2. Real end-to-end connect flow
expected: Disconnected tap selects default server; connected tap switches server via disconnect/reconnect path.
result: pending

### 3. Live API failure UX
expected: Timeout/offline/401/server failures show correct localized runtime feedback and cache fallback behavior.
result: pending

## Summary

total: 3
passed: 0
issues: 1
pending: 2
skipped: 0
blocked: 0

## Gaps

- truth: "Dashboard default servers section should load safely without provider startup crash."
  status: failed
  reason: "User reported ProviderException/HiveError: default_server_cache box not opened before provider use."
  severity: blocker
  test: 1
  artifacts:
    - lib/features/api/presentation/providers/default_server_cache_provider.dart
    - lib/features/dashboard/presentation/providers/default_servers_provider.dart
    - lib/main.dart
  missing:
    - "Open the default server cache Hive box during app bootstrap before providers read it."
