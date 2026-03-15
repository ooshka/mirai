---
case_id: CASE_retrieval_query_metadata_echo_contract
created: 2026-03-15
---

# CASE: Retrieval Query Metadata Echo Contract

## Slice metadata
- Type: feature
- User Value: gives query consumers one additive metadata object for grounding fields so they can inspect chunk provenance and snippet hints without relying on provider-specific internals or bespoke field-mapping logic.
- Why Now: `/mcp/index/query` already exposes top-level `path`, `chunk_index`, and `snippet_offset`, while semantic provider code already normalizes richer internal `metadata`; this is the smallest follow-on to make the public contract more uniform before additional retrieval explainability work lands.
- Risk if Deferred: clients will keep binding to a mixed shape of top-level fields plus implicit provider knowledge, making later retrieval metadata additions harder to ship without duplication or contract drift.

## Goal
Add an additive `metadata` object to `/mcp/index/query` chunk results that consistently echoes canonical grounding fields across lexical and semantic retrieval paths while preserving the existing top-level response contract.

## Why this next
- Value: unlocks cleaner client/audit integrations by making grounding metadata explicit and uniform in the public query payload.
- Dependency/Risk: builds directly on the completed snippet-offset and semantic-provider normalization work without widening into scoring or ranking changes.
- Tech debt note: pays down response-shape drift between retrieval internals and the endpoint contract before more retrieval explainability fields are added.

## Approach Outline

### Utility (Why this helps now)
- Reduces client friction for any caller that needs chunk provenance, because one `metadata` object can become the stable read target for future retrieval UX and audit tooling.
- Creates a safer extension point for follow-on retrieval explainability work, so new additive fields land in one place instead of proliferating top-level chunk keys.

### Rationale (Why this approach)
- Prefer an additive `metadata` echo over renaming or moving existing fields, because current callers likely already depend on top-level `path`, `chunk_index`, and `snippet_offset`.
- Reuse a shared response-annotation/builder seam near retriever orchestration rather than letting each provider emit endpoint-facing metadata independently.
- Assume the first public metadata echo only needs canonical grounding fields (`path`, `chunk_index`, `snippet_offset`), not provider-specific diagnostics or ranking rationale.

### Implementation Shape (How it will be done)
- Identify the narrowest retrieval response assembly boundary that currently returns ranked chunks from `NotesRetriever` into `/mcp/index/query`.
- Introduce a small metadata echo builder/annotator under `app/services/retrieval/` that merges a canonical `metadata` hash into each ranked chunk after snippet annotation is available.
- Keep lexical and semantic providers focused on ranking/normalization; endpoint-facing metadata shape should be assembled once after fallback and annotation are complete.
- Update endpoint and retrieval specs to lock the additive contract for lexical results, semantic results, and nil-snippet cases.
- Refresh the README query example only enough to document the new additive field and preserve compatibility expectations.

### Risk & Validation Preview
- Risk: metadata assembly could diverge from existing top-level fields and create contradictory payloads. Validation: request specs should assert equality between echoed metadata values and legacy top-level fields.
- Risk: semantic results with no lexical overlap may produce inconsistent `snippet_offset` echo behavior. Validation: cover explicit `nil` snippet-offset metadata in semantic-path specs.
- Risk: provider code may start leaking provider-only metadata into the public contract. Validation: keep the first metadata schema deliberately narrow and spec exact keys.

## Definition of Done
- [ ] `/mcp/index/query` returns each chunk with additive `metadata` containing `path`, `chunk_index`, and `snippet_offset`.
- [ ] Existing top-level chunk fields (`path`, `chunk_index`, `content`, `score`, `snippet_offset`) remain present and unchanged.
- [ ] Lexical and semantic retrieval paths populate the same public metadata contract, including `snippet_offset: nil` when semantic results have no lexical overlap.
- [ ] Targeted request/service specs cover the metadata echo shape, parity between top-level and metadata fields, and representative semantic fallback/no-overlap cases.
- [ ] README endpoint documentation includes one updated example or note showing the additive `metadata` field without implying a breaking contract change.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb spec/services/retrieval/notes_retriever_spec.rb spec/services/retrieval/local_semantic_client_spec.rb`

## Scope
**In**
- Add one additive public `metadata` object to query chunk results.
- Centralize metadata echo assembly in shared retrieval orchestration/annotation code.
- Cover lexical and semantic result parity with focused specs and a small docs update.

**Out**
- Removing or renaming existing top-level query chunk fields.
- Adding ranking rationale, provider diagnostics, or multi-snippet explainability fields.
- Changing retrieval scoring, ordering, fallback policy, or provider request contracts.

## Proposed approach
Keep the existing retrieval flow intact and add one narrow post-ranking response-shaping step. Ranked chunks already converge in `NotesRetriever`, and snippet offsets are already annotated there, so that boundary is the right place to attach a canonical public `metadata` echo. The new builder should derive `metadata.path`, `metadata.chunk_index`, and `metadata.snippet_offset` from the same normalized chunk fields already returned to callers, preserving top-level compatibility while establishing a stable container for future additive retrieval metadata.

## Steps (agent-executable)
1. Inspect the current `/mcp/index/query` response assembly path and identify where ranked chunks are converted into the JSON response after snippet annotation.
2. Add a shared retrieval metadata echo builder/annotator under `app/services/retrieval/` that merges `metadata: {path:, chunk_index:, snippet_offset:}` into each ranked chunk.
3. Wire the new builder at the retriever/orchestration boundary so lexical and semantic result paths share the same metadata assembly logic.
4. Update request specs for `/mcp/index/query` to assert the additive `metadata` object on lexical, path-scoped, semantic, and nil-snippet scenarios.
5. Add or extend service-level specs to verify metadata echo parity with the existing top-level fields and to prevent provider-specific metadata leakage.
6. Update the README query example or endpoint notes to document the additive contract, then run the targeted retrieval specs.

## Risks / Tech debt / Refactor signals
- Risk: payload duplication may become noisy if future retrieval fields are added ad hoc both top-level and under `metadata`. -> Mitigation: document `metadata` as the forward-compatible extension surface while preserving current top-level compatibility for now.
- Risk: the metadata builder could become a dumping ground for unrelated explainability features. -> Mitigation: keep this Case limited to canonical grounding fields only and queue richer rationale fields separately.
- Debt: this slice intentionally leaves legacy top-level duplication in place to avoid a breaking change.
- Refactor suggestion (if any): if more response-shaping concerns accumulate, extract a dedicated query-result serializer rather than expanding `NotesRetriever` orchestration indefinitely.

## Notes / Open questions
- Assumption: public query metadata should mirror only normalized chunk fields already trusted by the endpoint, not raw provider payloads.
- Open question: whether later explainability work should extend the same `metadata` object or introduce a sibling `explanation` container for ranking rationale.
