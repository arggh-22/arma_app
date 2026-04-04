---
phase: 01-foundation-config-import
plan: 03
subsystem: share-link-parsers
tags: [tdd, parsers, vless, vmess, trojan, shadowsocks, hysteria2, share-link, uri-parsing]
dependency_graph:
  requires: [01-02]
  provides: [ShareLinkParser dispatcher, VlessParser, VmessParser (dual format), TrojanParser, ShadowsocksParser, Hysteria2Parser, ParserUtils]
  affects: []
tech_stack:
  added: []
  patterns: [static parser classes, scheme-based dispatch, base64 normalization, URI parameter extraction, ParserUtils shared utility]
key_files:
  created:
    - lib/features/server/data/parsers/share_link_parser.dart
    - lib/features/server/data/parsers/vless_parser.dart
    - lib/features/server/data/parsers/vmess_parser.dart
    - lib/features/server/data/parsers/trojan_parser.dart
    - lib/features/server/data/parsers/shadowsocks_parser.dart
    - lib/features/server/data/parsers/hysteria2_parser.dart
    - lib/features/server/data/parsers/parser_utils.dart
    - test/features/server/data/parsers/share_link_parser_test.dart
    - test/features/server/data/parsers/vless_parser_test.dart
    - test/features/server/data/parsers/vmess_parser_test.dart
    - test/features/server/data/parsers/trojan_parser_test.dart
    - test/features/server/data/parsers/shadowsocks_parser_test.dart
    - test/features/server/data/parsers/hysteria2_parser_test.dart
  modified: []
decisions:
  - "VMess format detection uses @ + ? + & heuristic (per Pitfall 7 research) rather than trying base64 first"
  - "Shadowsocks method validation uses whitelist of 9 known ciphers per T-01-03-04 threat mitigation"
  - "ParserUtils extracted to centralize shared parsing logic across all 5 protocol parsers"
metrics:
  duration: 7min
  completed: "2026-04-04T23:57:00Z"
  tasks: 3
  files: 13
---

# Phase 01 Plan 03: Share Link Parsers Summary

TDD-driven implementation of all 5 protocol share link parsers (VLESS, VMess, Trojan, Shadowsocks, Hysteria2) with scheme-based dispatcher, VMess dual-format support (legacy base64-JSON + standard URI), input validation, and 60 unit tests.

## What Was Built

### Task 1: RED — Failing Tests (TDD)
- Created 6 test files with 60 total test cases covering all 5 protocols
- VlessParser: 10 tests — Reality/XTLS-Vision, WebSocket, gRPC, non-ASCII Farsi names, missing fragment, invalid port, port out of range, empty address, name truncation, input length limit
- VmessParser: 10 tests — legacy base64-JSON, missing padding, URL-safe base64, v!=2, empty fields, empty tls→none, standard URI, invalid input, length limit, name truncation
- TrojanParser: 8 tests — TCP/TLS, WebSocket, URL-encoded password, default TLS security, missing fragment, empty password, length limit, name truncation
- ShadowsocksParser: 10 tests — base64 method:password, no padding, SIP002 plugin, unknown method rejection, 9 valid methods, missing fragment, length limit, name truncation, malformed base64, missing password
- Hysteria2Parser: 8 tests — full params, hy2:// alternate scheme, missing obfs, missing fragment, empty auth, length limit, name truncation, non-ASCII Russian name
- ShareLinkParser: 13 tests — all 5 protocol dispatch, hy2:// dispatch, raw JSON VMess, empty string, https:// URL, garbage input, whitespace handling, whitespace-only, length limit, Chinese name

### Task 2: GREEN — Parser Implementation
- **ShareLinkParser** — Scheme-based dispatcher: trims input, detects URI scheme (vless://, vmess://, trojan://, ss://, hysteria2://, hy2://), routes to specific parser. Fallback: raw JSON VMess parsing for CONF-06 support.
- **VlessParser** — Dart `Uri.parse()` extraction: uuid from userInfo, query params mapped to ServerConfig fields (type→network, security, pbk→publicKey, fp→fingerprint, sid→shortId, spx→spiderX, flow, serviceName, etc.)
- **VmessParser** — Dual format per CONF-05: detects legacy vs standard by checking for `@`+`?`+`&` in content after prefix strip. Legacy path: normalizes URL-safe base64 (- → +, _ → /), pads, decodes JSON. Standard path: Uri.parse like VLESS.
- **TrojanParser** — Password from URL-decoded userInfo. Security defaults to `tls` (Trojan convention). Same query param mapping as VLESS.
- **ShadowsocksParser** — Manual parsing: splits on `@`, base64 decodes left side to `method:password`, extracts host:port from right side. Validates method against 9 known ciphers (T-01-03-04). Handles SIP002 plugin query params.
- **Hysteria2Parser** — Normalizes `hy2://` to `hysteria2://` before parsing. Auth from userInfo. Query params: sni, obfs, obfs-password.

### Task 3: REFACTOR — ParserUtils Extraction
- Extracted `ParserUtils` with 6 shared static methods: `nonEmpty`, `nonEmptyOr`, `decodeParam`, `extractName`, `isValidHostPort`, `exceedsMaxLength`
- Centralized `maxInputLength` (10000) constant and name truncation logic
- Removed duplicated private helpers from all 5 parsers
- All 60 tests still passing after refactoring

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|------------|
| T-01-03-01 | All parsers wrapped in try-catch returning null. Address non-empty and port 1-65535 validated via `ParserUtils.isValidHostPort()`. |
| T-01-03-02 | VMess base64: catches FormatException from decode. JSON: catches FormatException from jsonDecode. v field value ignored — always attempts parse. |
| T-01-03-03 | Input length capped at 10000 chars via `ParserUtils.exceedsMaxLength()`. Server name capped at 50 chars via `ParserUtils.extractName()` / `AppConstants.maxServerNameLength`. |
| T-01-03-04 | Shadowsocks method validated against whitelist of 9 known ciphers. Unknown methods return null. |

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- ✅ `flutter test test/features/server/data/parsers/` — 60/60 tests pass
- ✅ `flutter analyze lib/features/server/data/parsers/` — zero issues
- ✅ All 5 protocols covered: VLESS, VMess (dual format), Trojan, Shadowsocks, Hysteria2
- ✅ VMess dual format: legacy base64-JSON AND standard URI
- ✅ Non-ASCII names: Farsi, Russian, Chinese decode correctly
- ✅ Malformed inputs return null, never crash
- ✅ Input length limited to 10000 chars, server names capped at 50 chars

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 (RED) | b902a34 | test(01-03): add failing tests for all 5 protocol share link parsers |
| 2 (GREEN) | 50b6a16 | feat(01-03): implement all 5 protocol share link parsers |
| 3 (REFACTOR) | 37adfe7 | refactor(01-03): extract ParserUtils for shared parsing logic |

## Self-Check: PASSED

All 13 files verified present. All 3 commits verified in git log.
