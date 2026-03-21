---
case_id: CASE_case-case-local-planner-provider-handoff-decouple-draft-patch-provider-must-fix
created: 2026-03-21
---

# CASE: Decouple Draft Patch Provider From Local Planner Handoff

## Slice metadata
- Type: hardening
- User Value: keeps the planner-to-draft operator loop usable after enabling the new local planner provider instead of letting `/mcp/workflow/draft_patch` regress to a guaranteed unavailable response.
- Why Now: the current local planner handoff branch marks `MCP_WORKFLOW_PLANNER_PROVIDER=local` as supported, but the draft-patch route still consumes that same provider setting while only supporting the OpenAI patch client.
- Risk if Deferred: operators can successfully get `workflow.draft_patch` actions from `/mcp/workflow/plan` and then immediately fail to execute the corresponding draft step in the same runtime configuration.

## Goal
Preserve working `/mcp/workflow/draft_patch` behavior when the planner provider is set to `local`, without broadening this slice into full local patch-drafter support.

## Why this next
- Value: closes the most immediate end-to-end regression introduced by the planner-provider handoff.
- Dependency/Risk: blocks merge because the new local planner path currently breaks the next canonical workflow step.
- Tech debt note: this should remain a narrow decoupling or guardrail, not a stealth implementation of local patch drafting.

## Definition of Done
- [ ] `/mcp/workflow/draft_patch` no longer becomes unavailable solely because `MCP_WORKFLOW_PLANNER_PROVIDER=local` is selected for planning.
- [ ] Route/service behavior makes the planner-provider versus drafter-provider boundary explicit and deterministic.
- [ ] Request/service specs cover the local-planner-configured runtime so this coupling cannot silently regress.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_draft_patch_spec.rb spec/mcp_workflow_plan_spec.rb spec/services/llm/workflow_patch_drafter_spec.rb`

## Scope
**In**
- The workflow draft-patch route and adjacent drafter-provider wiring.
- Focused spec coverage for local-planner-configured workflow draft behavior.
- Minimal README clarification if the implementation changes operator expectations.

**Out**
- Full local workflow patch-drafter implementation.
- Broader workflow-provider config redesign beyond the minimum needed to remove this regression.

## Proposed approach
Treat this as a coupling fix, not a new feature. Identify the narrowest seam that prevents the draft-patch path from inheriting unsupported local-planner provider state. That likely means explicitly keeping the drafter on the existing OpenAI path for now, or introducing a tiny bounded config distinction if needed for correctness. Preserve the current request/response contract and keep failure behavior deterministic. Add the smallest request/service specs that prove a `local` planner configuration does not make draft generation unusable by accident.

## Steps (agent-executable)
1. Inspect the current `/mcp/workflow/draft_patch` route and `WorkflowPatchDrafter` provider handling to pinpoint where the planner-provider coupling leaks in.
2. Implement the narrowest fix that keeps draft generation working when the planner provider is `local` while staying out of local patch-drafter feature work.
3. Add focused request/service specs for the local-planner-configured runtime and any changed boundary behavior.
4. Update README guidance only if the chosen fix changes what operators need to configure or expect.

## Risks / Tech debt / Refactor signals
- Risk: accidentally broadening this fix into partial local patch-drafter support. -> Mitigation: keep the change bounded to provider decoupling and contract preservation.
- Debt: planner and drafter still share coarse workflow config names; a later slice may want clearer config ownership.
- Refactor suggestion (if any): if planner and drafter providers continue to diverge, introduce a dedicated workflow runtime-config object or explicit separate provider settings rather than reusing one flag across both surfaces.

## Notes / Open questions
- Assumption: preserving the existing draft-patch OpenAI path is preferable to making `/mcp/workflow/draft_patch` fail under a newly documented local planner configuration.
