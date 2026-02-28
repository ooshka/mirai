# Current Sprint

## Active Case
- `agent_docs/cases/CASE_index_artifact_persistence_contract.md`

## Sprint Goal
Persist deterministic index artifacts for query reuse:
- write local rebuild artifact under `NOTES_ROOT` with stable schema
- consume persisted chunks in query flow with deterministic fallback behavior
- preserve current retrieval API contract while reducing recomputation debt
