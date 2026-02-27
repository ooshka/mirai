---
case_id: CASE_retrieval_query_contract
created: 2026-02-27
---

# CASE: Retrieval Query Contract

## Goal
Add a deterministic MCP retrieval endpoint that returns top matching markdown chunks for a text query using local, non-embedding scoring.

## Why this next
- Value: establishes the first retrieval API contract that runtime agents can call immediately.
- Dependency/Risk: builds directly on deterministic chunking/indexing without committing to embedding or vector-store choices yet.
- Tech debt note: pays down missing retrieval-interface debt while intentionally deferring semantic ranking quality.

## Definition of Done
- [ ] A new MCP retrieval endpoint exists and returns deterministic results for identical notes/query input.
- [ ] Query validation and error contracts are test-backed (for example missing/blank query and invalid limit handling).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb spec/notes_retriever_spec.rb`

## Scope
**In**
- Add a retrieval service that reuses current deterministic chunking/index flow and performs local lexical scoring.
- Add an MCP endpoint/action for retrieval query with bounded result count.
- Add focused service + request specs covering deterministic ranking and input validation.

**Out**
- Embedding generation, vector database integration, or provider API calls.
- Advanced ranking (BM25, hybrid reranking, semantic similarity).
- Background indexing jobs or cache invalidation systems.

## Proposed approach
Introduce a `NotesRetriever` service that calls the existing indexing/chunking path and computes deterministic lexical scores (for example token overlap) per chunk. Sort by score descending and stable tie-breakers (`path`, `chunk_index`) so output stays deterministic. Add an MCP action and route for query requests (for example `GET /mcp/index/query?q=...&limit=...`) that returns top-N chunk metadata/content and score. Keep the scoring intentionally simple and explicit so later embedding/vector retrieval can replace internals without breaking endpoint contract.

## Steps (agent-executable)
1. Define retrieval endpoint contract in a new request spec (`query`, optional `limit`, response shape with ranked chunks and score).
2. Add a `NotesRetriever` service under `app/services/` that uses existing `NotesIndexer` output and deterministic lexical scoring.
3. Add explicit query/limit validation with clear invalid-request errors mapped to stable MCP error codes.
4. Add an MCP retrieval action under `app/services/mcp/` delegating to `NotesRetriever`.
5. Wire the new retrieval endpoint in `app.rb` using existing MCP error-handling conventions.
6. Add service specs for deterministic ranking, stable tie-break behavior, and limit handling.
7. Add request specs for success and representative invalid-input errors.
8. Run targeted retrieval specs, then full suite, and fix regressions.

## Risks / Tech debt / Refactor signals
- Risk: naive lexical scoring may produce low-quality matches on paraphrased queries. -> Mitigation: frame this as deterministic baseline retrieval contract and preserve swap-in seam for future embedding backend.
- Debt: accrues ranking-quality debt by not using semantic retrieval yet; acceptable for this bounded contract slice.
- Refactor suggestion (if any): if retrieval options expand, extract a scoring strategy interface to keep `NotesRetriever` simple and testable.

## Notes / Open questions
- Assumption: returning raw chunk content in retrieval response is acceptable for now because chunks are sourced from local markdown notes only.
