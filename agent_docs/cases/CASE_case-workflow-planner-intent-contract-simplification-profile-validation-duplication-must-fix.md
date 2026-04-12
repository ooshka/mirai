---
case_id: CASE_case-workflow-planner-intent-contract-simplification-profile-validation-duplication-must-fix
created: 2026-04-12
---

# CASE: Workflow Planner Intent Contract Simplification Profile Validation Duplication Must Fix

## Slice metadata
- Type: hardening
- User Value: keeps workflow profile validation consistent across planner normalization and the rest of the workflow stack so later profile-policy changes do not silently diverge.
- Why Now: the planner intent simplification introduced a second local copy of supported profile names and error text inside `Llm::WorkflowPlanner`, even though workflow profile policy already exists in `Llm::WorkflowModelProfile`.
- Risk if Deferred: future profile-policy changes can update one code path and miss the other, causing planner-only behavior or validation errors to drift from draft/apply/execute behavior.

## Goal
Remove the duplicated workflow profile validation logic from planner normalization and reuse the existing workflow profile policy source of truth.

## Why this next
- Value: restores one coherent owner for allowed profile values and their validation semantics.
- Dependency/Risk: directly closes the review finding without changing the planner intent contract introduced on this branch.
- Tech debt note: pays down duplicated policy logic before it hardens into two workflow profile validation paths.

## Definition of Done
- [ ] Planner normalization no longer defines its own supported profile list or separate profile-validation rules.
- [ ] Planner semantic-intent and canonical-action normalization reuse the existing workflow profile validation source of truth or one equally centralized helper.
- [ ] Invalid profile handling remains deterministic for planner output and still maps to planner unavailability at the endpoint boundary.
- [ ] Focused specs cover valid planner profile pass-through and invalid-profile rejection after the validation deduplication.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/llm/workflow_planner_spec.rb spec/mcp_workflow_plan_spec.rb`

## Scope
**In**
- Deduplicate planner-side workflow profile validation.
- Minimal spec adjustments required to lock the shared validation behavior.

**Out**
- Changing supported workflow profile values.
- Broader workflow planner contract redesign beyond the profile-validation seam.
- Any `local_llm` fixture or prompt updates.

## Proposed approach
Replace the planner-local profile allowlist and custom error handling with the existing workflow profile policy object, or a small shared helper extracted from it if needed for the planner normalization context. Keep the planner contract change from this branch intact; the must-fix is only about centralizing validation ownership so planner output does not drift from the rest of the workflow stack. Update the targeted planner specs to assert that valid profile values still pass through and invalid values still fail deterministically through the existing unavailable mapping.

## Steps (agent-executable)
1. Inspect `Llm::WorkflowPlanner` and `Llm::WorkflowModelProfile` to identify the smallest shared validation call that preserves current planner behavior.
2. Remove the planner-local profile constant and duplicate validation logic.
3. Reuse the centralized workflow profile validation path in both canonical and semantic planner draft normalization.
4. Update focused planner specs for valid profile pass-through and invalid profile rejection.
5. Run the targeted planner request/service specs.

## Risks / Tech debt / Refactor signals
- Risk: reusing the shared profile validator could accidentally change planner-specific error mapping. -> Mitigation: keep the planner-level `InvalidPlanError` to `UnavailableError` behavior locked in focused specs.
- Debt: pays down duplicated workflow policy logic that was introduced by the planner simplification slice.
- Refactor suggestion (if any): if more planner-only normalization starts sharing workflow policy rules, extract a small workflow request schema helper rather than duplicating per-service validation.

## Notes / Open questions
- Assumption: keeping one source of truth for supported profile values matters more than preserving the planner’s exact private validation implementation.
