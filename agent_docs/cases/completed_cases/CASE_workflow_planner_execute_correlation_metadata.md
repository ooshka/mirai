---
case_id: CASE_workflow_planner_execute_correlation_metadata
created: 2026-04-19
---

# CASE: Workflow Planner Execute Correlation Metadata

## Slice metadata
- Type: feature
- User Value: gives thin workflow clients and operator tooling one stable planner-issued action identifier they can carry through dry-run, apply, and execute responses.
- Why Now: execute-envelope cleanup and action echo are complete, so the remaining client-side friction is pairing a specific planner-returned `workflow.draft_patch` action with later mutation or dry-run output.
- Risk if Deferred: clients will keep inventing endpoint-local correlation logic around action order, instruction text, or surrounding session state instead of relying on one server-owned handoff signal.

## Goal
Add one planner-issued workflow action correlation identifier to canonical draft actions and echo it through dry-run/apply/execute responses when present.

## Why this next
- Value: makes the plan-to-execute handoff easier for CLI, thin clients, and later UI work without changing workflow behavior.
- Dependency/Risk: builds directly on the existing canonical `workflow.draft_patch` action contract and recent apply/execute action echo; it does not require a workflow session store or broader action dispatcher.
- Tech debt note: pays down workflow cross-step correlation debt while intentionally deferring richer trace/session metadata until operator usage proves the need.

## Definition of Done
- [ ] `/mcp/workflow/plan` adds a stable `workflow_action_id` to each returned canonical `workflow.draft_patch` action params.
- [ ] `/mcp/workflow/draft_patch` accepts an optional `workflow_action_id` in canonical action params and includes it in `trace` when present.
- [ ] `/mcp/workflow/apply_patch` and `/mcp/workflow/execute` accept the same optional `workflow_action_id` and include it in nested `audit` when present, while preserving the existing top-level `action` echo.
- [ ] Direct draft/apply/execute calls without `workflow_action_id` remain valid and keep their current response shape aside from omitting the optional correlation field.
- [ ] Focused request/service specs cover planner generation plus draft/apply/execute echo behavior.
- [ ] README workflow docs describe `workflow_action_id` as an optional planner-to-execution correlation signal, not an authorization token or durable session ID.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/mcp_workflow_draft_patch_spec.rb spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb spec/services/mcp/workflow_plan_action_spec.rb spec/services/mcp/workflow_draft_patch_action_spec.rb spec/services/mcp/workflow_draft_apply_action_spec.rb spec/services/mcp/workflow_execute_action_spec.rb && bundle exec standardrb app/routes/mcp_helpers.rb app/services/mcp/workflow_plan_action.rb app/services/mcp/workflow_draft_patch_action.rb app/services/mcp/workflow_draft_apply_action.rb app/services/mcp/workflow_execute_action.rb spec/mcp_workflow_plan_spec.rb spec/mcp_workflow_draft_patch_spec.rb spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb spec/services/mcp/workflow_plan_action_spec.rb spec/services/mcp/workflow_draft_patch_action_spec.rb spec/services/mcp/workflow_draft_apply_action_spec.rb spec/services/mcp/workflow_execute_action_spec.rb`

## Scope
**In**
- Add one optional `workflow_action_id` field to canonical `workflow.draft_patch` params.
- Generate the field for planner-returned draft actions.
- Thread and echo the field through dry-run trace and apply/execute audit responses.
- Update focused workflow request/service specs and README contract examples.

**Out**
- Durable workflow sessions, server-side run storage, retries, or adaptive fallback.
- Correlation IDs for non-`workflow.draft_patch` actions.
- Changing patch validation, git commit behavior, provider prompts, or model selection policy.

## Proposed approach
Treat `workflow_action_id` as lightweight contract metadata on the existing canonical action payload. Generate it when `WorkflowPlanAction` normalizes a planner-returned `workflow.draft_patch` action, likely using a deterministic bounded prefix plus action position or stable payload digest so repeated plan results are easy to reason about in tests. Extend the route payload parser and draft request path to accept but not send this field to model providers. Add it to `WorkflowDraftPatchAction` trace output and `WorkflowDraftApplyAction` audit output only when present, letting `/mcp/workflow/execute` inherit the apply behavior through its existing delegation. Keep the implementation narrowly threaded through existing workflow seams instead of creating a general metadata envelope.

## Steps (agent-executable)
1. Inspect current plan normalization, draft/apply payload parsing, and workflow response builders to choose the smallest `workflow_action_id` threading path.
2. Add planner-side generation for canonical `workflow.draft_patch` actions in `WorkflowPlanAction` without changing non-draft actions.
3. Extend workflow draft/apply/execute payload parsing to accept an optional string `workflow_action_id` and reject non-string values with the existing endpoint-specific error code.
4. Thread the optional identifier through `WorkflowDraftPatchAction`, `WorkflowDraftApplyAction`, and `WorkflowExecuteAction` without passing it into provider clients.
5. Add or adjust focused service/request specs for planner generation, draft trace echo, apply audit echo, execute audit echo, and direct calls without the field.
6. Update README workflow examples and contract notes for the optional correlation field.
7. Run the targeted RSpec and `standardrb` commands from Definition of Done.

## Risks / Tech debt / Refactor signals
- Risk: the field could be mistaken for a security or persistence primitive. -> Mitigation: document it as correlation metadata only and avoid policy/auth behavior tied to it.
- Risk: adding the field to action params could leak it into provider prompt context. -> Mitigation: validate and thread it separately from instruction/path/context/profile before provider calls.
- Debt: accrues one more optional workflow metadata field, but pays down larger client-side cross-step inference debt.
- Refactor suggestion (if any): if more workflow metadata fields are added after this slice, extract a small workflow action metadata value object rather than growing loose hash plumbing.

## Notes / Open questions
- Assumption: `workflow_action_id` should live in canonical action params because clients already pass that object from `/mcp/workflow/plan` to dry-run/apply/execute.
- Assumption: the field should be echoed only when present for direct non-planner calls, preserving current direct-call behavior.
