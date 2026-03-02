---
case_id: CASE_action_policy_identity_context_explicit_contract
created: 2026-03-02
---

# CASE: ActionPolicy Identity Context Explicit Contract

## Goal
Make identity-context handling in `Mcp::ActionPolicy` explicit so policy behavior is clear and testable without unused state.

## Why this next
- Value: removes ambiguity in a core safety boundary before identity-aware policy rules are added.
- Dependency/Risk: derisks future policy extension by clarifying whether identity is required input vs optional default state.
- Tech debt note: pays down policy-seam clarity debt; avoids carrying dead or misleading state.

## Definition of Done
- [ ] `Mcp::ActionPolicy` no longer carries ambiguous/unused identity-context state, or explicitly consumes it with clear intent.
- [ ] Existing allow/deny behavior for `allow_all` and `read_only` modes is unchanged.
- [ ] `identity_context` handling contract is covered in focused service specs.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_action_policy_spec.rb spec/mcp_policy_identity_context_plumbing_spec.rb`

## Scope
**In**
- Focused refactor in `app/services/mcp/action_policy.rb` to clarify identity-context ownership.
- Minimal spec adjustments in policy/plumbing coverage tied directly to the refactor.

**Out**
- New authorization logic based on identity fields.
- Route/API response contract changes.

## Proposed approach
Treat identity context as an explicit per-call input to `enforce!`, with a small deterministic fallback only where needed for backward compatibility. Remove placeholder usage patterns (for example noop local assignment) and encode intent through method structure and specs. Keep public mode/action constants and denial behavior unchanged so this remains a low-risk internals cleanup with contract-preserving tests.

## Steps (agent-executable)
1. Audit `Mcp::ActionPolicy` identity-context flow and choose one explicit ownership model (call-time input preferred).
2. Refactor policy implementation to remove ambiguous unused state/variables while preserving behavior.
3. Update policy and plumbing specs to assert the chosen identity-context contract.
4. Run targeted specs and confirm no behavior drift.

## Risks / Tech debt / Refactor signals
- Risk: subtle API drift for callers that rely on initializer-provided context. -> Mitigation: preserve backward compatibility or update all known callers with explicit specs.
- Debt: pays down confusing state-retention debt in a core policy class.
- Refactor suggestion (if any): if identity-aware rules expand, introduce dedicated predicate methods per action group to keep policy branching small.

## Notes / Open questions
- Assumption: current enforcement decisions remain mode-based only, independent of identity attributes.
