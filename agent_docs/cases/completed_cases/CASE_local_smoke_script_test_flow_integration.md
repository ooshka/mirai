---
case_id: CASE_local_smoke_script_test_flow_integration
created: 2026-03-01
---

# CASE: Local Smoke Script + Test-Flow Integration

## Goal
Add a deterministic local smoke workflow that validates core MCP contracts end-to-end and is integrated into project testing guidance.

## Why this next
- Value: provides a fast environment-level confidence check across read/patch/index/query flows before EC2 staging.
- Dependency/Risk: reduces regression risk from config/runtime drift that unit/request specs alone may miss.
- Tech debt note: pays down operational test-gap debt while keeping scope local and script-driven.

## Definition of Done
- [ ] A runnable smoke script exists under `scripts/` and validates core MCP flows against a local running app.
- [ ] Smoke script behavior is deterministic and exits non-zero on failures with actionable output.
- [ ] `agent_docs/testing/README.md` includes when/how to run the smoke script in the test workflow.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/health_spec.rb spec/mcp_notes_spec.rb spec/mcp_patch_spec.rb spec/mcp_index_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Add a single local smoke script (no cloud dependencies).
- Cover minimal end-to-end operations: health/config, notes list/read, patch propose/apply, index rebuild/status/query, cleanup.
- Document smoke usage and expected preconditions in testing docs.

**Out**
- EC2 provisioning, remote orchestration, or CI integration.
- Performance benchmarking and load testing.
- Semantic retrieval/provider behavior changes.

## Proposed approach
Create `scripts/smoke_local.sh` using strict shell options (`set -euo pipefail`) and small helper functions for request/assert patterns. Use temporary note files under `NOTES_ROOT` to avoid repo pollution and include explicit cleanup traps. Exercise existing HTTP contracts via `curl` and simple JSON checks, failing fast with clear error messages. Keep script assumptions explicit (app running at configurable base URL). Update `agent_docs/testing/README.md` with one small section describing prerequisites, command, and when to run smoke versus RSpec-only checks.

## Steps (agent-executable)
1. Add `scripts/smoke_local.sh` with strict shell mode, configurable `BASE_URL`, and deterministic temp-note naming.
2. Implement smoke checks for health/config and notes list/read endpoints.
3. Implement smoke checks for patch propose/apply and verify index invalidation/rebuild lifecycle.
4. Implement smoke checks for index status/query response shape and limit behavior.
5. Add robust cleanup and clear non-zero failure exits with concise diagnostics.
6. Update `agent_docs/testing/README.md` with smoke-script usage and recommended invocation order.
7. Run targeted endpoint specs to confirm no contract regressions while introducing script/docs.

## Risks / Tech debt / Refactor signals
- Risk: smoke script can become flaky if it depends on wall-clock timing or mutable shared files. -> Mitigation: use deterministic fixture names and scoped temp artifacts with cleanup trap.
- Debt: script assertions may be lightweight string/JSON checks rather than full schema validation.
- Refactor suggestion (if any): if smoke coverage expands further, split reusable bash helpers into `scripts/lib/` to keep the main flow readable.

## Notes / Open questions
- Assumption: local smoke run targets a locally running app (`docker compose up`) and a writable notes mount.
