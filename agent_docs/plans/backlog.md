# Backlog

## Next 3 Candidate Slices

1. Patch + Index Concurrency Guardrails (selected)
- Value: prevents race-driven stale index windows and non-deterministic outcomes when patch apply and index lifecycle endpoints run concurrently.
- Active case: `agent_docs/cases/CASE_patch_index_concurrency_guardrails.md`
- Scope cue: add bounded file locking/critical section around patch apply + index artifact invalidation/rebuild paths.
- Size: ~1 day.

2. Symlink Listing Policy Contract Alignment
- Value: resolves contract ambiguity where `/mcp/notes` can list symlinked markdown paths that `/mcp/notes/read` later rejects by containment checks.
- Scope cue: decide and enforce one deterministic policy (exclude symlink-escaped files from listing, or allow read through a safe policy) with request-spec coverage.
- Size: ~0.5-1 day.

3. Runtime Config Surface Parity + Boolean Parsing Contract
- Value: reduces config drift by centralizing boolean env parsing and exposing effective semantic-provider state in `/config` diagnostics.
- Scope cue: unify truthy parsing ownership (currently duplicated) and add deterministic config visibility for `MCP_SEMANTIC_PROVIDER_ENABLED`.
- Size: ~0.5-1 day.

## Additional queued slices

1. Runtime-Agent Policy Identity Extension Seam
- Value: prepares policy architecture for future identity-aware controls once mode config contracts are stable.
- Size: ~1 day.

2. Retrieval Storage Lifecycle Controls (Phase 2)
- Value: introduces bounded retention/cleanup controls after lifecycle telemetry/status contracts are fully stabilized.
- Size: ~1-2 days.
