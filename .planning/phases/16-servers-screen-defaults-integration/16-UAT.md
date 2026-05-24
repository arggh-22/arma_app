---
status: complete
phase: 16-servers-screen-defaults-integration
source:
  - .planning/phases/16-servers-screen-defaults-integration/16-01-SUMMARY.md
  - .planning/phases/16-servers-screen-defaults-integration/16-02-SUMMARY.md
started: "2026-05-25T01:16:00+04:00"
updated: "2026-05-25T01:38:30+04:00"
---

## Current Test

[testing complete]

## Tests

### 1. Defaults section visibility and order
expected: On Servers screen in normal mode, a dedicated default-servers section is visible above imported/custom server groups. When multi-select mode is activated, the default-servers section is hidden.
result: pass

### 2. Defaults section collapse behavior
expected: Default-servers section starts expanded each time the screen is opened and can be collapsed/expanded with its toggle.
result: issue
reported: 'endpoint /keys/ returns data like [ { "id": 15, "name": "Пробный (Приложение) #1", "key_body": "vless://...", "subscription_url": "https://your-domain.com/sub/user_42_abcdef", "expire_date": "2026-05-24T18:30:00Z", "is_active": true, "status": "active", "used_traffic": 104857600, "data_limit": 5368709120 } ] each item of array one sub link(its have more then one vpn server(for example different zones)) the item have subscription_url json key please using that url request and get servers list and show servers under her sub-link(this logic implemented in custom servers(when i tap import server after Clipboard its using subscription_url shows sublink colapsible group with server list)) i want the same for default servers section in "servers" screen'
severity: major

### 3. Default-row tap parity
expected: Tapping a default server selects it; if currently connected to a different server, the app disconnects then reconnects to the tapped one. If already selected/same target, no redundant reconnect occurs.
result: pass

### 4. Imported-group regression safety
expected: Imported/custom server group collapse/expand and selection behaviors still work as before with defaults integration present.
result: pass

## Summary

total: 4
passed: 3
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Default-servers section starts expanded each time the screen is opened and can be collapsed/expanded with its toggle."
  status: failed
  reason: 'User reported: endpoint /keys/ returns data like [ { "id": 15, "name": "Пробный (Приложение) #1", "key_body": "vless://...", "subscription_url": "https://your-domain.com/sub/user_42_abcdef", "expire_date": "2026-05-24T18:30:00Z", "is_active": true, "status": "active", "used_traffic": 104857600, "data_limit": 5368709120 } ] each item of array one sub link(its have more then one vpn server(for example different zones)) the item have subscription_url json key please using that url request and get servers list and show servers under her sub-link(this logic implemented in custom servers(when i tap import server after Clipboard its using subscription_url shows sublink colapsible group with server list)) i want the same for default servers section in "servers" screen'
  severity: major
  test: 2
  artifacts: []
  missing: []
