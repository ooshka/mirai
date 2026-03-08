---
case_id: CASE_case-retrieval-query-result-snippet-offsets-token-boundary-policy-single-owner-must-fix
created: 2026-03-08
---

# CASE: Make Snippet Token-Boundary Policy Single-Owner

## Slice metadata
- Type: hardening
- User Value: keeps snippet offsets and lexical ranking aligned so grounding hints stay predictable for clients.
- Why Now: the feature branch currently hardcodes token boundaries in the annotator while tokenization behavior is owned by `LexicalChunkScorer`.
- Risk if Deferred: future scorer tokenization updates can silently desynchronize offset annotations from ranking behavior.

## Goal
Ensure snippet matching uses a single shared token/boundary policy source instead of duplicating boundary rules in `QuerySnippetAnnotator`.

## Why this next
- Value: prevents correctness drift between ranking semantics and offset metadata.
- Dependency/Risk: this is a local, low-risk change that protects the newly added snippet-offset contract.
- Tech debt note: pays down policy duplication debt introduced in the initial implementation.

## Definition of Done
- [ ] `QuerySnippetAnnotator` no longer owns a duplicated hardcoded boundary constant separate from scorer tokenization policy.
- [ ] Offset matching behavior remains deterministic and consistent with existing lexical tokenization semantics.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/query_snippet_annotator_spec.rb spec/services/retrieval/notes_retriever_spec.rb`

## Scope
**In**
- Refactor snippet matching implementation to consume shared token/boundary policy behavior.
- Update/add focused specs proving annotation behavior parity after policy ownership change.

**Out**
- Retrieval ranking algorithm changes.
- Endpoint payload schema changes.

## Proposed approach
Extract or reuse a shared token-matching policy seam from lexical scoring utilities so `QuerySnippetAnnotator` relies on the same normalization/boundary definitions as ranking. Keep the public annotation contract unchanged (`snippet_offset` with `{start, end}` or `nil`). Lock behavior via targeted service-level specs.

## Steps (agent-executable)
1. Identify the smallest shared location for token-boundary/matching policy (existing scorer seam preferred).
2. Refactor `QuerySnippetAnnotator` to consume that shared policy and remove duplicated boundary constant logic.
3. Update `query_snippet_annotator` specs to cover behavior unchanged across representative boundary cases.
4. Run targeted retrieval annotation specs and fix regressions without widening scope.

## Risks / Tech debt / Refactor signals
- Risk: changing matcher internals could alter current offsets unexpectedly. -> Mitigation: keep current behavior locked with explicit before/after spec assertions.
- Debt: none new expected if ownership is centralized in one seam.
- Refactor suggestion (if any): if more retrieval surfaces need token-span behavior, introduce a dedicated reusable token matcher object.

## Notes / Open questions
- Assumption: current boundary semantics (alphanumeric token boundaries) remain the intended contract.
