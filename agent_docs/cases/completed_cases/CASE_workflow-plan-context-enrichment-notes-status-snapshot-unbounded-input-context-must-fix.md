---
case_id: CASE_workflow-plan-context-enrichment-notes-status-snapshot-unbounded-input-context-must-fix
created: 2026-03-08
---

# CASE: Must Fix - Bound Workflow Plan Input Context Size and Shape

## Slice metadata
- Type: hardening
- User Value: prevents oversized/unbounded planner payloads that can degrade latency, increase token cost, and produce unstable plan quality.
- Why Now: current workflow-plan enrichment forwards caller-provided `context` into planner payload without key/size limits, which conflicts with the case’s deterministic bounded-context intent.
- Risk if Deferred: `/mcp/workflow/plan` can accept arbitrarily large nested context objects and send them to LLM calls, increasing operational risk and reducing predictability.

## Goal
Enforce deterministic size/shape bounds for caller-supplied workflow-plan `context` before planner invocation.

## Why this next
- Value: closes a correctness gap in the current feature by aligning runtime behavior with bounded context requirements.
- Dependency/Risk: small, local change in workflow-plan action/builder path with focused spec updates.
- Tech debt note: preserves existing context enrichment design while adding explicit guardrails.

## Definition of Done
- [ ] `WorkflowPlanAction` rejects invalid/unbounded caller context deterministically (including oversized payload and unsupported nested structures if outside allowed policy).
- [ ] Planner receives a normalized bounded `input` section with stable schema/limits.
- [ ] Request specs cover at least one oversized-context failure contract (`invalid_workflow_intent`) and one bounded-success contract.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/services/mcp/workflow_plan_action_spec.rb spec/services/mcp/workflow_plan_context_builder_spec.rb`

## Scope
**In**
- Add explicit context normalization/limit policy in workflow-plan action or dedicated helper.
- Enforce deterministic bounds used by planner payload (`input` section).
- Add/update specs for invalid oversize context and normalized bounded behavior.

**Out**
- Changing planner output schema (`intent`, `provider`, `rationale`, `actions`).
- Introducing execute/orchestrator behavior.
- Broad refactors outside workflow-plan context path.

## Proposed approach
Add a small normalization policy for workflow input context in `WorkflowPlanAction` (or a narrow collaborator) before calling `WorkflowPlanContextBuilder`. Keep support for current `context.path` hint while constraining non-hint data to bounded string/object forms and limiting total serialized size (or key/value lengths) with deterministic `InvalidIntentError` messages. Ensure `WorkflowPlanContextBuilder` receives only normalized data and preserves existing snapshot/retrieval metadata behavior. Add request-level coverage to validate that oversized contexts fail with `invalid_workflow_intent`.

## Steps (agent-executable)
1. Define explicit workflow-context bounds policy (max serialized bytes and/or allowed key/value types).
2. Implement normalization + limit enforcement in `WorkflowPlanAction` before context builder call.
3. Keep `context.path` validation compatible with current behavior.
4. Add service specs for bounded normalization and oversize rejection.
5. Add request spec for oversize payload mapping to `invalid_workflow_intent`.
6. Run targeted workflow-plan specs and ensure no endpoint contract regressions.

## Risks / Tech debt / Refactor signals
- Risk: over-restrictive limits may block legitimate context usage. -> Mitigation: start with conservative but practical bounds and test expected payload shapes.
- Debt: context policy remains embedded in action unless a dedicated validator is introduced later.
- Refactor suggestion (if any): extract a `WorkflowPlanContextPolicy` object if additional context sections are added in follow-on cases.

## Notes / Open questions
- Assumption: preserving only bounded caller context is sufficient for this phase since server-built snapshot data now carries primary grounding value.
