---
case_id: CASE_runtime_agent_action_policy_layer
created: 2026-03-01
---

# CASE: Runtime-Agent Action Policy Layer

## Goal
Add a centralized policy seam that can deterministically allow or deny runtime-agent MCP actions without changing endpoint contracts for allowed calls.

## Why this next
- Value: introduces explicit, auditable safety control before adding higher-autonomy runtime behaviors.
- Dependency/Risk: derisks upcoming semantic retrieval and future mutation tools by avoiding route-local permission checks.
- Tech debt note: pays down emerging safety debt by making access policy a first-class service boundary.

## Definition of Done
- [ ] A policy service exists that evaluates named MCP actions (`notes.list`, `notes.read`, `patch.propose`, `patch.apply`, `index.rebuild`, `index.status`, `index.invalidate`, `index.query`) and returns allow/deny deterministically.
- [ ] MCP routes/actions use the centralized policy seam (not scattered inline checks), and denied actions return a stable JSON error contract via existing error handling.
- [ ] Default mode is backward-compatible for local development (all actions allowed unless policy mode/config denies them).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_notes_spec.rb spec/mcp_patch_spec.rb spec/mcp_index_spec.rb spec/mcp_index_query_spec.rb spec/mcp_error_mapper_spec.rb`

## Scope
**In**
- Add a small policy object in `app/services/mcp/` with explicit action identifiers and mode/config input.
- Wire policy checks into MCP orchestration points while preserving existing request/response shapes for allowed actions.
- Add/extend specs for denied-action behavior and mapped error code/status.

**Out**
- Authentication/identity systems, user roles, API keys, or multi-tenant permissions.
- New MCP endpoints or mutation semantics changes.

## Proposed approach
Introduce `Mcp::ActionPolicy` plus a dedicated deny error class carrying action + mode context. Keep policy input minimal (for example `MCP_POLICY_MODE=allow_all|read_only`) so behavior is deterministic and easy to exercise in specs. Route orchestration should invoke one helper/policy call per endpoint action name and rely on `Mcp::ErrorMapper` for denied responses (for example `policy_denied`, HTTP 403). Prefer explicit action-name constants over inferred route metadata to keep policy reviewable and avoid hidden coupling.

## Steps (agent-executable)
1. Add `Mcp::ActionPolicy` and `Mcp::ActionPolicy::DeniedError` with explicit action constants and mode handling.
2. Wire policy invocation into MCP route/action orchestration before action execution; keep existing action classes intact unless a thin wrapper is cleaner.
3. Extend `Mcp::ErrorMapper` and request specs to cover denied actions and ensure existing allowed contracts still pass.
4. Run targeted MCP request and mapper specs; adjust only policy wiring and error mapping until deterministic.

## Risks / Tech debt / Refactor signals
- Risk: policy checks duplicated per route could drift over time. → Mitigation: centralize action-name constants and use a single helper for enforcement.
- Debt: initial policy modes may be intentionally coarse (`allow_all`, `read_only`) and require later expansion for finer controls.
- Refactor suggestion (if any): if policy modes expand beyond simple env parsing, extract a tiny policy config object to isolate mode parsing from enforcement.

## Notes / Open questions
- Assumption: `read_only` should allow `notes.list`, `notes.read`, `index.status`, and `index.query`, while denying `patch.*`, `index.rebuild`, and `index.invalidate`.
