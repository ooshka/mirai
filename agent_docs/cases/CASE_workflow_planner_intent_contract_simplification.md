---
case_id: CASE_workflow_planner_intent_contract_simplification
created: 2026-04-12
---

# CASE: Workflow Planner Intent Contract Simplification

## Slice metadata
- Type: feature
- User Value: lets workflow planners emit a smaller semantic draft intent while `mirai` owns expansion into the canonical `workflow.draft_patch` execution shape, reducing brittle planner formatting pressure.
- Why Now: the earlier plan-to-draft handoff case established a canonical execution-ready action shape, but later slices moved more responsibility into `mirai` through `edit_intent`, dry-run trace, execute wiring, and profile routing; the planner is now carrying execution-shape detail that `mirai` can derive deterministically.
- Risk if Deferred: local and hosted planners will keep depending on syntax-heavy, execution-shaped action payloads that are harder to produce reliably, and the current planner envelope will harden further before `mirai` reclaims the unnecessary structure.

## Goal
Let `/mcp/workflow/plan` emit a smaller semantic draft intent that `mirai` expands into the canonical `workflow.draft_patch` action shape for downstream workflow execution.

## Why this next
- Value: reduces model-boundary complexity without changing the canonical downstream workflow contract used by draft/apply/execute paths.
- Dependency/Risk: builds directly on the completed plan handoff, `edit_intent`, execute, and profile slices while keeping the change limited to planner normalization plus one server-owned expansion seam.
- Tech debt note: pays down planner/output over-coupling to the current drafter wire format, while intentionally deferring broader action-taxonomy redesign and execute-envelope cleanup.

## Definition of Done
- [ ] `/mcp/workflow/plan` accepts planner output for draft generation in a smaller semantic intent shape rather than requiring the full canonical `workflow.draft_patch` params payload from the model.
- [ ] `mirai` expands that semantic planner intent into the existing canonical `workflow.draft_patch` action shape before returning actions to callers, so downstream draft/apply/execute consumers keep one stable action contract.
- [ ] Planner normalization rejects malformed or incomplete semantic draft intents deterministically, including missing required fields and unsupported profile/context shapes.
- [ ] Existing canonical `workflow.draft_patch` request handling remains unchanged for callers and thin clients outside the planner boundary.
- [ ] Focused request/service specs cover one successful planner semantic-intent expansion plus key malformed planner-output cases.
- [ ] README workflow docs explain that planner output is normalized server-side into the canonical draft action shape rather than exposing the smaller planner-only shape directly to consumers.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/services/llm/workflow_planner_spec.rb`

## Scope
**In**
- Narrow planner-output contract simplification for the draft-generation path only.
- One server-owned expansion seam from planner semantic intent to canonical `workflow.draft_patch` action payload.
- Focused docs/spec updates for the planner boundary.

**Out**
- Changing the public canonical `workflow.draft_patch` action shape used outside planner generation.
- Simplifying non-draft planner actions.
- Execute/apply envelope cleanup beyond any minimal adjustments required for planner expansion correctness.

## Proposed approach
Keep the canonical downstream action contract intact and move simplification only to the planner/model boundary. Introduce a smaller planner-owned semantic intent shape for draft generation, likely centered on draft target path, user instruction, and optional profile/context fields without asking the model to reproduce the full action wrapper and current param naming exactly. Normalize that smaller shape in the workflow planner service, expand it server-side into the canonical `workflow.draft_patch` action payload, and continue returning the canonical action to callers. Limit code changes to planner prompt guidance, planner result normalization/expansion, focused request specs, and README workflow notes so the slice stays bounded and does not reopen execute or drafter contracts.

## Steps (agent-executable)
1. Inspect the current workflow planner prompt, planner normalization, and plan request specs to identify the smallest semantic shape that still covers draft-generation intent.
2. Define a planner-only semantic draft intent schema with explicit required fields and bounded optional fields for profile/context.
3. Update workflow planner prompt guidance and normalization so planner outputs are parsed in that semantic shape and invalid planner responses fail deterministically.
4. Add one server-owned expansion step that converts the semantic planner intent into the canonical returned `workflow.draft_patch` action payload.
5. Update focused request/service specs to lock one successful expansion path and malformed planner-output rejection cases.
6. Refresh README workflow documentation to clarify that the public returned action remains canonical even though the planner-facing shape is smaller.

## Risks / Tech debt / Refactor signals
- Risk: simplifying too aggressively could hide fields that the canonical action still needs, leading to lossy expansion. -> Mitigation: keep the planner-only schema narrowly aligned to the existing canonical action fields and validate expansion through request specs.
- Risk: exposing the planner-only shape publicly would create two external workflow action contracts. -> Mitigation: keep the smaller shape internal to planner normalization and return only the canonical action payload to callers.
- Debt: pays down model-facing contract overhead, but adds one translation seam that should stay small and explicit.
- Refactor suggestion (if any): if multiple planner actions later need the same pattern, extract a small planner-action normalizer/expander instead of growing one-off inline conversion logic.

## Notes / Open questions
- Assumption: the first semantic planner intent should cover only the draft-generation action, not the broader planner action set.
- Assumption: preserving the canonical returned action shape is more important than exposing planner internals, because draft/apply/execute and thin clients already depend on that single downstream contract.
