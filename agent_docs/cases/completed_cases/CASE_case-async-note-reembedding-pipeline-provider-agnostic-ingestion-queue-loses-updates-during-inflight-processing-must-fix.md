---
case_id: CASE_case-async-note-reembedding-pipeline-provider-agnostic-ingestion-queue-loses-updates-during-inflight-processing-must-fix
created: 2026-03-08
---

# CASE: Fix Ingestion Queue Lost Updates During In-Flight Processing

## Slice metadata
- Type: hardening
- User Value: ensures rapid consecutive note edits are all reflected in semantic index state.
- Why Now: current dedupe behavior can drop a legitimate re-embed trigger while the same path is in-flight.
- Risk if Deferred: semantic retrieval can become stale after bursts of edits even though patch/apply succeeds.

## Goal
Guarantee that path-level semantic ingestion does not lose updates when enqueue requests arrive while the same path is currently being processed.

## Why this next
- Value: restores correctness for realistic edit patterns where a note is patched multiple times quickly.
- Dependency/Risk: protects the new async ingestion feature from silent drift immediately after rollout.
- Tech debt note: may introduce slightly more queue bookkeeping, but keeps the in-process model intact.

## Definition of Done
- [ ] Enqueueing the same path during in-flight processing results in at least one follow-up processing pass.
- [ ] Deduplication still avoids unbounded duplicate queue growth.
- [ ] Spec coverage demonstrates no-event-loss behavior for rapid repeated enqueue calls.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/semantic_ingestion_service_spec.rb spec/mcp_patch_spec.rb`

## Scope
**In**
- Update `AsyncSemanticIngestionService` queue-state semantics to preserve re-enqueue intent for in-flight paths.
- Add targeted specs proving behavior under repeated enqueue while processing.

**Out**
- Durable/distributed queue migration.
- Retry/backoff policy redesign.

## Proposed approach
Separate "currently processing" from "pending rerun" state for each path. When enqueue happens for an in-flight path, mark a pending rerun flag instead of dropping the event. After processing completes, automatically requeue exactly one additional job when rerun is pending, then clear flags deterministically. Keep lock boundaries explicit to avoid races and preserve bounded memory.

## Steps (agent-executable)
1. Refactor `AsyncSemanticIngestionService` path state tracking to represent queued, processing, and pending-rerun intent.
2. Update `enqueue_for_paths` to mark rerun intent for in-flight paths rather than no-op.
3. Update `process` completion flow to requeue one follow-up run when rerun intent is set.
4. Add/adjust specs for enqueue-while-processing behavior and dedupe guarantees.
5. Run targeted specs and confirm no regressions in patch/apply success behavior.

## Risks / Tech debt / Refactor signals
- Risk: incorrect state transitions could create infinite self-requeue loops. -> Mitigation: explicit finite-state transitions with focused unit specs.
- Debt: in-process queue still lacks crash durability.
- Refactor suggestion (if any): extract an internal path-state helper object if queue-state logic grows beyond a small method set.

## Notes / Open questions
- Assumption: at-least-once per path after burst updates is sufficient for this iteration; exact-once is not required.
