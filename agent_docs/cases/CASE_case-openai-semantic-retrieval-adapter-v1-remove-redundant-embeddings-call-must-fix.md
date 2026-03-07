---
case_id: CASE_case-openai-semantic-retrieval-adapter-v1-remove-redundant-embeddings-call-must-fix
created: 2026-03-07
---

# CASE: Remove Redundant OpenAI Embeddings Call in Semantic Search

## Slice metadata
- Type: hardening
- User Value: improves semantic query latency/reliability and reduces unnecessary API cost.
- Why Now: current semantic search path performs an embeddings request that is not used for vector store search ranking.
- Risk if Deferred: unnecessary network dependency increases fallback frequency and production cost without relevance benefit.

## Goal
Remove the unused embeddings request from semantic query flow while preserving OpenAI vector search behavior, fallback semantics, and response contract.

## Why this next
- Value: faster semantic queries and fewer avoidable failure points.
- Dependency/Risk: closes the last review finding before merge readiness.
- Tech debt note: keeps adapter behavior aligned with single-purpose query-time search flow.

## Definition of Done
- [ ] `OpenAiSemanticClient#search` no longer calls embeddings API when executing vector store search.
- [ ] Request/response parsing for vector store search remains unchanged and contract-safe for `SemanticRetrievalProvider`.
- [ ] Error mapping for vector-store failures still routes to deterministic lexical fallback.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/openai_semantic_client_spec.rb spec/services/retrieval/semantic_retrieval_provider_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- `OpenAiSemanticClient#search` call flow simplification.
- Focused spec updates asserting no embeddings request is issued for semantic search.

**Out**
- Vector store metadata schema changes.
- Broader retry/timeout policy work.
- Endpoint-level payload/schema changes.

## Proposed approach
Refactor `OpenAiSemanticClient#search` to call only vector store search with the query text and limit. Keep response normalization intact so downstream semantic provider behavior is unchanged. Update adapter specs to verify exactly one HTTP call (vector search) per semantic query and preserve existing malformed-response/error-path assertions.

## Steps (agent-executable)
1. Remove embeddings call from `OpenAiSemanticClient#search`.
2. Update client specs to assert no embeddings endpoint request is made and vector search payload remains correct.
3. Re-run semantic/provider/request specs to ensure fallback and contract behavior remains stable.
4. Fix any regressions with minimal, adapter-scoped changes.

## Risks / Tech debt / Refactor signals
- Risk: removing embeddings call could unintentionally remove config validation side effects. -> Mitigation: keep explicit config checks and rely on vector-search call success/failure semantics.
- Debt: adapter still depends on provider metadata (`path`, `chunk_index`) for local-chunk reconciliation.
- Refactor suggestion (if any): if additional providers are added, codify a shared semantic adapter contract test matrix.

## Notes / Open questions
- Assumption: query-time vector search does not require a precomputed embedding payload from this service path.
