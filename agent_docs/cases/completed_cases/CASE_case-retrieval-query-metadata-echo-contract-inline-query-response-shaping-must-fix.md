---
case_id: CASE_case-retrieval-query-metadata-echo-contract-inline-query-response-shaping-must-fix
created: 2026-03-15
---

# CASE: Inline Query Response Shaping Must Fix

## Slice metadata
- Type: refactor
- User Value: keeps the query contract implementation easier to follow by removing an extra abstraction that no longer carries enough logic to justify its own class.
- Why Now: the recent contract refactor moved grounding fields under `metadata`, and the remaining `QueryMetadataEchoAnnotator` is now a tiny single-call-site serializer with a stale name.
- Risk if Deferred: the current helper name and shape will mislead future changes, making it easier for retrieval response shaping to accumulate behind a weak abstraction boundary.

## Goal
Inline the current query response shaping logic into `NotesRetriever` and remove the now-underpowered `QueryMetadataEchoAnnotator` helper.

## Why this next
- Value: makes the retrieval orchestration flow simpler to read without changing the public query contract.
- Dependency/Risk: follows directly from the just-completed contract move; waiting longer will make the stale helper seem more intentional than it is.
- Tech debt note: pays down premature abstraction and naming drift introduced during the contract refactor.

## Definition of Done
- [ ] `NotesRetriever` builds the final query chunk response shape inline or via a clearly local private method, without delegating to `QueryMetadataEchoAnnotator`.
- [ ] `app/services/retrieval/query_metadata_echo_annotator.rb` is removed, and no production code still references it.
- [ ] Existing `/mcp/index/query` response behavior remains unchanged: top-level `content` and `score`, with `metadata.path`, `metadata.chunk_index`, and `metadata.snippet_offset`.
- [ ] Targeted request/service specs still pass after the cleanup with no contract drift.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb spec/services/retrieval/notes_retriever_spec.rb`

## Scope
**In**
- Inline the final query response shaping step into `NotesRetriever`.
- Remove the obsolete helper file and any constructor wiring/tests that only existed to support that helper abstraction.

**Out**
- Any further changes to the query payload contract.
- Renaming or restructuring other retrieval collaborators that are still carrying meaningful logic.

## Proposed approach
Keep the current retrieval flow order intact: rank, annotate snippet offsets, then shape the public chunk hashes. The cleanup should stay inside `NotesRetriever`, ideally as a small private method that converts normalized ranked chunks into the public response shape. Delete `QueryMetadataEchoAnnotator`, remove its injected dependency from the initializer, and keep the current request/service specs as the contract guardrail so the refactor remains behavior-preserving.

## Steps (agent-executable)
1. Update `NotesRetriever` to replace `metadata_echo_annotator` usage with a local private method that returns the current public chunk shape.
2. Remove `QueryMetadataEchoAnnotator` from production code wiring and delete the helper file.
3. Adjust any specs only as needed to reflect the removal of the helper dependency while preserving the same public query contract assertions.
4. Run the targeted request and retriever specs and stop if any contract behavior changes.

## Risks / Tech debt / Refactor signals
- Risk: inlining could accidentally blur the boundary between snippet annotation and response shaping. -> Mitigation: keep response shaping in one small private method after snippet annotation, not interleaved with ranking logic.
- Debt: this removes a premature abstraction rather than adding new debt.
- Refactor suggestion (if any): if query response shaping grows again later, re-extract it under a clearer serializer/builder name only once it owns enough policy to justify a separate class.

## Notes / Open questions
- Assumption: the current response shaping logic is too small and too local to justify a dedicated collaborator.
