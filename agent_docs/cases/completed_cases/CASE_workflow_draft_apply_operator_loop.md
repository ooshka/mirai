---
case_id: CASE_workflow_draft_apply_operator_loop
created: 2026-03-23
---

# CASE: Workflow Draft Apply Operator Loop

## Slice metadata
- Type: feature
- User Value: lets an operator take a canonical `workflow.draft_patch` action from `/mcp/workflow/plan` and run one explicit apply step without building client-side glue between workflow and patch contracts.
- Why Now: planner-to-drafter handoff, local drafter support, and the local smoke loop are now in place, so the next concrete gap is the missing operator-run step from canonical workflow action payload into a committed note change.
- Risk if Deferred: consumers will either stop at dry-run drafts or invent inconsistent draft-to-apply glue around the current contracts, making later workflow execution cleanup more disruptive.

## Goal
Add one explicit operator-run workflow apply path that accepts the canonical `workflow.draft_patch` action payload, drafts the patch, applies it, and returns a bounded apply result.

## Why this next
- Value: unlocks the first end-to-end workflow where planning output can lead to a committed note update through one server-owned follow-on step.
- Dependency/Risk: builds directly on the existing canonical planner action contract and draft validation path while avoiding a premature generic workflow executor.
- Tech debt note: pays down cross-endpoint glue pressure by making one canonical operator path server-owned, but intentionally defers multi-action workflow execution and broader action orchestration.

## Definition of Done
- [ ] There is one new explicit workflow apply endpoint or action path that accepts the canonical `workflow.draft_patch` payload shape and performs draft-plus-apply on the requested note.
- [ ] The new path reuses the existing draft and patch-apply safety boundaries instead of duplicating patch validation or inventing a second draft contract.
- [ ] The response is bounded and operator-friendly, exposing the committed note path and returning the drafted patch string for auditability.
- [ ] Request/service specs cover one successful canonical planner-action apply flow plus at least one invalid-payload or policy-denied regression case.
- [ ] README endpoint docs and any targeted testing notes reflect the new operator-run apply path and its relationship to draft-only behavior.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_draft_patch_spec.rb spec/mcp_patch_spec.rb` plus any new focused workflow-apply spec file.

## Scope
**In**
- One explicit operator-run workflow apply surface owned by `mirai`.
- Reuse of the canonical `workflow.draft_patch` action payload as the request contract.
- Minimal response shaping, request validation, and documentation updates needed for the new flow.

**Out**
- Generic execution of arbitrary planner actions.
- Background workflow orchestration, retries, or multi-step plans.
- Changes to planner action taxonomy beyond what this apply path must consume.

## Proposed approach
Keep the slice centered on one thin orchestration seam rather than expanding the workflow system. Accept the existing canonical `workflow.draft_patch` action payload, validate it through the current workflow draft parsing boundary, reuse `WorkflowDraftPatchAction` to obtain a validated patch, then hand the patch directly into the existing patch-apply action. Prefer a dedicated workflow apply surface over widening `/mcp/patch/apply` to accept multiple unrelated request shapes, because the workflow intent remains explicit and the existing patch endpoint can stay focused on raw unified diff application. Return a bounded response that includes both the drafted patch and the patch-apply summary so operators can audit what was applied without a second fetch.

## Steps (agent-executable)
1. Inspect the current workflow draft route/helper and patch apply route/action to identify the smallest orchestration boundary that can compose them without duplicating validation.
2. Add one workflow apply route/action that accepts the canonical `workflow.draft_patch` action envelope and maps policy enforcement to a mutation-capable action.
3. Reuse the existing workflow draft and patch apply services so the new path drafts, validates, applies, and commits through the current safety boundaries.
4. Shape the response to include the drafted patch plus the existing patch-apply summary fields needed for operator auditability.
5. Add focused request/service specs for one successful plan-action-to-apply flow and at least one invalid or denied path.
6. Update README endpoint documentation and any small testing guidance needed for the new operator-run workflow apply command surface.

## Risks / Tech debt / Refactor signals
- Risk: widening the feature into a generic workflow executor would create premature action-dispatch complexity. -> Mitigation: support only the canonical `workflow.draft_patch` action envelope in this slice.
- Risk: route-level orchestration could duplicate draft/apply validation logic. -> Mitigation: compose the existing action/service seams and keep new code thin.
- Debt: pays down consumer-side glue pressure between workflow and patch mutation flows.
- Refactor suggestion (if any): if more operator-executed workflow actions appear, extract a small workflow action executor/dispatcher instead of adding bespoke route orchestration for each action.

## Notes / Open questions
- Assumption: the preferred contract is a dedicated workflow-owned apply surface, not overloading `/mcp/patch/apply` with workflow action envelopes.
- Assumption: returning both `patch` and the apply summary is enough auditability for the first operator-run loop; richer workflow execution metadata can remain a later slice.
