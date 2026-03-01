---
case_id: CASE_semantic_retrieval_runtime_integration
created: 2026-03-01
---

# CASE: Semantic Retrieval Runtime Integration

## Goal
Integrate a provider-backed semantic retrieval path behind `GET /mcp/index/query` while preserving the current response contract and lexical fallback behavior.

## Why this next
- Value: improves retrieval relevance quality without requiring API consumers to change usage.
- Dependency/Risk: builds directly on the existing retrieval provider seam and derisks future embedding/vector provider swaps.
- Tech debt note: pays down roadmap debt by moving from lexical-only ranking toward provider-portable retrieval.

## Definition of Done
- [ ] `Mcp::IndexQueryAction`/`NotesRetriever` can use a semantic provider selected through explicit configuration while preserving current query/limit/chunks response shape.
- [ ] When semantic provider is unavailable or disabled, behavior deterministically falls back to lexical retrieval (no endpoint contract drift).
- [ ] Provider selection logic is isolated in service-layer wiring, not route conditionals.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb spec/notes_retriever_spec.rb spec/mcp_error_mapper_spec.rb`

## Scope
**In**
- Add/extend retrieval provider selection wiring in `app/services/notes_retriever.rb` (or a small adjacent selector object).
- Introduce a minimal semantic provider adapter contract and test double coverage for success/fallback paths.
- Keep `/mcp/index/query` request/response schema unchanged.

**Out**
- New endpoint parameters, payload shape changes, or index artifact schema changes.
- Production-grade embedding/vector infrastructure beyond this integration seam.

## Proposed approach
Use an explicit provider selection path driven by configuration (for example `MCP_RETRIEVAL_MODE=lexical|semantic`) and construct a semantic provider adapter behind the existing retriever interface. Keep lexical provider as the default and fallback path if semantic mode cannot serve results. Ensure `IndexQueryAction` continues to validate query and limit exactly as today. Add targeted specs at retriever and request levels for: semantic path used, semantic path unavailable then lexical fallback, and contract parity for response fields.

## Steps (agent-executable)
1. Add a minimal retrieval mode selector for retriever provider construction with lexical default.
2. Implement a semantic provider adapter stub/seam conforming to current provider `rank` expectations.
3. Wire retriever/provider selection without changing route contracts.
4. Add targeted specs for semantic enabled path and deterministic lexical fallback.
5. Run targeted query/retriever/error specs and adjust wiring only until contract parity is green.

## Risks / Tech debt / Refactor signals
- Risk: provider selection branching could leak into route/action layers. → Mitigation: keep all mode selection in retriever/service construction.
- Debt: semantic adapter may initially be coarse (no advanced ranking metadata) to preserve bounded slice size.
- Refactor suggestion (if any): if retrieval modes expand, extract a dedicated retrieval provider factory object instead of growing retriever initialization conditionals.

## Notes / Open questions
- Assumption: lexical fallback is mandatory for local/dev and any environment without semantic provider readiness.
