---
status: complete
phase: 17-dashboard-35-65-layout-refresh
source:
  - .planning/phases/17-dashboard-35-65-layout-refresh/17-01-SUMMARY.md
started: "2026-05-25T01:55:00+04:00"
updated: "2026-05-25T02:32:11+04:00"
---

## Current Test

[testing complete]

## Tests

### 1. Dashboard top/bottom grouped composition
expected: Dashboard visually reads as top and bottom groups (35/65 style) while remaining in a single scroll layout. The grouping containers are present and the screen still scrolls normally.
result: pass

### 2. Top panel required content
expected: Top group shows connect control, connection status/timer, selected server card, and statistics path (when stats preference is enabled).
result: pass

### 3. Bottom panel ordering and visibility
expected: Bottom group shows announcement first when announcement content exists, then default servers. When no announcement content exists, announcement block is hidden and default servers move up.
result: pass

### 4. Selected server parked highlight
expected: When a server is selected, ActiveServerCard shows a clear parked/highlighted treatment; when no server is selected, neutral state styling remains.
result: issue
reported: "selected server highlighted but in default servers list at bottom not selected/highlighted"
severity: major

## Summary

total: 4
passed: 3
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "When a server is selected, ActiveServerCard shows a clear parked/highlighted treatment; when no server is selected, neutral state styling remains."
  status: failed
  reason: "User reported: selected server highlighted but in default servers list at bottom not selected/highlighted"
  root_cause: "Selected/parked styling was implemented only in ActiveServerCard; DefaultServersSection tiles do not consume activeServerProvider to render selected highlight state."
  severity: major
  test: 4
  artifacts:
    - "lib/features/dashboard/presentation/widgets/active_server_card.dart:20,24-36 implement selected styling via activeServerProvider."
    - "lib/features/dashboard/presentation/widgets/default_servers_section.dart:26,88-91,161-164,170-223 show no selected-state input/branch for tile highlight."
    - "test/features/dashboard/presentation/widgets/default_servers_section_test.dart: existing tests cover refresh/tap flows but not selected/highlighted tile state."
  missing:
    - "Selected-server state propagation into DefaultServersSection tile rendering."
    - "Selected visual treatment for default server tile when tile server matches active server."
    - "Regression test coverage for bottom-list selected/highlight parity with ActiveServerCard."
