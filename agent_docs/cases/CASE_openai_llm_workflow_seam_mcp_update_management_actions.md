---
case_id: CASE_openai_llm_workflow_seam_mcp_update_management_actions
created: 2026-03-08
---

# CASE: OpenAI LLM Workflow Seam For MCP Update/Management Actions

## Slice metadata
- Type: feature
- User Value: enables natural-language workflow planning for note update and repository management tasks without changing existing MCP mutation safety boundaries.
- Why Now: semantic retrieval and snippet grounding are in place, so the next roadmap unlock is model-assisted update/management orchestration behind explicit service seams.
- Risk if Deferred: OpenAI-first phase remains retrieval-only, delaying validation of non-retrieval model workflows and increasing later integration risk.

## Goal
Introduce a bounded LLM workflow-planning seam that returns structured MCP action plans for update/management intents, without executing mutations.

## Why this next
- Value: unlocks the first user-visible non-retrieval LLM capability while preserving current patch/index safety contracts.
- Dependency/Risk: builds directly on existing MCP action boundaries and error-mapping patterns, reducing coupling risk for future execute/apply phases.
- Tech debt note: first iteration uses OpenAI-only planning adapter; provider parity remains a follow-on once planning contract stabilizes.

## Definition of Done
- [ ] Add a provider-agnostic workflow-planning service seam with an OpenAI-backed adapter and deterministic unavailable/error handling.
- [ ] Add one read-safe endpoint (for example, `POST /mcp/workflow/plan`) that accepts an intent payload and returns a structured action plan only (no execution).
- [ ] Expose runtime config diagnostics for workflow-planner enablement/model selection in `/config` without exposing secrets.
- [ ] Request/service specs cover success path, invalid payload path, and provider-unavailable fallback/error contract.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/runtime_config_spec.rb spec/mcp_error_mapper_spec.rb spec/mcp_workflow_plan_spec.rb spec/services/llm/workflow_planner_spec.rb`

## Scope
**In**
- Define a small workflow-plan response contract (ordered MCP actions + rationale metadata) for planning-only mode.
- Implement OpenAI adapter wiring behind an `llm/` service seam.
- Add config/env parsing and `/config` diagnostics for planner mode/provider/model.
- Add focused endpoint + service specs for contract and failure behavior.

**Out**
- Automatic execution of planned actions.
- Mutation endpoint contract changes (`/mcp/patch/*`, `/mcp/index/*`) beyond integration reuse.
- Self-hosted LLM provider support in this slice.

## Proposed approach
Create an `llm` domain seam that receives normalized workflow intents and returns validated action-plan objects consumed by a new MCP planning endpoint. Keep the endpoint read-safe: it only returns proposed MCP operations and does not call mutation actions. Reuse existing runtime config and error-mapping patterns so provider/config failures resolve to deterministic API errors. Keep OpenAI-specific prompting and response parsing confined to adapter classes to preserve planned provider portability and testability.

## Steps (agent-executable)
1. Add workflow-planner interface and OpenAI adapter under `app/services/llm/` with a narrow `plan(intent:, context:)` contract.
2. Add runtime config parsing for planner enablement/provider/model and expose non-secret diagnostics through `/config`.
3. Add `Mcp::WorkflowPlanAction` (or equivalent) plus a new `POST /mcp/workflow/plan` route with strict payload validation.
4. Reuse existing error mapper patterns for invalid payload, unavailable provider, and malformed provider response paths.
5. Add service specs for planner contract behavior and adapter failure mapping.
6. Add request specs for endpoint success + error contracts; run targeted runtime/MCP/LLM specs.

## Risks / Tech debt / Refactor signals
- Risk: model output drift can break action-plan parsing. -> Mitigation: require strict response-shape validation and deterministic malformed-response errors.
- Risk: planning endpoint may tempt premature execute coupling. -> Mitigation: keep execution explicitly out-of-scope and enforce read-safe route behavior in specs.
- Debt: OpenAI adapter/prompt policy will be provider-specific in this first pass.
- Refactor suggestion (if any): if planner payload complexity grows, extract a dedicated workflow-schema validator object.

## Notes / Open questions
- Assumption: a planning-only endpoint is sufficient to validate Phase 1 workflow value before adding execute/apply coupling.
- Open question: whether to include optional repository state summary in planner context now or defer to a follow-on slice.
