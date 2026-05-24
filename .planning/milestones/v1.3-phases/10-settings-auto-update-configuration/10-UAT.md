---
status: testing
phase: 10-settings-auto-update-configuration
source:
  - 10-01-SUMMARY.md
  - 10-02-SUMMARY.md
  - 10-03-SUMMARY.md
  - 10-04-SUMMARY.md
  - 10-05-SUMMARY.md
started: 2026-05-24T13:55:17Z
updated: 2026-05-24T13:58:03Z
---

## Current Test
<!-- OVERWRITE each test - shows where we are -->

number: 2
name: Selected auto-update interval persists
expected: |
  Change the auto-update interval, leave the screen (or restart app), and verify the same interval remains selected.
awaiting: user response

## Tests

### 1. Auto-update controls are visible and ordered
expected: Open Settings and confirm an "Arma VPN settings" section appears near the top with exactly four auto-update options: Disabled, Every 12 Hours, Every 24 Hours, and Every 7 Days.
result: pass

### 2. Selected auto-update interval persists
expected: Change the auto-update interval, leave the screen (or restart app), and verify the same interval remains selected.
result: pending

### 3. Auto-update changes trigger refresh policy without breaking dashboard usage
expected: After changing interval, dashboard default servers remain usable (list loads/refresh works and tap-to-connect flow is still normal).
result: pending

### 4. Overdue refresh indicator appears only after overdue fallback success
expected: After a missed refresh window and a successful overdue recovery, Settings shows a subtle "updated" indicator with timestamp; it should not be shown during normal non-overdue states.
result: pending

### 5. Expired default servers are removed on refresh
expected: When a refresh includes expired keys, those expired entries are no longer shown from cache after sync.
result: pending

### 6. Retry behavior remains bounded and app stays responsive during failures
expected: During failed refresh attempts, retries remain bounded (no endless rapid loop) and the app stays responsive with existing offline/error behavior.
result: pending

## Summary

total: 6
passed: 1
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps

[none yet]
