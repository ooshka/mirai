---
case_id: CASE_retrieval_query_result_match_explainability
created: 2026-03-16
---

# CASE: Retrieval Query Result Match Explainability

## Slice metadata
- Type: feature
- User Value: gives operators and downstream clients a compact explanation of why each query result matched, improving trust without forcing them to reverse-engineer raw scores.
- Why Now: retrieval grounding metadata is now stable, but query results still expose opaque scores; this is the smallest product-facing slice that improves retrieval trust before deeper semantic-provider work.
- Risk if Deferred: consumers will either ignore ranking details or invent their own inconsistent explanation heuristics, making later contract cleanup harder.

## Goal
Add a small, deterministic explanation object to `/mcp/index/query` chunk results so clients can understand the basic reason a chunk matched without changing retrieval ordering or provider selection behavior.

## Why this next
- Value: improves retrieval trust immediately and makes ranked results easier to inspect in operator workflows.
- Dependency/Risk: builds directly on the recent metadata contract cleanup and stays within the existing `NotesRetriever` response-shaping boundary.
- Tech debt note: pays down opaque-score contract debt while intentionally deferring richer semantic/provider-specific rationale.

## Definition of Done
- [ ] `/mcp/index/query` returns an additive, documented explanation field for each chunk result with a bounded deterministic shape.
- [ ] Lexical retrieval populates explanation data from retrieval-owned logic instead of leaking provider-internal payloads or requiring clients to rescan text.
- [ ] Semantic retrieval preserves the same public explanation shape, using explicit nil/limited values where lexical rationale is unavailable rather than inventing provider-specific semantics.
- [ ] Ranking order, `score`, and existing `metadata` fields remain unchanged across lexical, OpenAI semantic, local semantic, and lexical-fallback paths.
- [ ] Targeted request/service specs lock the new field shape and key nil/compatibility cases.
- [ ] Docs/verification: README query contract example and targeted specs reflect the new explainability field.

## Scope
**In**
- Add one bounded public explanation container to query result chunks.
- Populate deterministic lexical match details from existing retrieval-owned data or lightweight post-ranking computation.
- Preserve the same explanation keys across lexical and semantic result paths, even when some values are nil.
- Update request/service specs and README contract examples for the additive field.

**Out**
- Changing ranking formulas or score semantics.
- Provider-specific diagnostics, embeddings metadata, or verbose trace payloads.
- Multi-snippet highlighting, excerpts, or UI-oriented formatting.
- Broader retrieval policy changes beyond the response contract.

## Proposed approach
Keep the change at the existing response-shaping layer in `NotesRetriever`, where ranked chunks already converge before the public query payload is built. Introduce a small explanation shape that stays separate from grounding metadata, likely alongside `content`, `score`, and `metadata`, so rationale fields do not overload the canonical grounding container. Derive the first pass from deterministic lexical facts already available after ranking and snippet annotation, then normalize semantic hits into the same shape with bounded nil/default values rather than exposing provider-specific reasoning. Lock the contract with focused request specs and retriever specs before touching README examples.

## Steps (agent-executable)
1. Inspect current retrieval result shaping in `NotesRetriever`, query request specs, and any semantic/local provider normalization to define the smallest additive explanation contract that fits existing chunk payloads.
2. Add the explanation field to the retrieval response-shaping path, keeping key names and value types deterministic and consistent across lexical and semantic results.
3. Populate lexical explanation values from retrieval-owned logic (for example matched query terms/counts or similarly bounded rationale) without changing ranking order or score computation.
4. Normalize semantic and fallback results into the same public explanation shape, using explicit nil/limited values when lexical rationale is not available.
5. Update targeted service and request specs to cover lexical results, semantic results with lexical overlap, and semantic results with no lexical overlap.
6. Refresh the README `/mcp/index/query` example and field descriptions to document the additive explanation contract clearly.
7. Record any follow-on semantic-parity or richer explainability ideas in planning artifacts instead of widening this Case.

## Risks / Tech debt / Refactor signals
- Risk: explanation fields could duplicate or blur the role of `metadata.snippet_offset`. -> Mitigation: keep grounding (`metadata`) and rationale (`explanation`) as distinct containers with clearly different purposes.
- Risk: semantic-provider outputs could tempt provider-specific explanation leakage. -> Mitigation: define one provider-agnostic public shape and normalize unavailable semantics to nil/limited values.
- Debt: first-pass explanation remains intentionally shallow and may not fully explain semantic-only relevance.
- Refactor suggestion (if any): if explanation shaping grows beyond a few deterministic fields, extract a focused retrieval explanation builder rather than expanding `NotesRetriever` into a broader serializer.

## Notes / Open questions
- Assumption: a sibling `explanation` object is cleaner than extending `metadata`, because `metadata` is already the canonical grounding container.
- Assumption: the first slice should favor deterministic lexical rationale over richer but provider-specific semantic interpretation.
