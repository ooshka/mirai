---
case_id: CASE_case-retrieval-scoring-strategy-seam-tokenization-policy-single-owner-must-fix
created: 2026-02-28
---

# CASE: Make Retrieval Tokenization Policy Single-Owner

## Goal
Remove duplicated tokenization logic so retrieval scoring uses one canonical tokenization policy.

## Why this next
- Value: prevents subtle ranking drift when scoring/tokenization evolves.
- Dependency/Risk: de-risks upcoming semantic/hybrid scoring work by keeping lexical behavior centralized.
- Tech debt note: pays down duplication introduced during the scoring seam extraction.

## Definition of Done
- [ ] Tokenization regex/policy is defined in one place for retrieval scoring.
- [ ] `NotesRetriever` no longer duplicates scorer tokenization behavior.
- [ ] Existing ranking/ordering and query endpoint response contract remain unchanged.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/notes_retriever_spec.rb spec/mcp_index_query_spec.rb spec/lexical_chunk_scorer_spec.rb`

## Scope
**In**
- `app/services/notes_retriever.rb`
- `app/services/lexical_chunk_scorer.rb`
- Minimal spec updates needed to lock policy equivalence.

**Out**
- Any semantic/vector retrieval changes.
- API schema changes.

## Proposed approach
Move tokenization ownership fully into the scoring component (or a shared tokenizer helper used by both call sites). Update `NotesRetriever` query flow to use that single policy source for query tokenization before scoring. Preserve deterministic sorting, positive-score filtering, and limit behavior. Add/adjust tests only where needed to ensure behavior parity and avoid endpoint drift.

## Steps (agent-executable)
1. Choose a single canonical tokenization owner and remove duplication.
2. Refactor `NotesRetriever` query token preparation to use that single owner.
3. Keep scoring/filter/sort/limit semantics unchanged.
4. Update specs minimally and run required retrieval/query specs.

## Risks / Tech debt / Refactor signals
- Risk: tokenization drift could reorder tied results -> Mitigation: preserve existing token regex and keep contract specs green.
- Debt: static scorer selection remains for now.
- Refactor suggestion (if any): if additional scorers are introduced soon, formalize a small scorer interface contract doc/spec.

## Notes / Open questions
- Assumption: current tokenization semantics (`/[a-z0-9]+/` on lowercase stringified input) are the contract baseline.
