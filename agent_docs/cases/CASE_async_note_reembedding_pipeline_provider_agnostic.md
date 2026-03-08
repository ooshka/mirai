---
case_id: CASE_async_note_reembedding_pipeline_provider_agnostic
created: 2026-03-08
---

# CASE: Async Note Re-Embedding Pipeline (Provider-Agnostic)

## Slice metadata
- Type: feature
- User Value: keeps semantic retrieval results aligned with latest notes without requiring manual full re-embed workflows.
- Why Now: OpenAI semantic retrieval has been validated end to end, so freshness automation is now the shortest path to usable daily workflows.
- Risk if Deferred: semantic mode remains operationally fragile (stale remote index) and delivery slows due to repeated manual ingestion steps.

## Goal
Automatically enqueue and process note-chunk re-embedding/upsert work after note mutations so remote semantic search stays fresh with minimal operator intervention.

## Why this next
- Value: removes manual indexing friction and turns semantic retrieval into a practical default path.
- Dependency/Risk: de-risks upcoming retrieval quality and model-workflow slices by stabilizing data freshness semantics first.
- Tech debt note: introduces a minimal in-process async queue first; multi-worker durability can follow once contracts are proven.

## Definition of Done
- [ ] `POST /mcp/patch/apply` schedules re-embedding work for affected note chunks instead of relying on manual upload scripts.
- [ ] Re-embedding/upsert execution is asynchronous from the request lifecycle and preserves current patch/apply response contract.
- [ ] Failure in semantic ingestion is observable (structured logging and/or status signal) without breaking successful note mutation commits.
- [ ] Runtime config exposes a clear enable/disable flag for async semantic ingestion behavior.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_patch_spec.rb spec/services/retrieval/openai_semantic_client_spec.rb spec/services/retrieval/semantic_retrieval_provider_spec.rb spec/runtime_config_spec.rb`

## Scope
**In**
- Add a small ingestion orchestration seam that can enqueue chunk upsert tasks after successful patch apply.
- Implement OpenAI vector-store upsert path reuse from app-owned chunk/index data with `path` + `chunk_index` metadata.
- Add bounded runtime controls and diagnostics for async ingestion behavior.
- Add focused request/service tests for enqueue triggering and non-blocking failure behavior.

**Out**
- Distributed job system adoption (Redis/Sidekiq/etc).
- Bulk backfill migration of all existing notes.
- Provider-specific ranking/query contract changes.

## Proposed approach
Introduce an internal semantic ingestion service boundary that accepts changed note paths and resolves app-owned chunks via existing index/chunker behavior. Wire `PatchApplyAction` to trigger enqueue calls only after a successful git-backed patch commit, keeping mutation durability semantics intact. Implement a lightweight background worker loop (threaded/in-process) behind a runtime flag so ingestion failures do not fail user patch requests. Add deterministic metadata mapping (`path`, `chunk_index`) and focused observability so operators can detect drift or failed upserts quickly. Keep provider-specific API calls isolated behind retrieval/semantic client seams to preserve planned provider portability.

## Steps (agent-executable)
1. Add a semantic ingestion service interface (`enqueue_for_paths`, `process`) under `app/services/retrieval/` with OpenAI-backed implementation.
2. Extend `PatchApplyAction` orchestration to call ingestion enqueue after successful patch apply + index invalidation.
3. Add runtime config/env plumbing for async ingestion enablement and expose diagnostics in `/config`.
4. Implement minimal in-process queue/worker execution boundary with failure isolation and structured logs.
5. Add/adjust specs for patch apply enqueue behavior, config diagnostics, and ingestion service metadata contract.
6. Run targeted retrieval/patch/runtime specs and update `agent_docs/testing/README.md` only if verification workflow changes.

## Risks / Tech debt / Refactor signals
- Risk: queue/work thread lifecycle may behave inconsistently across app boot/test environments. -> Mitigation: default feature-flag off in non-target envs, add deterministic service injection in specs.
- Risk: duplicate/stale chunk uploads if enqueue semantics are path-only without versioning. -> Mitigation: preserve deterministic chunk identity (`path`, `chunk_index`) and define idempotent upsert behavior in service contract.
- Debt: initial in-process queue is not durable across crashes/restarts.
- Refactor suggestion (if any): if ingestion workload grows or retries become complex, extract queue adapter seam and migrate implementation to a durable job backend.

## Notes / Open questions
- Assumption: OpenAI vector-store file ingestion API limits are acceptable for current single-user/dev throughput.
- Open question: whether to soft-delete stale remote chunks immediately or defer to periodic reconciliation in a follow-on case.
