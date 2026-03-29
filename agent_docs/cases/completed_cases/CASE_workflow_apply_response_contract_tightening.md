---
case_id: CASE_workflow_apply_response_contract_tightening
created: 2026-03-29
---

# CASE: Workflow Apply Response Contract Tightening

## Slice metadata
- Type: feature
- User Value: gives workflow operators one explicit response contract for `/mcp/workflow/apply_patch`, so thin clients can distinguish mutation summary fields from drafted-patch audit data without depending on the current ad hoc flat merge.
- Why Now: the first workflow apply loop landed on 2026-03-23, and its response currently just merges `PatchApplyAction` output with a top-level `patch` field; tightening that shape now is cheaper than carrying a loosely owned contract into additional workflow consumers.
- Risk if Deferred: local smoke consumers and later workflow clients will bind to the current flat response, making even a small response cleanup more disruptive and increasing ambiguity about which fields belong to patch-apply versus workflow audit semantics.

## Goal
Tighten `/mcp/workflow/apply_patch` so its response keeps the patch-apply summary explicit while moving drafted-patch audit data under a workflow-owned envelope instead of exposing a loose top-level `patch` field.

## Why this next
- Value: makes the first workflow execution contract easier to consume and review without widening scope into generic workflow execution.
- Dependency/Risk: builds directly on the new workflow apply route and keeps the change localized to response shaping, docs, and focused specs.
- Tech debt note: pays down the temporary response-merging shortcut from the previous feature while avoiding a larger contract redesign across draft/apply endpoints.

## Definition of Done
- [ ] `POST /mcp/workflow/apply_patch` returns a documented tightened response shape where patch-apply summary fields remain explicit and drafted-patch audit data is nested under a workflow-owned key such as `audit`.
- [ ] The response no longer exposes the drafted unified diff as a loose top-level `patch` field.
- [ ] `Mcp::WorkflowDraftApplyAction` owns the tightened response shaping instead of relying on a direct hash merge from patch apply output.
- [ ] Request and service specs lock one successful tightened response contract and retain at least one invalid envelope or policy-denied regression path.
- [ ] README endpoint docs reflect the tightened response shape and clarify the ownership boundary between apply summary data and workflow audit data.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_apply_patch_spec.rb spec/services/mcp/workflow_draft_apply_action_spec.rb`

## Scope
**In**
- Tighten the success response contract for `/mcp/workflow/apply_patch`.
- Small service-layer response shaping in `WorkflowDraftApplyAction`.
- Focused request/service spec and README updates needed to document the new contract.

**Out**
- New workflow endpoints or generic action execution.
- Changes to `/mcp/patch/apply` response shape.
- Planner-output schema changes or wider workflow audit/event logging.

## Proposed approach
Keep the slice intentionally narrow: preserve the existing patch-apply summary fields (`path`, `hunk_count`, `net_line_delta`) and move the drafted diff under an explicit workflow audit envelope such as `audit.patch`. Prefer this small nesting change over a broader `{draft, apply}` response redesign, because it isolates the ambiguous field today without forcing every current summary field into a new structure. Limit changes to `WorkflowDraftApplyAction`, the request/service specs that assert the current flat response, and the README endpoint contract text.

## Steps (agent-executable)
1. Inspect `Mcp::WorkflowDraftApplyAction`, `spec/mcp_workflow_apply_patch_spec.rb`, and README workflow endpoint docs to confirm the current flat merged response contract.
2. Update `Mcp::WorkflowDraftApplyAction` to return the existing patch-apply summary plus a workflow-owned nested audit payload for the drafted diff instead of a top-level `patch`.
3. Keep `/mcp/workflow/apply_patch` request validation, policy enforcement, and patch-apply behavior unchanged while tightening only the success payload shape.
4. Update request specs to assert the tightened success response and preserve invalid-envelope and `read_only` denial regressions.
5. Update the focused service spec to lock the new response-shaping boundary in `WorkflowDraftApplyAction`.
6. Refresh README workflow/apply endpoint documentation to show the tightened response and explain why the drafted diff now lives under workflow audit fields.

## Risks / Tech debt / Refactor signals
- Risk: over-correcting into a broad `draft`/`apply` contract redesign would create unnecessary consumer churn. -> Mitigation: keep patch-apply summary fields stable and only isolate audit data under one nested key.
- Risk: request specs may miss existing consumers relying on the top-level `patch` field. -> Mitigation: document the breaking contract change explicitly in README and lock the new shape in focused request/service specs.
- Debt: pays down the response-merging shortcut introduced to ship the first operator loop quickly.
- Refactor suggestion (if any): if workflow execution later needs more returned audit metadata, grow the nested audit object instead of adding more top-level fields.

## Notes / Open questions
- Assumption: the smallest useful tightening is to move the drafted unified diff under `audit.patch` while leaving the patch-apply summary fields flat.
- Assumption: no compatibility shim is needed because the external consumer set is still small and this repo explicitly allows coordinated contract cleanup at this stage.
