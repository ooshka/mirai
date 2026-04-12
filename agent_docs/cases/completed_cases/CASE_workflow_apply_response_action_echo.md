---
case_id: CASE_workflow_apply_response_action_echo
created: 2026-04-12
---

# CASE: Workflow Apply Response Action Echo

## Slice metadata
- Type: feature
- User Value: gives thin workflow clients and operator tooling one explicit action-identity field in workflow apply responses so they can correlate planner output and mutation results without inferring it from endpoint choice.
- Why Now: execute-envelope convergence has made the canonical `workflow.draft_patch` action the clear workflow contract, but apply responses still require clients to infer which action just ran from surrounding context.
- Risk if Deferred: thin clients, CLI surfaces, and later UI work will keep adding endpoint-specific correlation logic that should be handled once by the server contract.

## Goal
Add one explicit action-identity echo to workflow apply responses so workflow clients can correlate planned actions and apply results using the response itself.

## Why this next
- Value: removes one more piece of client-side inference from the workflow path and makes apply results more self-describing for operator and thin-client use.
- Dependency/Risk: builds directly on the just-landed canonical execute/apply contract work without reopening request-shape design or broader workflow routing.
- Tech debt note: pays down workflow-response correlation debt while intentionally deferring richer cross-step correlation metadata until a later slice.

## Definition of Done
- [ ] `/mcp/workflow/apply_patch` responses include one explicit action-identity field for the executed canonical workflow action.
- [ ] `/mcp/workflow/execute` responses include the same action-identity field when executing the canonical `workflow.draft_patch` action.
- [ ] Existing top-level apply summary fields and nested `audit` structure remain stable aside from the new action-identity field.
- [ ] Focused request/service specs cover the echoed action field for both apply and execute paths.
- [ ] README workflow docs describe the new response field and its role in planner/apply correlation.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb spec/services/mcp/workflow_draft_apply_action_spec.rb spec/services/mcp/workflow_execute_action_spec.rb && bundle exec standardrb app/services/mcp/workflow_draft_apply_action.rb app/services/mcp/workflow_execute_action.rb spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb spec/services/mcp/workflow_draft_apply_action_spec.rb spec/services/mcp/workflow_execute_action_spec.rb`

## Scope
**In**
- Add one explicit action-identity echo field to the workflow apply and execute response contract for canonical `workflow.draft_patch`.
- Update focused workflow apply/execute specs and README documentation for the new response field.

**Out**
- Broader planner-to-apply correlation IDs or trace/session metadata.
- New workflow actions or generalized action registries beyond the current canonical `workflow.draft_patch` path.

## Proposed approach
Treat this as a narrow response-contract improvement, not a new workflow capability. Start from the current apply response shape produced by `WorkflowDraftApplyAction`, add one explicit action-identity field there, and let `/mcp/workflow/execute` inherit the same echoed field through the existing delegation path. Keep the field top-level so thin clients can correlate results without inspecting nested audit data, and avoid mixing this slice with richer correlation tokens or trace identifiers. Update the focused request specs for `/mcp/workflow/apply_patch` and `/mcp/workflow/execute`, keep service-spec coverage close to `WorkflowDraftApplyAction` and `WorkflowExecuteAction`, and document the field in the workflow endpoint section of the README.

## Steps (agent-executable)
1. Inspect the current workflow apply response builder and request specs to identify the narrowest place to add an explicit action echo.
2. Add the action-identity field to `WorkflowDraftApplyAction` so both apply and execute can reuse the same response shape.
3. Update any execute service/request wiring only if required to preserve the echoed action in the delegated response path.
4. Add or adjust focused request/service specs for `/mcp/workflow/apply_patch` and `/mcp/workflow/execute`.
5. Update the README workflow endpoint docs to describe the new response field and its correlation purpose.
6. Run the targeted RSpec and `standardrb` commands from Definition of Done.

## Risks / Tech debt / Refactor signals
- Risk: the new response field could accidentally diverge between apply and execute paths. → Mitigation: add request-spec assertions for both endpoints and anchor the field in the shared apply response builder.
- Risk: naming the field too broadly could imply a generic action registry before one exists. → Mitigation: keep the field narrowly described as the canonical workflow action identity for the current path.
- Debt: pays down response-correlation debt that currently forces endpoint-specific client inference.
- Refactor suggestion (if any): if later slices add more top-level workflow correlation fields, extract a small workflow response value object instead of continuing to grow response hashes inline.

## Notes / Open questions
- Assumption: the best field shape is one top-level action-identity echo, not a broader correlation envelope, because the current need is only to make apply/execute results self-identifying.
