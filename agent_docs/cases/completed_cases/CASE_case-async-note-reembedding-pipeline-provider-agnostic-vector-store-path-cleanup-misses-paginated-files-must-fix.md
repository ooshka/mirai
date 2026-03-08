---
case_id: CASE_case-async-note-reembedding-pipeline-provider-agnostic-vector-store-path-cleanup-misses-paginated-files-must-fix
created: 2026-03-08
---

# CASE: Fix Vector Store Path Cleanup Across Pagination

## Slice metadata
- Type: hardening
- User Value: keeps semantic retrieval results consistent by ensuring stale chunks for a path are fully removed before upsert.
- Why Now: current cleanup reads only one vector-store files page (`limit=100`) and can miss matching path entries beyond that page.
- Risk if Deferred: stale duplicate chunks can accumulate and cause incorrect semantic matches/order over time.

## Goal
Ensure path-scoped semantic upsert deletes all existing vector-store file attachments for the target path, not just first-page results.

## Why this next
- Value: preserves correctness of path-level replacement semantics as notes corpus grows.
- Dependency/Risk: prevents silent drift and stale data accumulation in the new async ingestion flow.
- Tech debt note: keeps OpenAI integration simple while addressing required pagination correctness now.

## Definition of Done
- [ ] `OpenAiSemanticClient#upsert_path_chunks` enumerates all relevant vector-store file pages when resolving existing entries for a path.
- [ ] Existing path entries are fully deleted before new chunk attachments are created.
- [ ] Unit coverage verifies multi-page list handling and deletion behavior.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/openai_semantic_client_spec.rb`

## Scope
**In**
- Add pagination-aware listing in `OpenAiSemanticClient` for vector-store file enumeration.
- Add/adjust unit specs for multi-page path filtering and deletion sequencing.

**Out**
- Cross-path global cleanup/reconciliation tasks.
- Changes to retrieval query ranking behavior.

## Proposed approach
Implement a paginated vector-store files iterator in `OpenAiSemanticClient` that repeatedly requests subsequent pages until exhaustion, collecting only entries with matching `attributes.path`. Reuse existing request helpers and keep response-shape validation strict. Update upsert tests to model multi-page responses and assert all matching entries are deleted before upload/attach operations.

## Steps (agent-executable)
1. Extend vector-store file list logic to request successive pages until no more results remain.
2. Keep path filtering based on `attributes.path` and preserve strict response-shape validation.
3. Update upsert flow to consume paginated results before uploading new chunks.
4. Add/adjust OpenAI client specs to cover multi-page cleanup.
5. Run targeted OpenAI client specs.

## Risks / Tech debt / Refactor signals
- Risk: pagination loop could fail to terminate on malformed cursor handling. -> Mitigation: guard with strict response checks and deterministic loop-exit conditions.
- Debt: API request count increases for large stores.
- Refactor suggestion (if any): if list/query operations expand, extract a small paginated API helper within OpenAI client to avoid duplicated cursor logic.

## Notes / Open questions
- Assumption: vector-store list endpoint exposes stable pagination metadata/cursor fields available to the current API version.
