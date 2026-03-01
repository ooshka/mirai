---
case_id: CASE_case-runtime-agent-action-policy-layer-unknown-policy-mode-fails-open-must-fix
created: 2026-03-01
---

# CASE: Unknown Policy Mode Must Not Fail Open

## Goal
Make MCP action-policy mode handling fail closed (or hard-fail) for unknown modes so misconfiguration cannot silently allow all runtime-agent actions.

## Why this next
- Value: prevents accidental policy bypass caused by typoed or unsupported `MCP_POLICY_MODE` values.
- Dependency/Risk: this is required for trustworthy autonomy constraints before additional runtime-agent capabilities are added.
- Tech debt note: pays down safety debt by making policy configuration deterministic and explicit.

## Definition of Done
- [ ] `Mcp::ActionPolicy` no longer treats unknown mode values as allow-all behavior.
- [ ] Unknown mode behavior is deterministic and test-covered (either deny-all via policy error mapping or explicit startup/config error).
- [ ] Existing `allow_all` and `read_only` behavior remains unchanged.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_action_policy_spec.rb spec/mcp_error_mapper_spec.rb spec/mcp_notes_spec.rb spec/mcp_patch_spec.rb spec/mcp_index_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Update mode normalization/validation logic in `app/services/mcp/action_policy.rb`.
- Add/adjust specs for unsupported mode values.
- Update error mapping/docs only if error shape changes for requests.

**Out**
- New policy modes, auth/identity controls, or endpoint behavior changes unrelated to mode validation.

## Proposed approach
Validate `mode` against explicit constants (`allow_all`, `read_only`). For invalid values, choose one deterministic safe path:
1) raise a dedicated invalid-policy-mode error and map consistently; or
2) normalize to a deny-all enforcement mode.
Prefer explicit error over silent fallback so operator misconfiguration is visible. Keep request behavior and current valid modes unchanged.

## Steps (agent-executable)
1. Add explicit mode validation in `Mcp::ActionPolicy` and remove fail-open fallback for unknown modes.
2. Add policy unit tests for unknown mode behavior.
3. If unknown mode can surface through request handling, map to stable API error contract and add request-level assertion.
4. Run targeted MCP and mapper specs; adjust only policy/mapping wiring.

## Risks / Tech debt / Refactor signals
- Risk: changing unknown-mode behavior may break environments currently relying on typoed values. → Mitigation: return a clear deterministic error message.
- Debt: policy configuration remains env-driven and global; per-request policy context is intentionally deferred.
- Refactor suggestion (if any): if policy modes expand, extract dedicated mode parser/config object to isolate validation from enforcement.

## Notes / Open questions
- Assumption: safety preference is explicit hard-fail for unknown mode values rather than implicit allow-all fallback.
