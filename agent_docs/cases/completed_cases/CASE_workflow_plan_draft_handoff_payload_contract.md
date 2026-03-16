---
case_id: CASE_workflow_plan_draft_handoff_payload_contract
created: 2026-03-15
---

# CASE: Workflow Plan Draft Handoff Payload Contract

## Slice metadata
- Type: feature
- User Value: lets operators and tools hand a planner-produced draft action directly into `/mcp/workflow/draft_patch` without inventing glue code or guessing which fields belong where.
- Why Now: the workflow planner and patch drafter endpoints now exist side by side, but their request contracts are still loosely coupled, which blocks a clean plan-to-draft operator loop.
- Risk if Deferred: planner output will harden around ad hoc action params, forcing each consumer to translate draft intent differently and making later contract cleanup more disruptive.

## Goal
Define one canonical planner action payload for draft generation so `/mcp/workflow/plan` can emit a draft-ready action that aligns directly with `/mcp/workflow/draft_patch`.

## Why this next
- Value: unlocks the first low-friction workflow where a planning response can drive a draft-patch request without custom mapping.
- Dependency/Risk: builds on the existing workflow planning and draft endpoints without widening into execution, apply, or local-provider work.
- Tech debt note: pays down contract ambiguity between adjacent workflow endpoints before more consumers depend on the current free-form planner action params.

## Definition of Done
- [ ] `/mcp/workflow/plan` has a documented canonical action shape for draft generation, including the exact action name and params that map to `/mcp/workflow/draft_patch`.
- [ ] Planner normalization rejects malformed draft-handoff actions instead of passing through ambiguous params.
- [ ] `/mcp/workflow/draft_patch` accepts the agreed payload shape without requiring consumers to duplicate fields into a different envelope.
- [ ] Request/service specs cover one valid planner-to-draft handoff and key invalid-shape cases.
- [ ] Docs/verification: README workflow endpoint examples and targeted specs reflect the aligned contract.

## Scope
**In**
- Tighten the workflow planner action contract for the draft-patch handoff path.
- Align request validation and normalization across planner and drafter surfaces where needed for direct reuse.
- Update targeted docs/specs for the canonical handoff payload.

**Out**
- Executing planner actions automatically.
- Multi-step workflow orchestration beyond the draft handoff action.
- Broader action-taxonomy redesign for non-draft planner actions.

## Proposed approach
Keep this slice narrowly focused on the contract boundary between existing workflow endpoints. Identify the smallest planner action shape that can represent a draft request, then make that shape canonical in planner normalization, endpoint examples, and draft-request validation. Prefer one explicit draft action contract over a generic free-form params pass-through so operators and future tooling can rely on a stable handoff surface. Limit code changes to workflow planner/drafter services, route payload parsing if needed, and the focused request/service specs already covering those endpoints.

## Steps (agent-executable)
1. Inspect the current `/mcp/workflow/plan` action normalization, planner prompt, and `/mcp/workflow/draft_patch` request validation to locate the narrowest shared handoff boundary.
2. Define the canonical draft-handoff action contract, including action name and required params, and document how it maps directly onto the draft endpoint request payload.
3. Update workflow planner normalization and prompt guidance so malformed or incomplete draft-handoff actions are rejected deterministically.
4. Adjust `/mcp/workflow/draft_patch` request handling only as needed to consume the canonical payload without duplicate translation fields.
5. Add or update request/service specs for one end-to-end handoff example plus invalid action/payload shape cases.
6. Refresh README workflow examples and any planner-facing notes to describe the aligned contract clearly.

## Risks / Tech debt / Refactor signals
- Risk: over-specifying all planner actions in one slice could expand scope and stall delivery. -> Mitigation: constrain validation changes to the draft-handoff action and leave other actions minimally normalized unless correctness requires more.
- Risk: aligning the draft payload could accidentally break the existing endpoint request shape for current callers. -> Mitigation: lock the intended request contract in request specs before changing normalization rules.
- Debt: pays down free-form workflow action ambiguity and duplicate consumer-side translation logic between planner and drafter endpoints.
- Refactor suggestion (if any): if more planner actions later need typed validation, extract a small workflow action-schema validator instead of growing `WorkflowPlanner` normalization inline.

## Notes / Open questions
- Assumption: the canonical draft handoff should be explicit enough that an operator or thin client can submit it to `/mcp/workflow/draft_patch` with no field remapping beyond wrapping it as the request body if needed.
