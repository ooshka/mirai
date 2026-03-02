---
case_id: CASE_case-action-policy-identity-context-explicit-contract-identity-resolution-unused-at-callsite-must-fix
created: 2026-03-02
---

# CASE: ActionPolicy Identity Resolution Must Be Explicitly Used

## Goal
Eliminate ambiguous side-effect-style identity resolution in `Mcp::ActionPolicy#enforce!` by making resolved identity context explicitly consumed in policy flow.

## Why this next
- Value: removes confusing dead-work signal in a policy-critical path.
- Dependency/Risk: reduces risk that future identity-aware authorization is built on unclear method semantics.
- Tech debt note: pays down readability and intent debt in the policy seam.

## Definition of Done
- [ ] `Mcp::ActionPolicy#enforce!` no longer calls identity resolution without explicit consumption of the returned value.
- [ ] Identity resolution intent is clear in method structure and naming.
- [ ] Existing `allow_all` / `read_only` behavior remains unchanged.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_action_policy_spec.rb spec/mcp_policy_identity_context_plumbing_spec.rb`

## Scope
**In**
- `app/services/mcp/action_policy.rb` call-site clarity update around identity resolution.
- Minimal spec updates if required to lock explicit call-site behavior.

**Out**
- New authorization rules based on identity attributes.
- Route/API contract changes.

## Proposed approach
Refactor `enforce!` so identity resolution is either assigned and passed into policy decision code, or removed entirely if not required in current behavior. Prefer explicit data flow over side-effect signaling. Preserve mode-based access semantics and existing public constants.

## Steps (agent-executable)
1. Update `enforce!` call-site to explicitly consume identity resolution output.
2. Adjust helper method names/signatures as needed to reflect real behavior.
3. Run focused policy and plumbing specs to confirm parity.
4. Verify no route/request contract drift.

## Risks / Tech debt / Refactor signals
- Risk: accidental signature drift in `allowed?`/helper methods. -> Mitigation: keep changes local and run targeted specs.
- Debt: removes “computed but ignored” ambiguity in core policy code.
- Refactor suggestion (if any): if identity becomes authorization input, introduce explicit predicate methods that take context.

## Notes / Open questions
- Assumption: current policy decisions remain mode-only after this fix.
