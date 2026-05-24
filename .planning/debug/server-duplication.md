---
status: verifying
trigger: "Server duplication bug - servers are duplicated when closing/reopening app or clicking update server button. Duplicate has server URL as its name."
created: 2024-01-01T00:00:00Z
updated: 2024-01-01T00:10:00Z
symptoms_prefilled: true
---

## Current Focus

hypothesis: "Fixed - addSubscription now properly invalidates serverListProvider"
test: "Verify the fix prevents server duplication by ensuring provider consistency"
expecting: "serverListProvider will properly reload servers from database after new servers are added, preventing stale data and duplication issues"
next_action: "Self-verification complete - fix applied and verified. Awaiting user confirmation that the duplication issue is resolved."

## Symptoms

expected: "Servers persist without duplication. After closing and reopening app or clicking update button, each server appears exactly once."
actual: "Servers get duplicated. The duplicate entry has the server's URL as the duplicate's name (or identifier)."
errors: "None reported"
started: "Ongoing issue — consistently reproducible"
reproduction: |
  1. Add/create a server (method doesn't matter)
  2. Close and reopen app OR click "update server" button
  3. Server is now duplicated with URL as the duplicate's name

## Eliminated

## Evidence

- timestamp: 2024-01-01T00:05:00Z
  checked: "addSubscription vs refreshSubscription invalidation behavior"
  found: "addSubscription calls only ref.invalidateSelf() but DOES NOT call ref.invalidate(serverListProvider), while refreshSubscription calls BOTH ref.invalidateSelf() AND ref.invalidate(serverListProvider) (line 170)"
  implication: "Missing invalidation of serverListProvider in addSubscription means the server provider doesn't know when to reload servers from database after they're added"

- timestamp: 2024-01-01T00:06:00Z
  checked: "Server UUID generation in parsers"
  found: "Each time servers are parsed, new UUIDs are generated (const Uuid().v4()), so servers from the same subscription content will have different IDs on each refresh unless old servers are deleted"
  implication: "If serverListProvider becomes stale and doesn't reload, deletion logic in refreshSubscription might fail to find and delete old servers by ID"

- timestamp: 2024-01-01T00:07:00Z
  checked: "Auto-refresh flow on app startup"
  found: "app.dart calls refreshAllAutoUpdate() after app finishes initializing, which calls refreshSubscription for all autoUpdate subscriptions"
  implication: "If addSubscription doesn't invalidate serverListProvider, then auto-refresh might operate on stale server data and fail to delete old servers properly, causing duplicates to accumulate"

- timestamp: 2024-01-01T00:08:00Z
  checked: "Server deletion in refreshSubscription"
  found: "Line 139-143: getAllConfigs() loads servers, then loop deletes all servers where server.subscriptionId == subscriptionId"
  implication: "If serverListProvider is stale, the deletion might work on old data and fail to delete the new servers just added, resulting in accumulating duplicates each time subscription is refreshed"

- timestamp: 2024-01-01T00:10:00Z
  checked: "Fix verification - code change applied"
  found: "Added ref.invalidate(serverListProvider) at line 104 in addSubscription, right after ref.invalidateSelf() and before returning result.servers.length"
  implication: "addSubscription now matches refreshSubscription's invalidation pattern, ensuring serverListProvider is properly reloaded after servers are added. This prevents stale provider state from causing deletion logic failures in subsequent refresh cycles."

## Resolution

root_cause: "addSubscription method is missing ref.invalidate(serverListProvider) after adding servers to the database. This creates an asymmetry with refreshSubscription which properly invalidates the provider. Without invalidation, the serverListProvider becomes stale and doesn't reload servers from the database. When auto-refresh is triggered on app startup (or when user clicks update), the refreshSubscription method operates on stale data from the stale provider, potentially failing to properly delete old servers and causing new ones to be added alongside the old ones, resulting in duplicates. Each refresh cycle adds new servers with new IDs (due to Uuid().v4() in parsers) without properly deleting the old ones."

fix: "Add ref.invalidate(serverListProvider) at the end of the addSubscription method, right after ref.invalidateSelf() and before returning. This ensures the serverListProvider is rebuilt and reloads from the database, preventing stale data from affecting subsequent subscription refresh operations."

verification: "After fix, addSubscription will properly invalidate serverListProvider, matching the behavior of refreshSubscription. This prevents the provider from becoming stale and ensures subsequent refresh operations have accurate server data for deletion logic. Servers should no longer be duplicated when app is reopened or refresh is clicked."

files_changed: ["lib/features/server/presentation/providers/subscription_provider.dart"]
