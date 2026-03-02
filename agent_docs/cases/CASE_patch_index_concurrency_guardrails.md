---
case_id: CASE_patch_index_concurrency_guardrails
created: 2026-03-02
---

# CASE: Patch + Index Concurrency Guardrails

## Goal
Make patch-apply and index lifecycle behavior deterministic under concurrent requests by introducing a bounded critical section for artifact mutation paths.

## Why this next
- Value: prevents race-driven stale index windows and non-deterministic lifecycle results during concurrent patch/apply and index/rebuild traffic.
- Dependency/Risk: derisks production-like usage before expanding policy and retrieval lifecycle features.
- Tech debt note: pays down implicit concurrency assumptions currently spread across separate actions.

## Definition of Done
- [ ] Patch apply and index rebuild/invalidate operations use one shared lock boundary for artifact lifecycle mutations.
- [ ] Existing contracts remain stable (`/mcp/patch/apply`, `/mcp/index/rebuild`, `/mcp/index/invalidate`, `/mcp/index/status`, `/mcp/index/query` response/error shapes unchanged).
- [ ] Concurrency-focused specs demonstrate deterministic outcomes (no stale artifact after successful patch apply invalidation).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- Add a small service for lock acquisition/release scoped to `NOTES_ROOT` (file lock or equivalent process-safe primitive).
- Use the lock in MCP actions that mutate index lifecycle state (`PatchApplyAction`, `IndexRebuildAction`, `IndexInvalidateAction`).
- Add/extend specs to cover concurrent patch/rebuild ordering guarantees and artifact presence expectations.

**Out**
- General-purpose distributed locking.
- Background jobs, async indexing, or request queueing.
- Retrieval scoring/provider behavior changes.

## Proposed approach
Introduce a dedicated lock service (for example `app/services/notes_operation_lock.rb`) that yields a block while holding an exclusive lock anchored under `NOTES_ROOT/.mirai/`. Keep locking responsibility in MCP action layer so low-level services remain reusable and testable. Wrap `PatchApplyAction#call` so patch commit + artifact invalidation occur atomically relative to index rebuild/invalidate operations, and apply the same lock to rebuild/invalidate actions. Add request/service specs that run concurrent operations with controlled timing and assert deterministic artifact state contracts. Keep lock scope narrow to lifecycle mutation paths to avoid broad throughput regressions.

## Steps (agent-executable)
1. Add a `NotesOperationLock` service with a simple `with_exclusive_lock` API and deterministic lock-file location under `NOTES_ROOT/.mirai/`.
2. Inject/use the lock in `Mcp::PatchApplyAction`, `Mcp::IndexRebuildAction`, and `Mcp::IndexInvalidateAction` around mutation work.
3. Add/extend specs to verify deterministic artifact outcomes when patch apply and rebuild/invalidate are invoked concurrently.
4. Run targeted specs for patch/index flows, then run full RSpec.
5. Update docs only if lock behavior changes operational guidance.

## Risks / Tech debt / Refactor signals
- Risk: lock misuse could cause deadlocks or leaked descriptors. -> Mitigation: block-based lock API with `ensure` release and narrow lock scope.
- Debt: adds a synchronization seam that must stay explicit; this is preferable to hidden race coupling in actions.
- Refactor suggestion (if any): if more mutation endpoints are introduced, centralize post-mutation lifecycle hooks with shared lock orchestration instead of duplicating action-level locking.

## Notes / Open questions
- Assumption: serialized lifecycle mutation operations are acceptable at current throughput and preferred over eventual-consistency behavior.
