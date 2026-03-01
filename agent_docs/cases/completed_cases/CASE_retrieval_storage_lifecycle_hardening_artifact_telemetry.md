---
case_id: CASE_retrieval_storage_lifecycle_hardening_artifact_telemetry
created: 2026-03-01
---

# CASE: Retrieval Storage/Lifecycle Hardening - Artifact Telemetry

## Goal
Add deterministic index artifact storage telemetry so operators can make better rebuild/lifecycle decisions as note volume grows, without changing query contracts.

## Why this next
- Value: improves scale observability for retrieval storage with low behavior risk.
- Dependency/Risk: creates a bounded first increment of retrieval storage/lifecycle hardening before deeper storage refactors.
- Tech debt note: pays down operational visibility debt around artifact size growth; intentionally defers storage format migration.

## Definition of Done
- [ ] `GET /mcp/index/status` includes deterministic artifact storage telemetry fields when artifact is present.
- [ ] Missing-artifact status remains stable and returns `nil` for new telemetry fields.
- [ ] `IndexStore` computes telemetry from persisted artifact data/path without adding nondeterministic values.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/index_store_spec.rb spec/mcp_index_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Extend `IndexStore#status` payload with bounded storage telemetry (for example artifact byte size and chunk-content bytes total).
- Propagate telemetry through existing MCP index status endpoint response.
- Add/adjust specs for both present and missing artifact cases.

**Out**
- Vector DB adoption, multi-file artifact layouts, or background compaction jobs.
- Query ranking changes, retrieval provider selection changes, or endpoint shape changes outside status telemetry.

## Proposed approach
Keep this slice additive and contract-safe: add telemetry keys directly to `IndexStore#status`, deriving values from on-disk artifact and payload chunk content lengths. Keep values deterministic integers and ensure missing artifacts return `nil` for these fields to preserve status semantics. Reuse existing status action and route plumbing so only payload shape expands. Update request/service specs first for missing/present cases, then implement status computation to satisfy them.

## Steps (agent-executable)
1. Add status telemetry expectations in `spec/index_store_spec.rb` for present and missing artifact scenarios.
2. Add/adjust endpoint-level assertions in `spec/mcp_index_spec.rb` to include new telemetry fields.
3. Implement telemetry computation in `app/services/index_store.rb` and ensure values are deterministic and non-negative.
4. Run targeted retrieval/index specs and fix regressions while preserving existing error contracts.
5. Update repository README index status contract section with new telemetry fields.

## Risks / Tech debt / Refactor signals
- Risk: telemetry calculations could add avoidable per-request overhead on very large artifacts. -> Mitigation: derive from already-loaded payload where possible and keep computation linear/minimal.
- Debt: telemetry remains summary-level and does not yet add retention/compaction policy controls.
- Refactor suggestion (if any): if more lifecycle metrics are added, extract status metric calculation into a dedicated helper to keep `IndexStore` focused.

## Notes / Open questions
- Assumption: additive status fields are acceptable for current MCP clients because existing consumers ignore unknown keys.
