---
case_id: CASE_case-case-index-artifact-persistence-contract-stale-artifact-contract-test-must-fix
created: 2026-02-28
---

# CASE: Must Fix Stale Artifact Contract Test

## Goal
Add explicit stale-artifact contract tests so version-mismatched index artifacts deterministically return `invalid_index_artifact`.

## Why this next
- Value: prevents silent contract drift by locking endpoint behavior for stale index schema versions.
- Dependency/Risk: derisks future artifact version bumps and migration work by making failure behavior explicit.
- Tech debt note: pays down test coverage debt in the artifact error-path contract.

## Definition of Done
- [ ] `IndexStore` has a service-level spec that rejects artifacts with non-current `version`.
- [ ] MCP index query request spec verifies stale-version artifacts map to HTTP 500 with `invalid_index_artifact`.
- [ ] Existing malformed-artifact behavior remains unchanged and passing.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/index_store_spec.rb spec/mcp_index_query_spec.rb spec/mcp_error_mapper_spec.rb`

## Scope
**In**
- Add stale-version artifact fixture coverage in `spec/index_store_spec.rb`.
- Add end-to-end stale-version endpoint contract coverage in `spec/mcp_index_query_spec.rb`.
- Ensure error mapping contract remains explicit via existing `invalid_index_artifact` behavior.

**Out**
- Artifact auto-migration logic.
- Changes to artifact schema version value or runtime fallback policy.

## Proposed approach
Create one explicit service spec that writes a syntactically valid artifact JSON with `version` set to a non-current value and asserts `IndexStore::InvalidArtifactError`. Add a request spec that places the same stale-version artifact at `NOTES_ROOT/.mirai/index.json`, calls `GET /mcp/index/query`, and asserts the existing error contract payload (`code: invalid_index_artifact`). Keep existing malformed-JSON test intact so stale and malformed paths are both covered without changing runtime behavior.

## Steps (agent-executable)
1. Add stale-version invalidation example to `spec/index_store_spec.rb`.
2. Add stale-version MCP query contract example to `spec/mcp_index_query_spec.rb`.
3. Run targeted specs for store/query/error mapping surfaces.
4. Confirm no behavior changes outside tests and prepare for re-review.

## Risks / Tech debt / Refactor signals
- Risk: brittle test fixtures could diverge from artifact contract fields → Mitigation: keep fixtures minimal but fully valid except for `version`.
- Debt: stale-version handling currently errors rather than migrates; this remains intentional for now.
- Refactor suggestion (if any): centralize artifact test fixture builder if more schema variants are added.

## Notes / Open questions
- Assumption: stale artifacts should continue to fail fast with `invalid_index_artifact` until explicit migration policy is introduced.
