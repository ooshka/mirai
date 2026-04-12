---
case_id: CASE_policy_identity_plumbing_spec_without_any_instance
created: 2026-04-12
---

# CASE: Policy Identity Plumbing Spec Without any_instance

## Slice metadata
- Type: hardening
- User Value: makes policy-plumbing request specs easier to trust and maintain, so future workflow and endpoint changes can ship with less noisy test breakage.
- Why Now: the recent workflow contract slices have relied on policy-gated request specs, and the remaining `any_instance` usage is a small but active fragility seam in that same area.
- Risk if Deferred: brittle mocking around policy identity can continue to create misleading failures or hide wiring regressions as more request-path work lands.

## Goal
Replace `any_instance`-based policy identity plumbing assertions with clearer, direct request-spec seams that still prove the correct identity context reaches policy enforcement.

## Why this next
- Value: improves confidence in policy-plumbing tests without changing public behavior, which directly supports continued feature work on the workflow and endpoint surfaces.
- Dependency/Risk: this is a hardening override because it fixes a fragile test path that blocks reliable feature delivery on an actively changing seam; feature-forward slicing should resume immediately after this cleanup.
- Tech debt note: pays down mocking fragility and reduces hidden coupling between request specs and object instantiation details.

## Definition of Done
- [ ] Existing request specs that currently rely on `any_instance` for policy identity plumbing are rewritten to use clearer, direct seams.
- [ ] The updated specs still prove that the correct identity context reaches policy enforcement for the covered request paths.
- [ ] No public runtime behavior or policy contract changes are introduced.
- [ ] Focused verification covers the touched policy/request specs and any directly related policy service specs.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_action_policy_spec.rb spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb && bundle exec standardrb spec/mcp_action_policy_spec.rb spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb`

## Scope
**In**
- Replace brittle `any_instance` mocking in the smallest relevant policy-plumbing request specs.
- Minimal supporting test-helper cleanup needed to keep policy identity assertions direct and readable.

**Out**
- Broader policy-mode redesign or runtime identity-behavior changes.
- Unrelated request-spec cleanup outside the `any_instance` policy-plumbing seam.

## Proposed approach
Treat this as a narrow test-hardening slice. Start by identifying the current request specs that reach into policy enforcement with `any_instance`, then replace those expectations with direct seams on the instantiated policy object or another stable request-level boundary already present in the app. Keep the assertions focused on what matters: which action was enforced and which identity context was supplied. Avoid widening this into general spec refactoring, and keep runtime code changes minimal unless a tiny helper adjustment is necessary to make the tests explicit and stable.

## Steps (agent-executable)
1. Inspect the current policy request specs and identify every `any_instance` usage tied to identity-plumbing assertions.
2. Choose the smallest stable seam for each covered path to assert action enforcement and identity context directly.
3. Update the relevant request specs to remove `any_instance` while preserving intent and coverage.
4. Make minimal supporting test-helper or app-hook adjustments only if needed to expose a stable assertion seam.
5. Run the targeted RSpec and `standardrb` commands from Definition of Done.

## Risks / Tech debt / Refactor signals
- Risk: replacing `any_instance` could accidentally weaken the actual identity-plumbing assertion. → Mitigation: keep each rewritten spec explicitly asserting both the enforced action and the identity context passed to policy.
- Risk: touching the wrong seam could make tests more coupled to request setup than before. → Mitigation: prefer the narrowest existing request-level seam instead of introducing new indirection.
- Debt: pays down fragile test wiring that currently depends on object-instantiation internals.
- Refactor suggestion (if any): if multiple request specs still need the same explicit policy assertion shape afterward, extract a small shared spec helper rather than repeating custom setup.

## Notes / Open questions
- Assumption: the `any_instance` usage is localized enough that one small request-spec cleanup slice can remove it without requiring runtime policy refactors.
