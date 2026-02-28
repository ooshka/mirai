---
case_id: CASE_case-retrieval-scoring-strategy-seam-query-repeat-contract-alignment-must-fix
created: 2026-02-28
---

# CASE: Align Query Repeat Semantics With Runtime Contract

## Goal
Align tests and implementation contract so repeated query token behavior is explicit and non-contradictory.

## Why this next
- Value: removes ambiguity for future scoring changes and avoids misleading unit tests.
- Dependency/Risk: prevents accidental behavior changes during lexical-to-hybrid transition work.
- Tech debt note: resolves test/contract mismatch introduced by scorer extraction.

## Definition of Done
- [ ] Scorer/retriever specs reflect actual runtime query repeat semantics.
- [ ] Contract is explicit: either repeated query tokens are deduped before scoring, or runtime is intentionally changed to weight repeats.
- [ ] Endpoint contract tests continue passing with deterministic ordering and limit behavior.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/notes_retriever_spec.rb spec/mcp_index_query_spec.rb spec/lexical_chunk_scorer_spec.rb`

## Scope
**In**
- `spec/lexical_chunk_scorer_spec.rb`
- `spec/notes_retriever_spec.rb`
- Minimal implementation updates only if needed to make semantics explicit.

**Out**
- New ranking algorithms.
- Query API payload changes.

## Proposed approach
Select one authoritative behavior for repeated query terms and enforce it consistently. Prefer preserving current runtime behavior (query-token dedupe in retriever) unless there is an explicit decision to change ranking semantics. Update specs so unit expectations and integration behavior agree, and add a focused regression check that documents the chosen repeat-token contract.

## Steps (agent-executable)
1. Confirm current runtime semantics for repeated query tokens in retriever path.
2. Update scorer/retriever specs so they no longer imply contradictory behavior.
3. If needed, make minimal code change to make repeat-token contract explicit.
4. Run retrieval/query target specs and confirm no endpoint drift.

## Risks / Tech debt / Refactor signals
- Risk: changing repeat-token semantics can reorder results -> Mitigation: keep integration contract tests and avoid behavioral change unless explicitly intended.
- Debt: scoring semantics are still lexical-first pending future strategy expansion.
- Refactor suggestion (if any): document scoring contract in a short inline class comment once behavior is finalized.

## Notes / Open questions
- Assumption: preserving current runtime behavior (deduped query tokens before scoring) is preferred unless explicitly changed.
