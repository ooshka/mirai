---
case_id: CASE_local_workflow_plan_draft_loop_smoke
created: 2026-03-22
---

# CASE: Local Workflow Plan/Draft Loop Smoke

## Slice metadata
- Type: feature
- User Value: gives operators one bounded end-to-end proof that a self-hosted workflow plan can hand off directly into a self-hosted draft patch without custom glue code.
- Why Now: the local planner and local drafter provider seams both just landed, but the existing smoke path still stops before the planner-to-drafter loop that those slices were meant to unlock.
- Risk if Deferred: the repo keeps only spec-level confidence for the new local workflow path, so runtime/config drift could hide until a later staging or operator test.

## Goal
Extend the local smoke path so it proves a planner-produced `workflow.draft_patch` action can be handed directly into the draft endpoint and return a validated dry-run patch for the same note.

## Why this next
- Value: validates the first real self-hosted workflow loop that an operator would use, rather than only isolated planner and drafter seams.
- Dependency/Risk: builds directly on the completed workflow handoff Cases and reduces runtime-wiring risk before any broader workflow execution slice.
- Tech debt note: pays down the current environment-level verification gap while intentionally deferring automatic action execution and richer workflow orchestration.

## Definition of Done
- [ ] `scripts/smoke_local.sh` exercises a bounded workflow section that calls `/mcp/workflow/plan`, extracts a canonical `workflow.draft_patch` action, and submits it to `/mcp/workflow/draft_patch`.
- [ ] The smoke flow asserts the drafted patch is non-empty, targets the selected smoke note, and does not mutate note contents during the draft-only step.
- [ ] Focused request/spec coverage proves one valid plan-to-draft handoff path and keeps failure behavior deterministic when the handoff payload is malformed or unavailable.
- [ ] README and `agent_docs/testing/README.md` explain the workflow smoke prerequisites, including when local workflow provider config is required.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/mcp_workflow_draft_patch_spec.rb`

## Scope
**In**
- Extend the existing local smoke script with one planner-to-drafter handoff section.
- Add or tighten focused request/spec coverage for the canonical handoff path.
- Document the workflow smoke preconditions and operator usage at a high level.

**Out**
- Automatic execution of planner actions.
- Patch apply orchestration driven by planner output.
- New provider abstractions or prompt-tuning beyond what the smoke needs to validate.

## Proposed approach
Reuse the existing smoke script rather than adding a second workflow harness. After the script reads one real note, send a deterministic workflow intent that should yield a canonical `workflow.draft_patch` action for that same note, then post the returned action body directly to `/mcp/workflow/draft_patch`. Keep smoke assertions contract-shaped instead of model-text-specific: action name, required params, matching path, and non-empty unified diff output. Preserve the script’s current cleanup guarantees by keeping the workflow section dry-run only and asserting the note content remains unchanged before the existing patch-apply section begins. Limit spec changes to the planner/drafter request boundary so the Case stays feature-sized.

## Steps (agent-executable)
1. Inspect the current smoke script and workflow request specs to identify the narrowest insertion point for a plan-to-draft handoff.
2. Extend `scripts/smoke_local.sh` with a workflow-plan request that targets the selected smoke note and asserts a canonical `workflow.draft_patch` action in the response.
3. Submit the returned action payload directly to `/mcp/workflow/draft_patch` and assert the response contains a non-empty validated patch for the same note path.
4. Verify in the smoke script that the draft-only step leaves the note content unchanged before the existing patch-propose/apply flow continues.
5. Add or update focused request specs for one successful handoff example and any small malformed/unavailable regression guard needed for the direct handoff contract.
6. Update `README.md` and `agent_docs/testing/README.md` with the workflow smoke prerequisites and recommended usage.

## Risks / Tech debt / Refactor signals
- Risk: smoke assertions could become flaky if they depend on exact model wording. -> Mitigation: assert only canonical action shape, matching path, and non-empty diff output.
- Risk: the smoke script could become too stateful as more workflow checks are added. -> Mitigation: keep the new section bounded and reuse the existing selected note and cleanup flow.
- Debt: pays down missing end-to-end verification for the self-hosted workflow seam, but still leaves full action execution as a later feature.
- Refactor suggestion (if any): if workflow smoke expands beyond one handoff, extract small JSON/request helpers into `scripts/lib/` instead of growing `smoke_local.sh` inline indefinitely.

## Notes / Open questions
- Assumption: the smoke should validate direct handoff using the existing canonical planner action envelope, not invent a separate workflow helper payload.
- Assumption: local provider configuration may be optional for hosted runs, but this Case should document the explicit prerequisites for the self-hosted loop it validates.
