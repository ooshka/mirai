---
case_id: CASE_action_policy_identity_context_storage_clarity
created: 2026-03-02
---

# CASE: ActionPolicy Identity Context Storage Clarity

## Goal
Clarify `ActionPolicy` identity-context handling by removing or explicitly justifying currently unused stored state.

## Why this next
- Value: keeps policy code intent explicit and avoids misleading state retention.
- Dependency/Risk: reduces confusion before identity-aware rules are added.
- Tech debt note: pays down ambiguity debt in the new policy seam.

## Definition of Done
- [ ] `ActionPolicy` no longer stores unused identity-context state, or it is clearly used with tests proving purpose.
- [ ] Public policy API for current callers remains stable.
- [ ] Existing allow/deny behavior across policy modes is unchanged.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_action_policy_spec.rb spec/mcp_policy_identity_context_plumbing_spec.rb`

## Scope
**In**
- Small refactor in `app/services/mcp/action_policy.rb` for identity-context clarity.
- Minimal spec updates tied to the refactor.

**Out**
- New policy decision logic based on identity fields.
- Route/helper behavior changes unrelated to API compatibility.

## Proposed approach
Treat identity context as an explicit input to `enforce!` and avoid retaining unused instance state until policy logic consumes it. Keep current default behavior and call sites unchanged.

## Steps (agent-executable)
1. Refactor `ActionPolicy` identity-context handling to remove ambiguous stored state or make usage explicit.
2. Adjust affected specs to preserve contract expectations.
3. Re-run targeted specs for policy + plumbing paths.
4. Confirm full behavior parity.

## Risks / Tech debt / Refactor signals
- Risk: API drift if initializer/enforce signatures change unexpectedly. -> Mitigation: preserve existing invocation shape for helpers/tests.
- Debt: reduces latent “unused state” drift in policy core.
- Refactor suggestion (if any): when identity rules arrive, add explicit policy predicates per actor/source to keep branching small.

## Notes / Open questions
- Assumption: no current production behavior depends on persisted identity context between calls.
