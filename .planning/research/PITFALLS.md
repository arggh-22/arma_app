# Pitfalls — v1.5 Dashboard Layout Refresh + Servers Screen Defaults

## Critical pitfalls

1. Selected-server identity drift between default-server cards and persisted active server state.
2. Race conditions when switching servers while already connected.
3. Dashboard 35/65 relayout regressing CTA/announcement visibility behavior.
4. Servers screen accidentally applying imported-server destructive actions to default-server cards.
5. Repeating artifact debt (missing verification artifacts / partial validation) at phase close.

## Prevention strategy

- Keep `activeServerProvider` as single selected-server source of truth.
- Centralize default-server tap/switch logic in one shared action path.
- Lock dashboard invariants with widget tests (CTA branch, announcement visibility, read-more).
- Keep default servers as a distinct section in Servers screen with capability-gated actions.
- Require phase exit gates to include verification + validation artifacts.
