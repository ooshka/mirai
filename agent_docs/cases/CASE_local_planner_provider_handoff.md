---
case_id: CASE_local_planner_provider_handoff
created: 2026-03-21
---

# CASE: Local Planner Provider Handoff

## Slice metadata
- Type: feature
- User Value: lets `mirai` consume the validated `local_llm` planner path behind the existing workflow-plan contract so self-hosted orchestration can begin without guessing at provider behavior.
- Why Now: `local_llm` has completed planner smoke, parity fixtures, and fixture-hygiene work, while `mirai` still hard-codes the workflow planner to `openai` despite already supporting local semantic retrieval on the retrieval side.
- Risk if Deferred: the completed local planner evidence stays stranded in docs and fixtures, and `mirai`'s workflow planning seam continues to assume hosted-provider-only wiring even as the self-hosted path becomes the next concrete integration target.

## Goal
Add a narrow local workflow-planner provider seam in `mirai` so `POST /mcp/workflow/plan` can use a self-hosted planner backend without changing its request or response contract.

## Why this next
- Value: unlocks the first real `mirai` consumption path for the completed `local_llm` planner evidence.
- Dependency/Risk: directly uses the new local parity-fixture work to keep provider behavior bounded before any deeper local patch-drafter or end-to-end orchestration slice.
- Tech debt note: pays down current OpenAI-only planner coupling while intentionally leaving workflow patch drafting and broader local runtime fallback policy for later.

## Definition of Done
- [ ] `Llm::WorkflowPlanner` can represent at least `openai` and `local` providers without route-layer provider branching.
- [ ] A minimal local workflow planner client/adapter seam exists that targets the current `local_llm` OpenAI-compatible planner baseline and preserves the normalized `intent/provider/rationale/actions` result contract.
- [ ] Runtime/config diagnostics expose the local planner provider option and bounded readiness signals without leaking secrets.
- [ ] Request/service specs cover provider selection, local-planner success normalization, and unavailable/malformed local-provider mapping for `/mcp/workflow/plan`.
- [ ] README/config guidance documents the local planner provider option and expected base URL/config surface at a high level.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/runtime_config_spec.rb spec/mcp_workflow_plan_spec.rb spec/services/llm/workflow_planner_spec.rb`

## Scope
**In**
- Provider-aware workflow planner selection for `openai` and `local`.
- A minimal local planner client/adapter seam using the existing `local_llm` planner JSON baseline.
- Focused runtime-config, request-spec, and service-spec updates for planner-provider selection and failure behavior.

**Out**
- Local workflow patch-drafter wiring.
- End-to-end notes-repo orchestration tests.
- Planner prompt tuning or broader provider-fallback policy beyond deterministic unavailable handling.

## Proposed approach
Keep the slice parallel to the existing retrieval-provider work: extend planner provider selection in the service/config layer rather than branching in routes. Add a local planner client that speaks the same OpenAI-compatible chat-completions interface `local_llm` already validates through Ollama, then let `WorkflowPlanner` choose between OpenAI and local adapters while preserving the normalized plan contract and existing `planner_unavailable` mapping. Limit config work to the smallest additive surface needed for a local base URL and readiness diagnostics, and defer the patch-drafter side until this planner seam is proven.

## Steps (agent-executable)
1. Inspect current workflow planner config parsing, route wiring, and service specs to identify the narrowest provider-selection extension point.
2. Add local planner provider config/diagnostic support and extend `WorkflowPlanner` provider normalization to accept `local`.
3. Introduce a minimal local planner client/adapter that targets the `local_llm` OpenAI-compatible planner baseline and maps malformed/unreachable responses to the existing unavailable path.
4. Keep `/mcp/workflow/plan` request and response contracts unchanged while updating route wiring to construct the right planner client through one bounded seam.
5. Add focused service/request/runtime-config specs for local-provider success and unavailable/malformed failure behavior.
6. Update README/config docs only enough to describe the local planner provider option and required base URL/runtime assumptions.

## Risks / Tech debt / Refactor signals
- Risk: planner provider selection could leak branching into route code. -> Mitigation: keep provider choice inside runtime config and `Llm::WorkflowPlanner`/adjacent client construction.
- Risk: the local planner adapter could overfit current Ollama behavior and accidentally redefine the public workflow-plan contract. -> Mitigation: normalize to the existing plan contract and reuse `local_llm` parity evidence as the adapter boundary.
- Debt: this slice still leaves local workflow patch drafting and deeper end-to-end orchestration for later Cases.
- Refactor suggestion (if any): if planner provider variants or fallback rules expand beyond `openai|local`, extract a dedicated planner-client factory/registry rather than continuing to widen the planner initializer.

## Notes / Open questions
- Assumption: the first local planner handoff should target the current OpenAI-compatible `/v1/chat/completions` path already validated in `local_llm`, not a new bespoke transport.
- Assumption: deterministic `planner_unavailable` behavior is sufficient for this slice; richer provider-specific diagnostics can stay in `/config` and later hardening work.
