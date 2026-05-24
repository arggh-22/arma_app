---
status: complete
phase: 03-dashboard-telegram-cta-announcements
source: 03-01-SUMMARY.md
started: 2026-05-24T19:14:09Z
updated: 2026-05-24T19:22:00Z
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
result: pass

### 4. Read more bottom sheet
expected: When announcement text exists, Read more opens bottom sheet with full text.
result: pass

## Summary

total: 4
passed: 4
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
