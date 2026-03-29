---
case_id: CASE_canonical_workflow_execute_endpoint
created: 2026-03-29
---

# CASE: Canonical Workflow Execute Endpoint

## Slice metadata
- Type: feature
- User Value: gives operators and thin workflow clients one server-owned endpoint that can accept a planned `workflow.draft_patch` action payload and carry it through draft generation plus patch apply without stitching together multiple workflow endpoints.
- Why Now: the workflow surface now has stable plan, draft, and apply seams, but consumers still need endpoint-specific translation and sequencing to complete one note-update run; converging on a canonical execute path now is cheaper than letting that client glue harden across more consumers.
- Risk if Deferred: additional clients will keep encoding their own `/mcp/workflow/plan` -> `/mcp/workflow/draft_patch` -> `/mcp/workflow/apply_patch` orchestration, making a later server-owned workflow contract change more disruptive and leaving audit semantics split across multiple endpoints.

## Goal
Add one canonical workflow execute endpoint that accepts the existing planned draft action payload and returns the applied update result through a single server-owned flow.

## Why this next
- Value: reduces client-side orchestration and makes the operator path from intent to committed note update easier to run and reason about.
- Dependency/Risk: builds directly on the existing `WorkflowDraftPatchAction` and `WorkflowDraftApplyAction` seams, so the slice can stay bounded to endpoint design, request shaping, and focused orchestration.
- Tech debt note: pays down the current multi-endpoint workflow stitching debt while avoiding a broader generic workflow dispatcher redesign.

## Definition of Done
- [ ] A new workflow-owned execute endpoint exists with a request contract aligned to the canonical `workflow.draft_patch` planner action payload and no extra translation fields.
- [ ] The execute endpoint performs draft generation and patch apply through one server-owned orchestration path while preserving existing patch policy enforcement and mutation behavior.
- [ ] The success response exposes applied-update summary and workflow audit data through one explicit contract, reusing the tightened workflow apply response ownership where practical.
- [ ] Existing `/mcp/workflow/plan`, `/mcp/workflow/draft_patch`, and `/mcp/workflow/apply_patch` behavior remains unchanged unless the new endpoint requires a small shared orchestration extraction for correctness.
- [ ] Request/service specs cover at least one successful execute flow plus one invalid payload or policy-denied regression path.
- [ ] README workflow docs describe when clients should use the canonical execute endpoint versus the lower-level draft/apply endpoints.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/mcp_workflow_apply_patch_spec.rb spec/services/mcp/workflow_draft_apply_action_spec.rb` plus any new focused execute-endpoint spec file.

## Scope
**In**
- Add one workflow execute endpoint and the smallest orchestration/service seam needed to support it.
- Reuse the canonical planner action payload shape for `workflow.draft_patch` execution when possible.
- Update focused request/service specs and README workflow documentation.

**Out**
- Generic execution for arbitrary planner actions beyond `workflow.draft_patch`.
- Removal of existing draft/apply endpoints in this slice.
- Broader workflow event logging, queued execution, or multi-step transaction semantics.

## Proposed approach
Treat this as a narrow convergence slice, not a workflow-platform rewrite. Introduce one new workflow-owned endpoint, likely under `/mcp/workflow/execute`, that accepts an action payload shaped like the planner’s canonical `workflow.draft_patch` output. Validate the action name and required params at the boundary, then route only the supported draft-patch action through a small executor/orchestrator that reuses `WorkflowDraftApplyAction` instead of duplicating route logic. Keep patch policy enforcement and request validation explicit in the route/action layer. Preserve existing lower-level endpoints for operators that still want dry-run drafting or direct patch application. Limit changes primarily to `app/routes/mcp_routes.rb`, a small new `app/services/mcp/` action or executor, request specs for the new endpoint, and README workflow contract text.

## Steps (agent-executable)
1. Inspect the current planner output shape, `/mcp/workflow/draft_patch`, and `/mcp/workflow/apply_patch` request contracts to identify the narrowest action payload that can become the execute endpoint input unchanged.
2. Add a workflow-owned execute action/service that validates the supported action name (`workflow.draft_patch`) and delegates to `WorkflowDraftApplyAction` using the action params as the single source of truth.
3. Add a new route in `app/routes/mcp_routes.rb` that parses the execute payload, enforces the same mutation policy boundary as workflow apply, and returns the executor result.
4. Refactor only the minimum shared drafter/executor construction needed to avoid duplicated route orchestration between workflow apply and the new execute endpoint.
5. Add focused request specs for successful execution, invalid action payloads, and read-only/policy-denied behavior; add or adjust a service spec for the new executor boundary.
6. Update README workflow docs to point thin clients at the canonical execute path for end-to-end note updates while preserving lower-level endpoint descriptions for manual operator control.

## Risks / Tech debt / Refactor signals
- Risk: the execute endpoint could drift into a generic action dispatcher and enlarge scope quickly. -> Mitigation: support only canonical `workflow.draft_patch` in this slice and reject other action names explicitly.
- Risk: duplicated drafter/apply wiring between endpoints could make route maintenance worse if copied again. -> Mitigation: extract only a tiny shared executor construction seam if needed, not a broad workflow framework.
- Debt: pays down client-side endpoint stitching debt; may intentionally leave old endpoints in place until consumers migrate.
- Refactor suggestion (if any): if more executable workflow actions are added later, extract a dedicated workflow executor/registry after the first execute contract proves out.

## Notes / Open questions
- Assumption: pre-broad-adoption contract cleanup is still acceptable, so a new canonical endpoint can be introduced before external clients depend heavily on the older multi-step path.
- Assumption: the execute endpoint should accept the planner action object directly or with only one thin wrapper field, rather than inventing a second parallel request schema.
