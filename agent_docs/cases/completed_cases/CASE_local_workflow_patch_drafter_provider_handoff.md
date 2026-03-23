---
case_id: CASE_local_workflow_patch_drafter_provider_handoff
created: 2026-03-22
---

# CASE: Local Workflow Patch Drafter Provider Handoff

## Slice metadata
- Type: feature
- User Value: lets operators complete the self-hosted workflow loop in `mirai` by turning planner-produced `workflow.draft_patch` actions into bounded draft patches through the validated local runtime path.
- Why Now: `local_llm` has already landed the local workflow draft smoke path and `mirai` has finished local planner-provider wiring, so the remaining cross-project gap is the draft-patch seam still hard-coded to the hosted client.
- Risk if Deferred: the self-hosted workflow path stays half-complete, forcing planner output to hand off into a different provider path and leaving the most visible local-workflow gap unresolved.

## Goal
Add a narrow local workflow patch-drafter provider seam in `mirai` so `POST /mcp/workflow/draft_patch` can use the self-hosted runtime without changing its request or response contract.

## Why this next
- Value: completes the next user-visible self-hosted workflow step after local planner handoff.
- Dependency/Risk: converts already-validated `local_llm` provider evidence into the `mirai` runtime seam that is still missing.
- Tech debt note: pays down the current planner/drafter provider mismatch while intentionally deferring broader workflow fallback policy or multi-provider orchestration redesign.

## Definition of Done
- [ ] `Llm::WorkflowPatchDrafter` can represent at least `openai` and `local` providers without route-level branching.
- [ ] A minimal local workflow patch client/adapter exists that targets the current `local_llm` OpenAI-compatible draft-patch baseline and normalizes successful responses to a non-empty unified diff string.
- [ ] `POST /mcp/workflow/draft_patch` preserves its current request and response contract when the drafter provider is `local`, including deterministic unavailable behavior for malformed or unreachable local runtime responses.
- [ ] Runtime/config diagnostics and README guidance make the local drafter path explicit enough for operators to configure without guessing.
- [ ] Focused service/request/runtime-config specs cover provider selection, local draft success normalization, and unavailable/malformed local-provider mapping.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/runtime_config_spec.rb spec/mcp_workflow_draft_patch_spec.rb spec/services/llm/workflow_patch_drafter_spec.rb`

## Scope
**In**
- Provider-aware workflow patch-drafter selection for `openai` and `local`.
- A minimal local draft client/adapter that reuses the existing OpenAI-compatible local workflow base URL boundary.
- Focused runtime-config, request-spec, and service-spec updates for draft-provider selection and failure behavior.

**Out**
- Planner-provider fallback redesign or multi-provider orchestration policy.
- End-to-end patch apply execution beyond draft generation.
- Broader prompt tuning or richer provider-specific metadata in draft responses.

## Proposed approach
Mirror the planner-provider structure instead of widening route logic. Add one local draft client that speaks the same OpenAI-compatible `/v1/chat/completions` boundary already validated in `local_llm`, then let `WorkflowPatchDrafter` select between hosted and local adapters behind one small seam. Keep the public draft endpoint contract unchanged by normalizing the local response down to the existing unified-diff string and routing malformed/unreachable provider failures into the existing unavailable path. Limit config work to the smallest explicit diagnostics needed to show whether the selected drafter provider is actually runnable.

## Steps (agent-executable)
1. Inspect current draft-patch route wiring, `WorkflowPatchDrafter`, runtime config, and existing local planner client patterns to identify the narrowest provider-selection extension point.
2. Add local drafter provider config/diagnostic support and extend draft-provider normalization to accept `local` without introducing route-branching.
3. Introduce a minimal local workflow patch client/adapter that targets the `local_llm` OpenAI-compatible draft baseline and maps malformed/unreachable responses to the existing unavailable path.
4. Keep `/mcp/workflow/draft_patch` request and response contracts unchanged while updating service construction to build the correct draft client through one bounded seam.
5. Add focused service/request/runtime-config specs for local-provider success and unavailable/malformed failure behavior.
6. Update README/config guidance only enough to describe the local drafter provider option, base URL dependency, and remaining boundary limits.

## Risks / Tech debt / Refactor signals
- Risk: draft-provider selection could spread into routes or endpoint helpers. -> Mitigation: keep provider choice inside runtime config and drafter/client construction, parallel to the planner seam.
- Risk: the local draft adapter could overfit current Ollama wording and accidentally redefine the public draft contract. -> Mitigation: validate only the bounded unified-diff output shape already exercised by `local_llm` smoke coverage.
- Debt: planner and drafter may still share coarse workflow runtime settings after this slice.
- Refactor suggestion (if any): if planner and drafter providers diverge further, introduce a dedicated workflow client factory or typed workflow runtime-config object instead of duplicating provider selection rules.

## Notes / Open questions
- Assumption: the first local drafter handoff should reuse the current `MCP_LOCAL_WORKFLOW_BASE_URL` boundary rather than introduce a second local workflow host setting.
- Assumption: deterministic `workflow patch drafter is unavailable` behavior remains sufficient for this slice; richer provider diagnostics can stay in `/config` and later hardening work.
