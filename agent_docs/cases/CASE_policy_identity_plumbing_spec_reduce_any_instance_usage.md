---
case_id: CASE_policy_identity_plumbing_spec_reduce_any_instance_usage
created: 2026-03-02
---

# CASE: Policy Identity Plumbing Spec Without `any_instance`

## Goal
Replace broad `expect_any_instance_of` usage in policy plumbing request specs with narrower, less brittle verification.

## Why this next
- Value: improves test reliability and reduces false positives from global instance interception.
- Dependency/Risk: keeps identity-context seam tests stable as internals evolve.
- Tech debt note: pays down test brittleness introduced during fast seam wiring.

## Definition of Done
- [ ] `spec/mcp_policy_identity_context_plumbing_spec.rb` no longer uses `expect_any_instance_of`.
- [ ] The spec still verifies identity context is threaded through policy enforcement.
- [ ] Existing policy plumbing behavior remains unchanged.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_policy_identity_context_plumbing_spec.rb`

## Scope
**In**
- Refactor only policy plumbing request spec assertions to use narrower seams.
- Add minimal supporting stubs/spies if needed in the same spec file.

**Out**
- Runtime behavior changes in routes, helpers, or policy decisions.
- Unrelated test cleanup.

## Proposed approach
Replace global any-instance expectations by stubbing the helper seam or injecting a policy double where feasible. Keep assertions tied to action + identity-context argument shape and preserve the existing allowed/denied endpoint assertions.

## Steps (agent-executable)
1. Update `spec/mcp_policy_identity_context_plumbing_spec.rb` to remove `expect_any_instance_of`.
2. Use a narrower seam (for example helper method stubbing or local policy double) to assert `enforce!` receives `identity_context`.
3. Keep the allowed and denied request assertions intact.
4. Run the targeted spec and verify pass.

## Risks / Tech debt / Refactor signals
- Risk: over-mocking Sinatra internals can make tests less representative. -> Mitigation: keep endpoint response assertions unchanged and minimal stubbing.
- Debt: reduces high-coupling test pattern debt.
- Refactor suggestion (if any): if policy seam tests grow, extract tiny test helpers for policy call assertions.

## Notes / Open questions
- Assumption: helper-level seam (`mcp_action_policy`) is stable enough for narrow stubbing.
