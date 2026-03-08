---
case_id: CASE_retrieval_query_result_snippet_offsets
created: 2026-03-08
---

# CASE: Retrieval Query Result Snippet Offsets

## Slice metadata
- Type: feature
- User Value: provides deterministic match-location hints so clients can highlight grounding context without reparsing full chunk text.
- Why Now: retrieval relevance work is now semantic-capable, but result payloads still require client-side scanning to locate evidence spans.
- Risk if Deferred: downstream tools keep duplicating ad hoc snippet parsing, slowing UX work and increasing contract drift risk.

## Goal
Add bounded, deterministic snippet offset metadata to `/mcp/index/query` chunk results while preserving existing ranking behavior and payload compatibility.

## Why this next
- Value: unlocks faster grounding UX and audit workflows by returning location hints directly in query results.
- Dependency/Risk: builds on now-stable retrieval provider/fallback seams without expanding mutation/index lifecycle scope.
- Tech debt note: introduces a small result-annotation seam now to avoid provider-specific offset logic leaking into retriever/provider classes later.

## Definition of Done
- [ ] `/mcp/index/query` returns additive snippet offset metadata for each returned chunk, with unchanged existing fields (`path`, `chunk_index`, `content`, `score`).
- [ ] Offset values are deterministic for repeated queries and stable across lexical and semantic retrieval modes.
- [ ] Empty/no-match edge cases are handled with a consistent null/empty offset contract (documented and spec-covered).
- [ ] Request/service specs cover endpoint response shape updates and annotation behavior for representative token-match cases.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb spec/services/retrieval/notes_retriever_spec.rb spec/services/retrieval/semantic_retrieval_provider_spec.rb`

## Scope
**In**
- Define one additive chunk metadata field for snippet location hints (for example, start/end offsets) in query responses.
- Implement a retrieval-layer annotation step that computes offsets from chunk content and normalized query text.
- Ensure both lexical and semantic paths share the same annotation contract.
- Add focused request/service specs for shape, determinism, and edge cases.

**Out**
- Full-text highlighting markup generation.
- Multi-snippet extraction/ranking per chunk.
- Query contract changes unrelated to snippet metadata.

## Proposed approach
Add a dedicated retrieval-result annotation seam that runs after ranking selection and before endpoint response serialization. The annotator computes a deterministic first-match span using normalized query tokens against each chunk `content`, then merges an additive metadata field into each chunk hash. Keep provider contracts unchanged so lexical/semantic adapters continue owning ranking only, while annotation owns location metadata uniformly. Cover behavior with endpoint and retriever-level specs to ensure the new field is additive, deterministic, and stable under fallback.

## Steps (agent-executable)
1. Introduce a retrieval snippet annotation service under `app/services/retrieval/` with a narrow `annotate(query_text:, chunks:)` interface.
2. Wire `NotesRetriever#query` (or equivalent retrieval orchestration boundary) to apply annotation after fallback policy ranking.
3. Define and document exact offset field shape in request specs (additive only, no contract-breaking renames/removals).
4. Add service specs for deterministic matching, case normalization behavior, and no-match handling.
5. Update/extend endpoint specs for `/mcp/index/query` lexical path and semantic/fallback path parity.
6. Run targeted retrieval/query specs and adjust only contract-safe internals needed for deterministic output.

## Risks / Tech debt / Refactor signals
- Risk: offset calculations may diverge from ranking tokenization behavior, causing confusing spans. -> Mitigation: share/align token normalization rules and lock with unit specs.
- Risk: semantic results with weak lexical overlap may produce missing offsets. -> Mitigation: define explicit null/empty contract and validate in request specs.
- Debt: initial annotation likely returns only one span per chunk.
- Refactor suggestion (if any): if consumers later require multi-span snippets or excerpts, extract a dedicated snippet policy object rather than expanding retriever orchestration.

## Notes / Open questions
- Assumption: first-match span per chunk is sufficient for current grounding workflows.
- Open question: whether offset units should remain character-based only or include line/column in a follow-on slice.
