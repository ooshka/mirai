---
case_id: CASE_case-local-workflow-patch-drafter-provider-handoff-drafter-construction-seam-must-fix
created: 2026-03-22
---

# CASE: Workflow Patch Drafter Construction Seam Must Fix

## Slice metadata
- Type: hardening
- User Value: keeps the workflow draft provider seam easier to reason about by making client ownership explicit instead of relying on dual-slot constructor wiring.
- Why Now: the local drafter handoff just introduced a new provider seam, so this is the cheapest point to tighten the abstraction before more workflow-provider paths accumulate around it.
- Risk if Deferred: future edits can misread the `WorkflowPatchDrafter` constructor contract, accidentally pass mismatched clients, or duplicate the same ambiguous route wiring pattern in adjacent workflow code.

## Goal
Make workflow patch drafter construction explicit enough that provider-specific client selection is obvious and does not depend on passing one built client through both provider slots.

## Why this next
- Value: reduces ambiguity in the newest workflow-provider seam before it spreads.
- Dependency/Risk: de-risks later planner/drafter seam cleanup by giving the draft path one clear ownership boundary for client construction.
- Tech debt note: pays down a small but real readability/maintainability smell introduced by the initial local drafter handoff.

## Definition of Done
- [ ] The draft-patch route no longer passes the same built client object through both `openai_client` and `local_client` slots.
- [ ] Drafter/client construction reflects one clear ownership boundary, either through a single-client drafter initializer shape or a factory that returns a fully wired drafter.
- [ ] Focused specs still cover provider selection after the seam cleanup without route-level branching regressions.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_draft_patch_spec.rb spec/services/llm/workflow_patch_drafter_spec.rb`

## Scope
**In**
- Workflow patch drafter construction and factory ownership for provider-specific client wiring.
- Minimal spec updates required to preserve current provider-selection behavior after the seam cleanup.

**Out**
- Any planner-provider seam redesign beyond what is needed to keep the draft seam coherent.
- Broader runtime-config or README changes unless the final seam shape requires a small clarification.

## Proposed approach
Collapse the ambiguity at the construction boundary instead of adding more route logic. Either let a factory return a fully wired `WorkflowPatchDrafter`, or change the drafter initializer so it accepts one selected client behind a smaller interface. Keep provider choice outside the endpoint contract, preserve existing unavailable mapping, and update only the smallest set of request/service specs needed to prove the refactor did not change behavior.

## Steps (agent-executable)
1. Inspect the current draft-patch route, `WorkflowPatchClientFactory`, and `WorkflowPatchDrafter` initializer to choose the smallest explicit ownership boundary.
2. Refactor construction so provider selection does not rely on passing the same built client into both provider-specific initializer slots.
3. Update targeted draft route/service specs to assert the intended construction path without changing request or response behavior.
4. Re-run the focused draft route and service verification commands.

## Risks / Tech debt / Refactor signals
- Risk: over-correcting into a larger workflow factory redesign than this finding requires. -> Mitigation: keep the change bounded to draft client/drafter construction only.
- Debt: current planner and drafter seams still share coarse workflow runtime settings.
- Refactor suggestion (if any): if planner and drafter continue diverging, consider a dedicated workflow runtime object that owns both provider selection and configuration diagnostics.

## Notes / Open questions
- Assumption: preserving the current route contract matters more than preserving the exact current constructor shape.
