---
case_id: CASE_workflow_plan_context_enrichment_notes_status_snapshot
created: 2026-03-08
---

# CASE: Workflow Plan Context Enrichment (Notes/Status Snapshot)

## Slice metadata
- Type: feature
- User Value: improves planning quality by giving the planner model bounded repository context (target note snapshot + index/semantic status) instead of relying on caller-supplied free-form context.
- Why Now: planning and patch-draft seams now exist; adding deterministic context is the smallest next step to make plan outputs actionable before any execute/orchestrator layer.
- Risk if Deferred: planner responses stay generic and can miss obvious constraints (missing files, stale index, disabled semantic mode), reducing trust in workflow guidance.

## Goal
Return stronger and more grounded `/mcp/workflow/plan` outputs by attaching a server-built context snapshot for requested note paths and retrieval status.

## Why this next
- Value: raises plan relevance without expanding mutating behavior.
- Dependency/Risk: builds directly on existing workflow planner endpoint and index/config status seams.
- Tech debt note: introduces a small context-builder object to avoid bloating route/action code.

## Definition of Done
- [ ] `POST /mcp/workflow/plan` accepts optional context hints (for example `path`) and enriches planner input with server-built snapshot fields.
- [ ] Snapshot includes bounded note metadata/content excerpt and retrieval-status metadata with deterministic shape and size limits.
- [ ] Missing/unreadable hinted note paths do not 500; endpoint returns deterministic validation or not-found style planner errors.
- [ ] Request and service specs cover: enriched success path, hint validation failures, and snapshot truncation/shape contract.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/services/mcp/workflow_plan_action_spec.rb spec/services/mcp/workflow_plan_context_builder_spec.rb spec/services/llm/workflow_planner_spec.rb`

## Scope
**In**
- Add a workflow-plan context builder seam under `app/services/mcp/` that gathers bounded note/status context.
- Extend workflow-plan action validation to normalize and constrain hint fields.
- Pass enriched context to the planner adapter while keeping endpoint read-safe.
- Add focused request/service specs for context-shape contracts and failure mapping.

**Out**
- Automatic execution of planned actions.
- Cross-note retrieval queries or dynamic multi-file planning context expansion.
- Any mutation endpoint behavior changes.

## Proposed approach
Introduce a small `WorkflowPlanContextBuilder` that accepts validated hint inputs (initially optional `path`) and composes a deterministic context object from existing read-safe surfaces: note read/preview data and runtime retrieval/index configuration/status signals. Keep strict size limits (for example excerpt length and fixed key set) to protect prompt budget and avoid accidental data overexposure. `WorkflowPlanAction` should own hint validation and delegate snapshot assembly to the builder before calling `WorkflowPlanner`. Route wiring remains unchanged apart from passing payload through the expanded action contract. Error mapping should preserve current planner semantics while adding explicit invalid-context handling where needed.

## Steps (agent-executable)
1. Add `WorkflowPlanContextBuilder` service with deterministic snapshot schema and truncation limits.
2. Extend `WorkflowPlanAction` contract to validate/normalize context hints and call the builder.
3. Wire dependencies in app boot so workflow planning uses the builder in production and test overrides remain simple.
4. Add/update planner error mapping for invalid/missing context-hint cases as needed.
5. Add unit specs for context builder schema/truncation and action-level validation behavior.
6. Update request specs for `/mcp/workflow/plan` success + failure paths with enriched context expectations.
7. Run targeted spec set and ensure endpoint behavior remains planning-only/read-safe.

## Risks / Tech debt / Refactor signals
- Risk: context size drift can inflate prompt tokens and latency. -> Mitigation: enforce strict field and character limits in builder tests.
- Risk: exposing raw note content broadly may leak unnecessary data. -> Mitigation: include only requested path preview and minimal status metadata.
- Debt: first pass may only support single-path hints.
- Refactor suggestion (if any): if context types grow (multi-path, recent mutations, retrieval samples), move snapshot assembly to typed context sections with per-section policies.

## Notes / Open questions
- Assumption: planning consumers can supply a single target path hint when they need grounded update guidance.
- Open question: should status context use `index/status` freshness signals only, or also include semantic adapter readiness flags in the same object.
