---
case_id: CASE_index_lifecycle_controls
created: 2026-02-28
---

# CASE: Index Lifecycle Controls

## Goal
Add explicit MCP index lifecycle controls so operators and runtime agents can tell whether a reusable index exists and can invalidate it safely.

## Why this next
- Value: removes stale-artifact ambiguity and makes index state observable without forcing a rebuild/query side effect.
- Dependency/Risk: de-risks upcoming semantic retrieval work by clarifying lifecycle behavior before additional index complexity lands.
- Tech debt note: pays down implicit lifecycle debt; intentionally keeps lifecycle synchronous and manual.

## Definition of Done
- [ ] A new status endpoint returns deterministic index lifecycle metadata (`present`, `generated_at`, `notes_indexed`, `chunks_indexed`) when artifact exists.
- [ ] A new invalidate endpoint removes the persisted index artifact and returns a deterministic result for both present and already-missing artifact states.
- [ ] Existing `/mcp/index/rebuild` and `/mcp/index/query` contracts remain unchanged.
- [ ] Errors for malformed artifacts continue to map through MCP error contracts without leaking internals.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/index_store_spec.rb spec/mcp_index_spec.rb spec/mcp_error_mapper_spec.rb`

## Scope
**In**
- Add minimal index lifecycle operations to `IndexStore` needed for status and invalidation.
- Add MCP action objects + Sinatra routes for index status and invalidation.
- Add/update request and unit specs for happy paths and edge/error cases.

**Out**
- Automatic stale detection or background rebuild triggers.
- Async job orchestration.
- Retrieval scoring/ranking changes.

## Proposed approach
Extend `IndexStore` with bounded lifecycle primitives (for example `status` and `delete`) rather than introducing a larger orchestrator in this slice. Add a read-only MCP action for status and a mutation MCP action for invalidation, each returning small deterministic payloads. Keep payload shape explicit and stable, and keep existing rebuild/query actions untouched. Reuse current `Mcp::ErrorMapper` behavior for invalid artifacts so endpoint-level behavior stays consistent. Add request specs that exercise artifact-present and artifact-missing states and assert deterministic JSON responses.

## Steps (agent-executable)
1. Add `IndexStore` lifecycle helpers to report artifact presence/metadata and delete artifact safely.
2. Add `Mcp::IndexStatusAction` returning a deterministic status payload.
3. Add `Mcp::IndexInvalidateAction` deleting the artifact and returning deterministic mutation summary.
4. Wire new routes in `app.rb` (status read endpoint and invalidate mutation endpoint) with existing MCP error handling.
5. Add request specs covering status/invalidate when artifact exists and when it does not.
6. Add/update unit specs for new `IndexStore` lifecycle helpers, including invalid artifact behavior.
7. Run targeted specs and keep existing rebuild/query contract assertions passing.

## Risks / Tech debt / Refactor signals
- Risk: unclear endpoint naming could create contract churn. -> Mitigation: choose explicit MCP path names aligned with existing `/mcp/index/*` pattern and lock via request specs.
- Risk: invalidation semantics could accidentally remove non-artifact files. -> Mitigation: confine deletion strictly to `IndexStore` artifact path under `NOTES_ROOT/.mirai/index.json`.
- Debt: manual lifecycle controls still require an operator or runtime agent to trigger rebuild.
- Refactor suggestion (if any): if lifecycle operations grow beyond status/invalidate/rebuild, introduce a dedicated index lifecycle coordinator service.

## Notes / Open questions
- Assumption: lifecycle controls should be tool-facing MCP endpoints (`/mcp/index/status` and `/mcp/index/invalidate`) with no auth changes in this phase.
