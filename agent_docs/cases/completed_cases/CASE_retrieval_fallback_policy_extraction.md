---
case_id: CASE_retrieval_fallback_policy_extraction
created: 2026-03-02
---

# CASE: Retrieval Fallback Policy Extraction

## Goal
Extract retrieval fallback behavior from `NotesRetriever` into a focused policy seam while preserving current query contracts.

## Why this next
- Value: keeps `NotesRetriever` focused on orchestration instead of mixed provider/fallback error handling.
- Dependency/Risk: lowers risk for upcoming semantic provider growth by creating one place to evolve fallback rules.
- Tech debt note: pays down branching/coupling debt in retrieval orchestration before more provider modes are added.

## Definition of Done
- [ ] Fallback decision logic is moved out of `NotesRetriever#query` into a dedicated, test-covered policy seam.
- [ ] Existing behavior is preserved: semantic `UnavailableError` falls back to lexical provider; successful semantic results do not call fallback.
- [ ] Existing endpoint-level retrieval contract remains unchanged (`GET /mcp/index/query` behavior and payload shape).
- [ ] Tests/verification: `bundle exec rspec spec/notes_retriever_spec.rb spec/retrieval_provider_factory_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Small refactor in retrieval service layer (`app/services/notes_retriever.rb` plus one focused policy/helper object if needed).
- Minimal spec updates/additions to lock fallback behavior ownership.

**Out**
- New retrieval modes or provider types.
- Any ranking algorithm changes or query payload/schema changes.
- Runtime config surface changes beyond what is required for fallback policy wiring.

## Proposed approach
Introduce a narrow fallback policy seam that receives primary/fallback providers and the provider call block, then handles only expected fallback conditions (`SemanticRetrievalProvider::UnavailableError`). Keep provider selection in `RetrievalProviderFactory` and keep chunk sourcing in `NotesRetriever`. Update retriever specs to assert fallback delegation through the seam instead of inline rescue behavior.

## Steps (agent-executable)
1. Add a retrieval fallback policy object (or equivalent private seam) under `app/services/`.
2. Refactor `NotesRetriever#query` to delegate fallback handling to that seam.
3. Keep `RetrievalProviderFactory` contract unchanged unless a minimal wiring tweak is required.
4. Update/add focused specs for fallback behavior ownership and unchanged result contracts.
5. Run targeted retrieval specs and confirm no endpoint contract drift.

## Risks / Tech debt / Refactor signals
- Risk: over-abstraction for a small behavior can reduce readability. -> Mitigation: keep seam tiny, single-purpose, and local to retrieval domain.
- Debt: pays down conditional/error-handling sprawl in retriever orchestration.
- Refactor suggestion (if any): if fallback rules expand (timeouts, partial semantic results), move policy inputs to an explicit strategy interface with deterministic error taxonomy.

## Notes / Open questions
- Assumption: only `SemanticRetrievalProvider::UnavailableError` should trigger lexical fallback; other provider errors should continue to surface.
