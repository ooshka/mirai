# Backlog

## Next 3 Candidate Slices

1. Retrieval Fallback Policy Extraction (selected)
- Value: keeps retrieval orchestration small and explicit as semantic provider behaviors expand.
- Active case: `agent_docs/cases/CASE_retrieval_fallback_policy_extraction.md`
- Scope cue: extract semantic-unavailable fallback handling from `NotesRetriever` into a dedicated seam, no endpoint contract changes.
- Size: ~0.5-1 day.

2. Retrieval Storage Lifecycle Controls (Phase 2)
- Value: introduces bounded retention/cleanup controls after lifecycle telemetry/status contracts are fully stabilized.
- Size: ~1-2 days.

3. Index lifecycle telemetry extraction helper
- Value: prevents `IndexStore` lifecycle/status methods from growing into a metrics/policy hotspot.
- Size: ~0.5-1 day.

## Additional queued slices

1. Runtime Config Surface Parity + Boolean Parsing Contract (follow-up only)
- Value: reopen only if semantic config diagnostics/parsing regress after retrieval policy refactors.
- Size: ~0.5 day, conditional.
