---
case_id: CASE_local_semantic_retrieval_adapter_v1
created: 2026-03-14
---

# CASE: Local Semantic Retrieval Adapter V1

## Slice metadata
- Type: feature
- User Value: lets `mirai` recognize a first self-hosted semantic retrieval provider path without changing the `/mcp/index/query` contract, so local-provider integration can begin behind the existing retrieval seam.
- Why Now: `local_llm` now has an explicit retrieval artifact contract, while `mirai` still treats semantic retrieval as effectively OpenAI-only; this is the smallest adapter gap between the two repos.
- Risk if Deferred: follow-on self-hosted work will stay trapped in docs and local experiments, and `mirai`’s retrieval abstraction will continue to hard-code provider assumptions that become more expensive to unwind later.

## Goal
Add the first local semantic retrieval adapter seam in `mirai` so runtime configuration and retrieval-provider wiring can select a self-hosted/local semantic provider path that still emits the existing ranked chunk contract with lexical fallback.

## Why this next
- Value: turns the new `local_llm` retrieval contract into a real `mirai` integration seam instead of a disconnected planning artifact.
- Dependency/Risk: de-risks future self-hosted retrieval by replacing the current OpenAI-only assumption with explicit provider selection at the service/config layer.
- Tech debt note: pays down provider-coupling debt in retrieval wiring without widening into ingestion, reranking, or default-provider policy.

## Definition of Done
- [ ] Runtime config and retrieval provider selection can represent at least `openai` and `local` semantic provider choices without route-layer branching.
- [ ] A new local semantic retrieval client/adapter seam exists behind the current semantic provider interface and expects ranked chunk records aligned with the `local_llm` retrieval artifact contract.
- [ ] `/mcp/index/query` response shape remains unchanged, and lexical fallback remains the deterministic fallback path when the local provider is disabled, unavailable, or misconfigured.
- [ ] Targeted specs cover provider selection, local-adapter normalization/failure mapping, and one request- or service-level fallback path.
- [ ] Docs/config surfaces mention the new provider option and any required local adapter configuration at a high level.

## Scope
**In**
- Extend retrieval runtime/provider selection from OpenAI-only semantic wiring to provider-aware semantic wiring.
- Add a minimal local semantic client/adapter seam that consumes ranked chunk objects compatible with the `local_llm` contract.
- Keep `/mcp/index/query` request and response contracts unchanged.
- Add focused tests and lightweight config/docs updates for the new provider option.

**Out**
- End-to-end local retrieval service implementation in `local_llm`.
- Re-embedding/ingestion support for the local provider.
- Planner/patch-drafting local provider work.
- Changing defaults from lexical/OpenAI to local.

## Proposed approach
Keep the current retrieval architecture intact: `IndexQueryAction` -> `NotesRetriever` -> `RetrievalProviderFactory` -> semantic provider. The narrow change is to stop treating “semantic” as synonymous with OpenAI. Introduce a provider-aware local semantic client seam that normalizes ranked chunk objects shaped like the `local_llm` contract, then let `RetrievalProviderFactory` choose between OpenAI and local semantic adapters while preserving lexical fallback. Keep runtime config explicit and additive: `MCP_SEMANTIC_PROVIDER=openai|local` with provider-specific config exposed only as non-secret diagnostics where appropriate.

## Steps (agent-executable)
1. Inspect current retrieval runtime config, provider factory wiring, and semantic provider tests to identify the narrowest provider-selection extension point.
2. Add provider-aware retrieval semantic wiring so `MCP_SEMANTIC_PROVIDER` can select `local` in addition to `openai`.
3. Introduce a minimal local semantic client/adapter seam that requests or accepts ranked chunk objects matching the `local_llm` retrieval artifact contract and maps malformed/unavailable results to the existing semantic-unavailable path.
4. Keep lexical fallback behavior unchanged and verify that `/mcp/index/query` continues to return the same envelope and chunk fields.
5. Add targeted specs for runtime config/provider selection plus local-adapter normalization and failure/fallback behavior.
6. Update README/config guidance only enough to document the new provider option and the expected local adapter contract/config surface.
7. Record any follow-on gaps for local ingestion, parity fixtures, or richer telemetry in planning artifacts without widening this Case.

## Risks / Tech debt / Refactor signals
- Risk: provider selection could leak OpenAI-vs-local branching into route or action layers. -> Mitigation: keep provider choice inside runtime config and `RetrievalProviderFactory`.
- Risk: the local adapter could over-assume a final local service API before `local_llm` implementation exists. -> Mitigation: bind only to the ranked chunk artifact contract already documented, not to richer transport details.
- Debt: this slice leaves local ingestion and operational hardening unresolved.
- Refactor suggestion (if any): if semantic provider variants keep growing, extract an explicit semantic-provider registry/selector instead of expanding a single factory initializer.

## Notes / Open questions
- Assumption: the first local adapter should target retrieval only; workflow-planner local provider work stays separate.
- Assumption: the local provider should be opt-in and non-default until parity evidence is stronger.
