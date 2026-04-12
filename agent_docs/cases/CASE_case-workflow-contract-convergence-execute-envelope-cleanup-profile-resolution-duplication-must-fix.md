---
case_id: CASE_case-workflow-contract-convergence-execute-envelope-cleanup-profile-resolution-duplication-must-fix
created: 2026-04-12
---

# CASE: Execute Profile Resolution Duplication Must Fix

## Slice metadata
- Type: hardening
- User Value: keeps the converged execute contract maintainable by removing a redundant profile-resolution seam that could drift from the rest of workflow routing behavior.
- Why Now: the current execute-envelope cleanup is otherwise merge-ready, but the review found that profile handling is still normalized once in request parsing and then resolved again when building the apply action.
- Risk if Deferred: future profile-policy changes can update one resolution path and miss the other, reintroducing contract confusion into the execute boundary.

## Goal
Make the execute path resolve workflow profile policy exactly once while cleaning up the now-unused `action_policy` require in the execute action.

## Why this next
- Value: preserves the contract-convergence intent by keeping profile policy ownership in one place instead of splitting it across parse and build layers.
- Dependency/Risk: this is the only merge-blocking issue from review; fixing it now avoids carrying a second source of truth into later workflow routing changes.
- Tech debt note: pays down leftover execute-boundary duplication and one small stale dependency import.

## Definition of Done
- [ ] `POST /mcp/workflow/execute` no longer resolves workflow profile policy twice for the same request.
- [ ] Profile validation and provider selection for execute flow clearly reuse one shared resolution result.
- [ ] The stale `action_policy` require is removed from `WorkflowExecuteAction` if it remains unused after the fix.
- [ ] Focused specs still cover valid execute requests and invalid execute profile handling.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_workflow_execute_spec.rb spec/services/mcp/workflow_execute_action_spec.rb && bundle exec standardrb app/routes/mcp_helpers.rb app/routes/mcp_routes.rb app/services/mcp/workflow_execute_action.rb spec/mcp_workflow_execute_spec.rb spec/services/mcp/workflow_execute_action_spec.rb`

## Scope
**In**
- Remove the duplicate execute profile-resolution step between request parsing and action construction.
- Small cleanup directly related to that seam, including removing the unused `action_policy` require if still unused.

**Out**
- Broader redesign of workflow request parsing for plan, draft, or apply beyond what is required to remove the duplicate resolution.
- New workflow actions or execute capabilities beyond `workflow.draft_patch`.

## Proposed approach
Inspect the execute request helper and route wiring, then choose one owner for profile resolution in the execute path. Prefer carrying the already resolved result forward rather than re-resolving a normalized string through the builder stack. Keep the public request contract unchanged, keep execute-specific errors reported as `invalid_workflow_execute`, and limit the service-layer cleanup to directly related unused dependencies. Update the focused execute request/service specs only as needed to lock the single-resolution behavior.

## Steps (agent-executable)
1. Inspect the current execute request parsing and apply-action construction to identify the exact duplicate profile-resolution call chain.
2. Refactor the execute route/helper flow so one shared resolved profile result is used for both validation and drafter/apply construction.
3. Remove the stale `action_policy` require from `WorkflowExecuteAction` if it remains unused after the refactor.
4. Update focused execute specs and run the targeted RSpec plus `standardrb` commands from Definition of Done.

## Risks / Tech debt / Refactor signals
- Risk: shifting profile ownership could accidentally change execute error mapping or provider selection. → Mitigation: keep `invalid_workflow_execute` request-spec coverage for invalid profiles and one explicit local-profile success path.
- Debt: removes one small second-source-of-truth seam in workflow routing.
- Refactor suggestion (if any): if draft/apply/execute all start sharing resolved profile objects rather than profile strings, consider a small workflow request context object in a later slice instead of growing helper hashes.

## Notes / Open questions
- Assumption: the cleanest fix is to thread one resolved profile result through the execute route rather than re-resolving the normalized `profile` string in `build_workflow_draft_apply_action`.
