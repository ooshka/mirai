---
case_id: CASE_retrieval_query_metadata_echo_contract
created: 2026-03-15
---

# CASE: Retrieval Query Metadata Contract

## Slice metadata
- Type: feature
- User Value: gives query consumers one clear location for grounding fields so they can inspect chunk provenance and snippet hints without guessing between duplicated top-level fields and nested metadata.
- Why Now: the current consumer surface is still minimal, so this is the cheapest point to make `metadata` the single contract for grounding fields before more integrations and explainability work land.
- Risk if Deferred: duplicated field shapes will harden into de facto API guarantees, making later cleanup more disruptive and encouraging ambiguous client usage.

## Goal
Move grounding fields in `/mcp/index/query` chunk results under `metadata` so `path`, `chunk_index`, and `snippet_offset` are no longer exposed at top level.

## Why this next
- Value: unlocks cleaner client/audit integrations by making grounding metadata explicit and singular in the public query payload.
- Dependency/Risk: builds directly on the completed snippet-offset and semantic-provider normalization work without widening into scoring or ranking changes.
- Tech debt note: pays down response-shape drift and removes duplicate public fields before they become sticky compatibility debt.

## Approach Outline

### Utility (Why this helps now)
- Reduces client friction for any caller that needs chunk provenance, because one `metadata` object becomes the only read target for future retrieval UX and audit tooling.
- Creates a safer extension point for follow-on retrieval explainability work, so new additive fields land in one place instead of proliferating top-level chunk keys.

### Rationale (Why this approach)
- Prefer a direct move into `metadata` over a compatibility echo, because the current consumer set is small enough that duplication would create more ambiguity than value.
- Reuse a shared response-annotation/builder seam near retriever orchestration rather than letting each provider emit endpoint-facing metadata independently.
- Assume the first public metadata echo only needs canonical grounding fields (`path`, `chunk_index`, `snippet_offset`), not provider-specific diagnostics or ranking rationale.

### Implementation Shape (How it will be done)
- Identify the narrowest retrieval response assembly boundary that currently returns ranked chunks from `NotesRetriever` into `/mcp/index/query`.
- Introduce a small response-shaping builder under `app/services/retrieval/` that moves canonical grounding fields into `metadata` after snippet annotation is available.
- Keep lexical and semantic providers focused on ranking/normalization; endpoint-facing metadata shape should be assembled once after fallback and annotation are complete.
- Update endpoint and retrieval specs to lock the new contract for lexical results, semantic results, and nil-snippet cases.
- Refresh the README query example and notes to document the breaking contract clearly.

### Risk & Validation Preview
- Risk: hidden consumers may still expect top-level grounding fields. Validation: lock the new response shape in request specs and document the contract change in the README.
- Risk: semantic results with no lexical overlap may produce inconsistent `snippet_offset` metadata behavior. Validation: cover explicit `nil` snippet-offset metadata in semantic-path specs.
- Risk: provider code may start leaking provider-only metadata into the public contract. Validation: keep the first metadata schema deliberately narrow and spec exact keys.

## Definition of Done
- [ ] `/mcp/index/query` returns each chunk with top-level `content` and `score`, plus `metadata` containing `path`, `chunk_index`, and `snippet_offset`.
- [ ] Top-level `path`, `chunk_index`, and `snippet_offset` are removed from the public query chunk contract.
- [ ] Lexical and semantic retrieval paths populate the same public metadata contract, including `metadata.snippet_offset: nil` when semantic results have no lexical overlap.
- [ ] Targeted request/service specs cover the new response shape and representative semantic fallback/no-overlap cases.
- [ ] README endpoint documentation includes an updated example and note describing the contract move into `metadata`.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb spec/services/retrieval/notes_retriever_spec.rb spec/services/retrieval/local_semantic_client_spec.rb`

## Scope
**In**
- Move public grounding fields into one `metadata` object on query chunk results.
- Centralize metadata response shaping in shared retrieval orchestration/annotation code.
- Cover lexical and semantic result parity with focused specs and a small docs update.

**Out**
- Adding ranking rationale, provider diagnostics, or multi-snippet explainability fields.
- Changing retrieval scoring, ordering, fallback policy, or provider request contracts.

## Proposed approach
Keep the existing retrieval flow intact and add one narrow post-ranking response-shaping step. Ranked chunks already converge in `NotesRetriever`, and snippet offsets are already annotated there, so that boundary is the right place to build the final public shape. The new builder should move `path`, `chunk_index`, and `snippet_offset` into `metadata` while leaving `content` and `score` at top level, establishing a single stable container for future retrieval metadata.

## Steps (agent-executable)
1. Inspect the current `/mcp/index/query` response assembly path and identify where ranked chunks are converted into the JSON response after snippet annotation.
2. Add a shared retrieval response-shaping builder under `app/services/retrieval/` that returns chunk hashes shaped as `content`, `score`, and `metadata: {path:, chunk_index:, snippet_offset:}`.
3. Wire the new builder at the retriever/orchestration boundary so lexical and semantic result paths share the same metadata assembly logic.
4. Update request specs for `/mcp/index/query` to assert the new contract on lexical, path-scoped, semantic, and nil-snippet scenarios.
5. Add or extend service-level specs to verify provider-specific metadata does not leak into the public contract.
6. Update the README query example or endpoint notes to document the moved fields, then run the targeted retrieval specs.

## Risks / Tech debt / Refactor signals
- Risk: hidden callers may still be reading top-level grounding fields. -> Mitigation: keep the contract change explicit in docs and constrained to the still-early consumer surface.
- Risk: the metadata builder could become a dumping ground for unrelated explainability features. -> Mitigation: keep this Case limited to canonical grounding fields only and queue richer rationale fields separately.
- Debt: this slice intentionally accepts a small breaking contract now to avoid longer-lived duplication debt.
- Refactor suggestion (if any): if more response-shaping concerns accumulate, extract a dedicated query-result serializer rather than expanding `NotesRetriever` orchestration indefinitely.

## Notes / Open questions
- Assumption: public query metadata should mirror only normalized chunk fields already trusted by the endpoint, not raw provider payloads.
- Open question: whether later explainability work should extend the same `metadata` object or introduce a sibling `explanation` container for ranking rationale.
