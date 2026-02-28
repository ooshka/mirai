---
case_id: CASE_index_artifact_persistence_contract
created: 2026-02-28
---

# CASE: Index Artifact Persistence Contract

## Goal
Persist rebuild output to a deterministic local artifact so query paths can reuse indexed chunks without rescanning notes each request.

## Why this next
- Value: reduces repeated full-note scans and establishes a stable index data contract for future retrieval work.
- Dependency/Risk: unlocks predictable retrieval latency and later incremental indexing without introducing external storage.
- Tech debt note: pays down repeated recomputation debt while intentionally deferring cache invalidation triggers beyond rebuild.

## Definition of Done
- [ ] `POST /mcp/index/rebuild` writes a deterministic JSON artifact under `NOTES_ROOT` with summary metadata + chunk data.
- [ ] `GET /mcp/index/query` reads from persisted artifact when present and falls back to deterministic rebuild behavior when absent.
- [ ] Error contract covers malformed/stale artifact handling with explicit mapping (no raw exceptions).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_spec.rb spec/mcp_index_query_spec.rb spec/notes_indexer_spec.rb spec/notes_retriever_spec.rb`

## Scope
**In**
- Add a small service boundary for local index artifact read/write under `NOTES_ROOT`.
- Wire rebuild action to persist artifact atomically.
- Wire retriever/query flow to consume artifact with deterministic fallback.
- Add request + service specs for artifact happy path and malformed artifact handling.

**Out**
- External vector store or embedding provider integration.
- Incremental indexing triggers or background jobs.
- Full cache invalidation policy beyond explicit rebuild.

## Proposed approach
Add an `IndexStore` service responsible for deterministic artifact pathing, JSON serialization, and guarded parsing. Update `NotesIndexer`/`Mcp::IndexRebuildAction` flow so rebuild writes the artifact atomically (`tmp` file + rename) after successful indexing. Update `NotesRetriever` (or a thin retrieval source seam) to attempt loading chunks from `IndexStore` first, with a fallback to in-memory index generation when artifact is missing. Keep artifact format explicit and versioned (`version`, `generated_at`, `notes_indexed`, `chunks_indexed`, `chunks`) to support forward migration later. Extend `Mcp::ErrorMapper` for malformed artifact payloads so endpoint behavior stays deterministic. Cover behavior with focused request specs and service specs.

## Steps (agent-executable)
1. Add `IndexStore` service with deterministic artifact location, safe write/read, and `InvalidArtifactError`.
2. Update rebuild flow to persist artifact on successful index rebuild and return existing summary contract.
3. Update retrieval/query flow to read chunks from artifact first and fall back to on-demand indexing when artifact is absent.
4. Map artifact parse/shape failures through MCP error mapper with explicit error code/message.
5. Add/adjust specs for rebuild persistence, query artifact usage, missing-artifact fallback, and malformed artifact behavior.
6. Run targeted RSpec commands for index/retrieval surfaces and capture results.

## Risks / Tech debt / Refactor signals
- Risk: corrupted artifact could break query endpoint behavior. -> Mitigation: strict payload validation + explicit `invalid_index_artifact` error mapping.
- Risk: artifact write interruption could leave partial files. -> Mitigation: atomic temp-file write then rename.
- Debt: artifact schema versioning starts simple JSON; migration tooling is deferred.
- Refactor suggestion (if any): if additional index lifecycle actions are added, extract a dedicated `IndexLifecycle` orchestration service to keep action classes thin.

## Notes / Open questions
- Assumption: storing artifact under `NOTES_ROOT/.mirai/index.json` is acceptable for this phase.
- Open question: should query endpoint auto-trigger rebuild when artifact missing, or continue using current on-demand fallback until lifecycle policy is formalized?
