---
case_id: CASE_case-openai-semantic-retrieval-adapter-v1-openai-conformance-must-fix
created: 2026-03-07
---

# CASE: OpenAI Retrieval API Conformance Must-Fix

## Slice metadata
- Type: hardening
- User Value: ensures semantic retrieval uses documented OpenAI request/response shapes, reducing integration drift and runtime fallback surprises.
- Why Now: current implementation appears to assume non-standard vector search payload/response fields and should be corrected before merge.
- Risk if Deferred: semantic mode may silently degrade to lexical fallback or fail against current OpenAI API behavior in production.

## Goal
Refactor OpenAI adapter request/response mappings to conform to current OpenAI API documentation while preserving the existing MCP query response contract and lexical fallback behavior.

## Why this next
- Value: improves correctness and operational predictability for the OpenAI-backed semantic path.
- Dependency/Risk: unblocks merge confidence for the OpenAI retrieval slice and avoids compounding provider-specific assumptions.
- Tech debt note: keep conformance isolated to the OpenAI adapter boundary so self-hosted provider support remains feasible.

## Definition of Done
- [ ] `OpenAiSemanticClient` uses documented OpenAI request shapes for embeddings and vector store search.
- [ ] OpenAI vector-search response parsing handles documented content/metadata structure and maps safely into internal semantic candidate structure.
- [ ] `SemanticRetrievalProvider` retains local-scope/canonical-content guarantees added in prior must-fix work.
- [ ] Semantic provider failures still map to `UnavailableError` for deterministic lexical fallback.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/semantic_retrieval_provider_spec.rb spec/services/retrieval/retrieval_provider_factory_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- `app/services/retrieval/openai_semantic_client.rb` request/response conformance updates.
- Minimal mapping adjustments in semantic retrieval normalization as needed to consume conformed client output.
- Targeted spec updates/additions for conformed OpenAI payload parsing and fallback safety.

**Out**
- New retrieval providers or multi-provider abstraction refactors.
- Changes to external MCP endpoint payload schema.
- Broader timeout/retry strategy changes beyond what is required for conformance correctness.

## Proposed approach
Update the OpenAI adapter so vector store search follows documented request structure (query-centric search payload, optional max result count) and parse documented response fields (including content blocks/metadata). Normalize adapter output into the existing internal candidate shape expected by `SemanticRetrievalProvider` without leaking OpenAI-specific structures beyond the adapter boundary. Keep existing local chunk membership/content precedence enforcement intact. Extend focused specs for conformance parsing and failure-to-fallback behavior.

## Steps (agent-executable)
1. Update `OpenAiSemanticClient` search request payloads and response parsing to match current OpenAI docs.
2. Add defensive mapping for documented response content structures into internal candidate format.
3. Adjust semantic provider integration only as needed to consume the conformed adapter output.
4. Add/update specs covering conformed mapping success cases and malformed/unavailable fallback cases.
5. Run targeted retrieval/query specs and resolve regressions.

## Risks / Tech debt / Refactor signals
- Risk: strict conformance may expose incomplete metadata assumptions in existing vector store content. -> Mitigation: enforce graceful `RequestError/ResponseError` mapping and verify lexical fallback.
- Debt: provider-specific parsing remains in one adapter class; this is acceptable for current slice but should be abstracted if additional providers are added.
- Refactor suggestion (if any): define a small internal semantic adapter contract test shared by future providers.

## Notes / Open questions
- Assumption: vector-store records include metadata needed to map back to local chunk identity (`path`, `chunk_index`), or equivalent fields that can be translated deterministically.
