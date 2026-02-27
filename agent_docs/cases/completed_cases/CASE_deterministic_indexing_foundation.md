---
case_id: CASE_deterministic_indexing_foundation
created: 2026-02-27
---

# CASE: Deterministic Indexing Foundation

## Goal
Add a deterministic, local-first indexing foundation for markdown notes so retrieval work can start from a stable, testable contract.

## Why this next
- Value: unlocks the roadmap's indexing/retrieval phase without introducing provider coupling yet.
- Dependency/Risk: derisks future retrieval by establishing deterministic chunking and index summary behavior first.
- Tech debt note: pays down missing retrieval-foundation debt; intentionally defers embedding/vector-store integration.

## Definition of Done
- [ ] A new MCP index rebuild endpoint exists and returns stable summary metadata (for example `notes_indexed` and `chunks_indexed`) for `NOTES_ROOT` markdown notes.
- [ ] Indexing/chunking logic is implemented in focused services (not route code) with deterministic behavior covered by specs.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_spec.rb spec/notes_indexer_spec.rb`

## Scope
**In**
- Add deterministic markdown chunking and note traversal services under `app/services/`.
- Add an MCP endpoint to trigger index rebuild and return summary output.
- Add focused request/service specs for deterministic indexing behavior and endpoint contract.

**Out**
- Embeddings, vector database integration, or provider API calls.
- Search/ranking UX beyond index build summary.
- Background jobs or async processing.

## Proposed approach
Implement a small `NotesIndexer` flow that walks safe markdown paths under `NOTES_ROOT`, chunks content with deterministic local rules, and produces a summary result object. Expose this through a dedicated MCP action and route (`POST /mcp/index/rebuild`) while reusing the existing MCP error handling pattern. Keep chunking strategy intentionally simple and explicit (fixed-size or heading-aware, but deterministic) and document the contract in tests. Do not persist to external systems in this slice; return summary metadata only so follow-on retrieval slices can add storage/query layers safely.

## Steps (agent-executable)
1. Define an index rebuild contract (input/output fields and deterministic expectations) in a new request spec for `POST /mcp/index/rebuild`.
2. Add `NotesIndexer` service(s) to enumerate `.md` notes safely and chunk content deterministically.
3. Add an MCP action wrapper for index rebuild that delegates to `NotesIndexer`.
4. Wire a new Sinatra route for index rebuild in `app.rb` using existing MCP error-handling conventions.
5. Add service specs for chunking determinism and summary counting (including empty-notes-root and multi-file cases).
6. Add request specs for successful rebuild and representative error mapping behavior.
7. Run targeted specs, then full suite, and fix regressions.

## Risks / Tech debt / Refactor signals
- Risk: deterministic chunk boundaries may be underspecified and drift over time. -> Mitigation: pin explicit chunking rules in specs with fixture notes.
- Debt: defers persistence/search integration; acceptable for a foundation slice.
- Refactor suggestion (if any): if more indexing operations are added, extract a shared indexing policy object to avoid duplicated chunking rules across services.

## Notes / Open questions
- Assumption: synchronous rebuild is acceptable at current project scale and can be revisited when note volume grows.
