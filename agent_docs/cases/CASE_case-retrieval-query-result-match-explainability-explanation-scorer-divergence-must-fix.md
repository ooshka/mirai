---
case_id: CASE_case-retrieval-query-result-match-explainability-explanation-scorer-divergence-must-fix
created: 2026-03-16
---

# CASE: Explanation Scorer Divergence Must Fix

## Slice metadata
- Type: hardening
- User Value: keeps retrieval explanation fields trustworthy by ensuring they describe the same lexical matching policy that produced the result ordering.
- Why Now: the new explainability slice introduced a second scorer dependency in `NotesRetriever`, which can drift from the scorer used by an injected lexical provider and produce contradictory `score` vs `explanation` output.
- Risk if Deferred: review and future refactors will normalize around a hidden coupling where results can report a positive score with `matched_term_count: 0`, undermining the purpose of the new explanation contract.

## Goal
Align retrieval explanation generation with the same lexical scoring policy used for ranking so injected/custom lexical scorer behavior cannot produce contradictory public output.

## Why this next
- Value: preserves the credibility of the new `explanation` contract and removes a hidden dependency mismatch in `NotesRetriever`.
- Dependency/Risk: blocks merge because the feature currently introduces a public explanation field that can disagree with scoring semantics under supported injected-provider test seams.
- Tech debt note: pays down a fresh coupling bug rather than adding follow-on scope.

## Definition of Done
- [ ] `NotesRetriever` does not maintain a separate lexical-scoring policy that can drift from the scorer used by lexical ranking.
- [ ] The injected-scorer retriever spec asserts explanation output that matches the same lexical policy used for ranking.
- [ ] Public query response shape remains unchanged apart from making explanation data consistent with ranking semantics.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/notes_retriever_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Fix the explanation/scoring coupling inside retrieval-owned code.
- Tighten the existing injected-scorer spec to prove explanation output stays aligned.

**Out**
- New explanation fields.
- Provider-specific semantic rationale work.
- Broader retrieval refactors unrelated to this mismatch.

## Proposed approach
Remove the new duplicated scorer ownership or explicitly wire explanation building through the same scoring/token-matching policy object the lexical provider path already uses. Keep the public `explanation` shape unchanged. Prefer the smallest change that preserves current production behavior while making injected lexical scorer seams consistent and test-backed.

## Steps (agent-executable)
1. Inspect how `NotesRetriever`, `LexicalRetrievalProvider`, and `QuerySnippetAnnotator` currently obtain lexical token policy.
2. Refactor the explanation path so it reuses the same lexical matcher/scorer policy as lexical ranking instead of relying on an independent default scorer.
3. Update the injected-scorer service spec to assert explanation values that would fail if scorer policies drift again.
4. Re-run the targeted retriever and request specs and stop if explanation output or public query shape regresses.

## Risks / Tech debt / Refactor signals
- Risk: fixing scorer reuse could accidentally change snippet-offset behavior. -> Mitigation: keep snippet-offset expectations locked in existing request/service specs.
- Debt: this closes hidden coupling introduced by the current feature implementation.
- Refactor suggestion (if any): if retrieval explainability grows further, centralize lexical match policy in one collaborator consumed by scorer, snippet annotation, and explanation shaping.

## Notes / Open questions
- Assumption: the lexical provider path remains the owner of lexical match semantics, and explanation should conform to it rather than inventing a parallel policy.
