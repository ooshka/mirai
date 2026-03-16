---
case_id: CASE_case-case-workflow-plan-draft-handoff-payload-contract-reject-noncanonical-draft-actions-must-fix
created: 2026-03-15
---

# CASE: Reject Noncanonical Draft Actions In Workflow Planner Output

## Slice metadata
- Type: hardening
- User Value: ensures planner responses are safe to consume directly for draft generation without clients having to support stale or ambiguous action names.
- Why Now: the feature branch tightened `/mcp/workflow/draft_patch` to one canonical envelope, so allowing planner output to keep emitting legacy draft-like actions would undercut the handoff contract.
- Risk if Deferred: consumers may still receive `patch.propose` or other noncanonical draft-like actions from `/mcp/workflow/plan`, defeating the “direct handoff” goal and reintroducing translation ambiguity.

## Goal
Make the workflow planner contract reject or normalize noncanonical draft-generation actions so draft handoff output is guaranteed to use `workflow.draft_patch`.

## Why this next
- Value: closes the remaining gap between “documented canonical shape” and “enforced canonical shape” for planner-to-drafter workflows.
- Dependency/Risk: protects the just-landed endpoint contract tightening from being bypassed by permissive planner normalization.
- Tech debt note: pays down residual ambiguity left by generic action validation while keeping the fix narrowly focused on draft-generation actions.

## Definition of Done
- [ ] Planner output cannot return a legacy draft-like action name such as `patch.propose` when the payload is intended for draft generation.
- [ ] Workflow planner validation or normalization enforces one canonical draft action contract: `workflow.draft_patch` with the required params.
- [ ] Request/service specs cover the rejected noncanonical action case and the accepted canonical action case.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/services/llm/workflow_planner_spec.rb`

## Scope
**In**
- Tighten planner-side draft action validation/normalization for canonical handoff enforcement.
- Add focused specs proving noncanonical draft-like actions are rejected.

**Out**
- Broader planner action taxonomy validation for unrelated actions.
- Changes to `/mcp/workflow/draft_patch` request handling beyond what is needed to keep the contract aligned.

## Proposed approach
Keep the change entirely on the planner side. Identify the smallest rule that distinguishes canonical draft generation from generic actions, then enforce that rule in `WorkflowPlanner` normalization or an adjacent helper. Prefer explicit rejection of legacy draft-style actions over silently accepting them, because the repo’s contract posture favors one clear public shape. Update the planner request and service specs to prove that a noncanonical draft-like action does not leak through the endpoint.

## Steps (agent-executable)
1. Inspect the current planner normalization and prompt guidance to identify how a legacy draft-like action such as `patch.propose` could still pass through.
2. Add the smallest planner-side rule that rejects or canonicalizes draft-generation actions unless they use `workflow.draft_patch` with the required params.
3. Update planner-focused specs to cover one rejected noncanonical draft action and the expected error mapping/behavior.
4. Re-run the targeted planner request and service specs.

## Risks / Tech debt / Refactor signals
- Risk: overreaching into full action-schema validation could bloat a small correctness fix. -> Mitigation: scope the rule to draft-generation actions only.
- Debt: pays down the remaining mismatch between documented canonical planner output and actually permitted planner output.
- Refactor suggestion (if any): if more action-specific rules appear, extract a dedicated workflow action contract validator instead of growing inline conditionals.

## Notes / Open questions
- Assumption: `patch.propose` is now considered a stale/incorrect planner action for model-generated draft generation, not a supported alternative contract.
