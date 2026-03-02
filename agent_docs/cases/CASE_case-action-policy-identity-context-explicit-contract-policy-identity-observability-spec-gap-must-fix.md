---
case_id: CASE_case-action-policy-identity-context-explicit-contract-policy-identity-observability-spec-gap-must-fix
created: 2026-03-02
---

# CASE: Strengthen Policy Identity Contract Observability In Specs

## Goal
Close the test gap where identity-context resolution precedence is asserted indirectly but not as an explicit policy-level contract.

## Why this next
- Value: makes policy identity handling behavior durable and easier to maintain.
- Dependency/Risk: lowers risk of future regressions where identity plumbing appears present but is effectively unused.
- Tech debt note: pays down spec-intent debt in policy seam coverage.

## Definition of Done
- [ ] `spec/mcp_action_policy_spec.rb` includes explicit examples that assert identity resolution contract in policy terms.
- [ ] Spec intent is clear about precedence and fallback behavior without over-reliance on incidental implementation details.
- [ ] Existing request-level plumbing assertions remain green.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_action_policy_spec.rb spec/mcp_policy_identity_context_plumbing_spec.rb`

## Scope
**In**
- Focused spec improvements in `spec/mcp_action_policy_spec.rb` for identity-context contract clarity.
- Minimal production-code changes only if needed to support observable contract assertions.

**Out**
- New policy modes or auth logic.
- Broad test-suite cleanup unrelated to identity-context contract.

## Proposed approach
Add concise spec examples that express identity resolution precedence as policy contract behavior, not only as class-method call expectations. If necessary, expose a minimal internal seam or assertion target that improves observability while keeping production behavior unchanged.

## Steps (agent-executable)
1. Refine/add policy specs to assert identity precedence/fallback as explicit contract outcomes.
2. Keep test doubles narrow and avoid broad global stubs.
3. Run targeted policy/plumbing specs and confirm pass.
4. Ensure readability: each spec name should communicate the contract it protects.

## Risks / Tech debt / Refactor signals
- Risk: over-coupling tests to internals while trying to improve observability. -> Mitigation: anchor assertions on stable contract semantics.
- Debt: reduces ambiguity in how identity-related behavior is protected by tests.
- Refactor suggestion (if any): if identity becomes first-class authorization input, split identity-contract specs from mode-behavior specs.

## Notes / Open questions
- Assumption: lightweight production code remains acceptable if spec contract can be made explicit without new API surface.
