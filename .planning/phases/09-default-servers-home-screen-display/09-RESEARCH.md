# Phase 09: Default Servers Home Screen Display - Research

**Researched:** 2026-05-24  
**Status:** Ready for planning

## RESEARCH COMPLETE

## Locked Context Alignment

This research aligns with `09-CONTEXT.md` decisions:
- Inline Dashboard section below traffic stats.
- Top-3 preview + Show all in modal/bottom sheet.
- Reuse `ServerCard` visual style.
- Header refresh button with spinner, keep list visible.
- Specific error snackbars and offline cached-label behavior.
- Tap behavior integrated with existing `activeServerProvider`/connection flow.

## Requirements Mapping

| Requirement | Implementation direction |
|---|---|
| API-02 | Reuse `defaultServerKeysProvider` + existing auth-retry path |
| API-03 | Map `ApiClientException` types to specific UX messages |
| UI-01 | New Dashboard default-servers section widget + top-3 preview |
| UI-02 | Header refresh icon with loading spinner + `ref.refresh(...)` |
| REL-01 | Add default-server local cache + offline fallback rendering |

## Existing Reusable Assets

- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — insertion point for new section.
- `lib/features/server/presentation/widgets/server_card.dart` — style/pattern to reuse.
- `lib/features/api/presentation/providers/default_server_keys_provider.dart` — fetch/provider contract.
- `lib/features/server/presentation/providers/active_server_provider.dart` — canonical active-server state path.
- `lib/features/connection/presentation/providers/connection_provider.dart` — handles reconnect flow.
- `lib/features/api/data/datasources/api_client.dart` — typed timeout/network/unauthorized/server errors.

## Key Findings

1. Existing auth/token/401 retry flow from Phase 08 is ready and should be reused directly.
2. Dashboard currently has no default-server section; this must be added as new widget(s).
3. REL-01 is the main gap: no dedicated persisted default-server cache/metadata layer exists yet.
4. Connection switching should route through existing providers only (no parallel state tree).
5. Error UX can be deterministic by mapping `ApiClientException.type` to localized snackbar copy.

## Recommended Phase 09 Structure

- `lib/features/dashboard/presentation/widgets/default_servers_section.dart`
- `lib/features/dashboard/presentation/widgets/default_servers_sheet.dart`
- `lib/features/api/data/models/default_server_cache_model.dart`
- `lib/features/api/data/datasources/default_server_cache_datasource.dart`
- `lib/features/api/presentation/providers/default_server_cache_provider.dart`
- dashboard/provider tests for UI states, refresh, offline fallback, and tap behavior

## Risks and Pitfalls

1. Bypassing `activeServerProvider` causes state divergence.
2. Missing cache layer breaks REL-01 offline requirement.
3. Default server parsing may produce unstable IDs unless normalized for selection/cache use.
4. Non-localized UI strings would violate current l10n patterns.
5. Overly aggressive loading replacement (instead of inline spinner) violates locked UX.

## Validation Guidance for Planner

- Require widget tests for:
  - top-3 render + Show all trigger
  - refresh spinner while list remains visible
  - non-active disabled tap states
  - cached list + “Offline data” label
  - no-cache error empty state
- Require integration tests for:
  - disconnected tap => select only
  - connected tap on new active default server => auto reconnect flow

## Open Items to Track (non-blocking for plan)

- Production `baseUrl`/API key handling remains environment-dependent from Phase 08 setup.
- Exact REL-01 queue/backoff depth should be scoped to foreground behavior for Phase 09, with full scheduler in Phase 10.
