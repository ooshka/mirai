---
case_id: CASE_retrieval_scoring_strategy_seam
created: 2026-02-28
---

# CASE: Retrieval Scoring Strategy Seam

## Goal
Introduce a small scoring strategy boundary so retrieval ranking remains deterministic now and easier to evolve later.

## Why this next
- Value: reduces coupling in retrieval logic and makes future semantic/hybrid ranking changes lower risk.
- Dependency/Risk: de-risks provider-abstraction work by preventing `NotesRetriever` from becoming a monolithic policy class.
- Tech debt note: pays down separation-of-concerns debt; intentionally defers multi-strategy runtime configuration.

## Definition of Done
- [ ] `NotesRetriever` no longer hardcodes lexical scoring logic inline.
- [ ] A dedicated scoring component encapsulates current lexical token-match behavior with the same deterministic results.
- [ ] Existing query endpoint contract (shape, ordering, limit handling) remains unchanged.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/notes_retriever_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Extract current lexical scoring into a focused scorer object/service.
- Inject scorer dependency into retrieval path with safe defaults.
- Update/extend specs to lock behavior equivalence.

**Out**
- Semantic embeddings or vector-store retrieval changes.
- Query API schema changes.
- Index artifact lifecycle controls.

## Proposed approach
Create a small scorer class (for example `LexicalChunkScorer`) that accepts query tokens + chunk content and returns a numeric score compatible with current ranking. Keep tokenization policy deterministic and aligned with existing behavior to avoid response drift. Update `NotesRetriever` to orchestrate chunk loading, scorer invocation, filtering, and tie-break ordering. Wire defaults so `Mcp::IndexQueryAction` remains unchanged. Add focused unit specs for the scorer plus regression assertions that existing retriever/query endpoint outputs are preserved.

## Steps (agent-executable)
1. Add a scorer service that implements current lexical scoring behavior and tokenization policy.
2. Refactor `NotesRetriever` to depend on the scorer service instead of inline `lexical_score`.
3. Keep current sorting/tie-break order and limit behavior unchanged.
4. Add scorer-focused specs for scoring/tokenization edge cases.
5. Update `spec/notes_retriever_spec.rb` only where needed to assert behavior parity through injected scorer/default scorer paths.
6. Run targeted RSpec commands for retriever + query endpoint contracts.
7. If behavior is unchanged, avoid API/doc changes; if any drift appears, adjust implementation to preserve contract.

## Risks / Tech debt / Refactor signals
- Risk: subtle tokenization drift could reorder results. -> Mitigation: preserve regex/token normalization and assert deterministic fixture outputs.
- Risk: over-abstraction for a single policy. -> Mitigation: keep interface minimal (single scorer contract) and avoid premature strategy registries.
- Debt: strategy selection is still static/default and not yet configurable per request.
- Refactor suggestion (if any): if semantic+lexical hybrid ranking lands soon after, introduce a composed scoring policy object rather than branching in retriever.

## Notes / Open questions
- Assumption: current lexical scoring semantics are the contract baseline and should remain unchanged in this slice.
