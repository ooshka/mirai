---
case_id: CASE_index_freshness_status_signal
created: 2026-03-01
---

# CASE: Index Freshness Status Signal

## Goal
Expose deterministic freshness metadata in index status so clients can tell when the persisted artifact is stale relative to current notes.

## Why this next
- Value: removes ambiguity after mutations by making staleness observable through existing MCP lifecycle tooling.
- Dependency/Risk: de-risks future lifecycle automation by adding a contract signal before introducing rebuild-on-read or async flows.
- Tech debt note: pays down lifecycle observability debt while intentionally keeping rebuild triggers explicit/manual.

## Definition of Done
- [ ] `/mcp/index/status` includes a freshness signal (`stale`) when artifact is present.
- [ ] Freshness is computed against markdown note modification times under `NOTES_ROOT`.
- [ ] Missing-artifact status remains deterministic and backward-compatible (`present: false` semantics preserved).
- [ ] Malformed artifact error behavior remains unchanged (`invalid_index_artifact` mapping).
- [ ] Request/service specs cover fresh, stale, and missing-artifact cases.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_spec.rb spec/index_store_spec.rb`

## Scope
**In**
- Add freshness computation to index status service/action path.
- Extend status payload in a backward-compatible way.
- Add focused specs for status freshness behavior.

**Out**
- Automatic rebuild when stale.
- Query-time artifact writes.
- Async/incremental indexing flows.

## Proposed approach
Extend `IndexStore#status` (or an adjacent lifecycle helper) to compute `latest_note_mtime` across markdown files and compare it to artifact `generated_at`, returning `stale: true/false` when artifact is present. Keep current status fields (`present`, `generated_at`, `notes_indexed`, `chunks_indexed`) unchanged and append freshness metadata only. Preserve existing error contracts and avoid introducing side effects in status reads. Add request specs in `spec/mcp_index_spec.rb` for fresh vs stale outcomes and unit coverage in `spec/index_store_spec.rb` for deterministic comparison rules.

## Steps (agent-executable)
1. Add freshness calculation in index lifecycle service (`IndexStore`-level preferred) based on note mtimes vs artifact generation time.
2. Extend status payload with `stale` (and optional supporting timestamp field if needed for determinism).
3. Keep missing-artifact payload deterministic and preserve existing error mapping.
4. Add/adjust index status request specs for fresh, stale, and missing cases.
5. Add/adjust `IndexStore` specs for freshness comparison logic and edge conditions.
6. Run targeted index specs and ensure current rebuild/query contracts remain stable.

## Risks / Tech debt / Refactor signals
- Risk: filesystem timestamp precision differences could make stale checks flaky. -> Mitigation: use deterministic test timestamps and tolerant comparison strategy.
- Risk: status read could become expensive with large note trees. -> Mitigation: keep scan bounded to markdown files and avoid additional heavy parsing.
- Debt: staleness is signal-only; lifecycle remediation remains manual.
- Refactor suggestion (if any): if lifecycle intelligence grows, extract freshness policy into a dedicated lifecycle coordinator/policy object.

## Notes / Open questions
- Assumption: adding fields to status payload is acceptable as a backward-compatible contract extension.
