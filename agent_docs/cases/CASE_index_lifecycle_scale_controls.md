---
case_id: CASE_index_lifecycle_scale_controls
created: 2026-03-01
---

# CASE: Index Lifecycle + Scale Controls

## Goal
Add bounded lifecycle metadata and controls that improve operational predictability of index workflows as note volume grows, without changing query into a write path.

## Why this next
- Value: improves operator/runtime decision-making around rebuild timing and artifact state under higher mutation/query activity.
- Dependency/Risk: de-risks future scale automation by tightening lifecycle contracts before introducing semantic retrieval complexity.
- Tech debt note: pays down lifecycle ambiguity debt while intentionally deferring async jobs and query-triggered writes.

## Definition of Done
- [ ] `/mcp/index/status` includes deterministic lifecycle telemetry needed for scale operations (`stale`, artifact age indicator, and current note-count signal).
- [ ] Lifecycle telemetry remains read-only and does not trigger rebuild/write side effects.
- [ ] `/mcp/index/rebuild` and `/mcp/index/query` response contracts remain backward-compatible.
- [ ] Request/unit specs cover fresh/stale artifacts and status telemetry behavior with deterministic assertions.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_spec.rb spec/index_store_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Extend index status payload with bounded, deterministic lifecycle/scale signals.
- Keep lifecycle controls explicit (status/read and rebuild/invalidate remain separate operations).
- Add focused tests for new status fields and existing contract stability.

**Out**
- Auto rebuild or background indexing.
- Query-triggered artifact writes.
- Semantic/vector retrieval changes.

## Proposed approach
Enhance `IndexStore#status` to return additional deterministic telemetry that helps operational scale decisions while preserving existing fields. Candidate signals: `stale`, `artifact_age_seconds`, and a lightweight current note metric (`notes_present`) gathered from markdown files. Keep all logic in lifecycle services/actions, not routes, and keep query/rebuild contracts unchanged. Update request and unit specs to pin status semantics for present/missing/stale states and ensure existing index/query behavior is stable.

## Steps (agent-executable)
1. Extend `IndexStore#status` with bounded scale-oriented lifecycle telemetry fields.
2. Ensure stale/age calculations remain deterministic across filesystem timestamp precision differences.
3. Keep `Mcp::IndexStatusAction` and route wiring unchanged except for returning the richer status payload.
4. Add/update `spec/index_store_spec.rb` for telemetry contracts in present/missing/stale conditions.
5. Add/update `spec/mcp_index_spec.rb` for endpoint-level status payload assertions.
6. Run targeted index specs, including query endpoint coverage for contract stability.
7. Update docs only if visible API contract text needs refresh.

## Risks / Tech debt / Refactor signals
- Risk: additional status fields could become inconsistent if lifecycle math is duplicated. -> Mitigation: centralize computation inside `IndexStore`.
- Risk: status scan cost may rise with very large note sets. -> Mitigation: keep telemetry bounded to lightweight metadata-only scans.
- Debt: lifecycle remains synchronous and operator-driven.
- Refactor suggestion (if any): if telemetry surface expands further, extract an index lifecycle policy object from `IndexStore`.

## Notes / Open questions
- Assumption: additive status fields are backward-compatible for current MCP consumers.
