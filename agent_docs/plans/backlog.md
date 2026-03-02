# Backlog

## Next 3 Candidate Slices

1. Symlink Listing Policy Contract Alignment (selected)
- Value: resolves contract ambiguity where `/mcp/notes` can list symlinked markdown paths that `/mcp/notes/read` later rejects by containment checks.
- Active case: `agent_docs/cases/CASE_symlink_listing_policy_contract_alignment.md`
- Scope cue: decide and enforce one deterministic policy (exclude symlink-escaped files from listing, or allow read through a safe policy) with request-spec coverage.
- Size: ~0.5-1 day.

2. Runtime Config Surface Parity + Boolean Parsing Contract
- Value: reduces config drift by centralizing boolean env parsing and exposing effective semantic-provider state in `/config` diagnostics.
- Scope cue: unify truthy parsing ownership (currently duplicated) and add deterministic config visibility for `MCP_SEMANTIC_PROVIDER_ENABLED`.
- Size: ~0.5-1 day.

3. Runtime-Agent Policy Identity Extension Seam
- Value: prepares policy architecture for future identity-aware controls once mode config contracts are stable.
- Size: ~1 day.

## Additional queued slices

1. Retrieval Storage Lifecycle Controls (Phase 2)
- Value: introduces bounded retention/cleanup controls after lifecycle telemetry/status contracts are fully stabilized.
- Size: ~1-2 days.
