---
status: diagnosed
phase: 03-dashboard-telegram-cta-announcements
source: 03-01-SUMMARY.md
started: 2026-05-24T19:14:09Z
updated: 2026-05-24T19:14:09Z
---

## Current Test

[testing complete]

## Tests

### 1. Guest CTA behavior
expected: As guest (`is_guest=true`), dashboard shows Link FAB and tapping opens Telegram link guide.
result: pass

### 2. Linked CTA behavior
expected: As linked (`is_guest=false`), dashboard shows icon-only Telegram FAB and tapping opens @devarmabot externally.
result: pass

### 3. Announcement freshness on app open
expected: On every app open, app calls `/auth/device/` so announcements shown on dashboard are fresh.
result: issue
reported: "please on every app open call /auth/device/ endpoint to get Announcements"
severity: major

### 4. Read more bottom sheet
expected: When announcement text exists, Read more opens bottom sheet with full text.
result: skipped
reason: User deferred validation pending announcement freshness behavior.

## Summary

total: 4
passed: 2
issues: 1
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "On every app open, `/auth/device/` is called so dashboard announcement content is fresh."
  status: failed
  reason: "User reported: please on every app open call /auth/device/ endpoint to get Announcements"
  severity: major
  test: 3
  root_cause: "`authBootstrapProvider` uses `authTokenProvider`, which can return a still-valid persisted token without forcing a fresh `/auth/device/` call."
  artifacts:
    - path: "lib/features/api/presentation/providers/auth_bootstrap_provider.dart"
      issue: "Bootstrap path does not force `authenticateDevice()` on every app open."
    - path: "lib/app.dart"
      issue: "Startup bootstrap depends on token prewarm path, not guaranteed fresh device-auth fetch."
  missing:
    - "Force `/auth/device/` execution on each app open bootstrap (cold start), then continue default server prewarm."
    - "Add provider-level test coverage proving bootstrap triggers a fresh device-auth call."
  debug_session: ""
