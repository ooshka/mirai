---
case_id: CASE_openai_semantic_retrieval_adapter_v1
created: 2026-03-07
---

# CASE: OpenAI Semantic Retrieval Adapter V1

## Slice metadata
- Type: feature
- User Value: enables materially better retrieval relevance behind existing MCP contracts without requiring client-side API changes.
- Why Now: roadmap now prioritizes an OpenAI-first model phase; current semantic mode is still a lexical placeholder, so there is no real semantic quality gain yet.
- Risk if Deferred: semantic-mode planning remains theoretical, delaying provider validation and increasing migration risk to self-hosted parity later.

## Goal
Add a real OpenAI-backed semantic retrieval adapter path behind `GET /mcp/index/query` while preserving deterministic lexical fallback and the existing response contract.

## Why this next
- Value: delivers the first concrete step of roadmap Phase 1 (OpenAI-first) with immediate retrieval-quality upside.
- Dependency/Risk: de-risks later self-hosted migration by proving provider boundaries, failure handling, and contract parity now.
- Tech debt note: intentionally limits scope to retrieval; LLM-driven update/management flows are deferred to a follow-on feature case.

## Definition of Done
- [ ] Semantic mode uses an OpenAI-backed retrieval adapter (embedding + vector search path) instead of lexical-placeholder behavior.
- [ ] Missing/invalid OpenAI config or provider unavailability deterministically falls back to lexical retrieval with unchanged endpoint payload shape.
- [ ] Runtime config and `/config` diagnostics expose effective semantic provider configuration needed for operator verification.
- [ ] Request/service specs cover semantic success path, unavailability fallback, and contract parity for `GET /mcp/index/query`.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/semantic_retrieval_provider_spec.rb spec/services/retrieval/retrieval_provider_factory_spec.rb spec/mcp_index_query_spec.rb spec/runtime_config_spec.rb`

## Scope
**In**
- Implement an OpenAI semantic retrieval adapter in the retrieval service layer.
- Add minimal runtime configuration surface for OpenAI retrieval wiring (API key/model/vector store identifiers).
- Preserve existing `lexical|semantic` mode selection and lexical fallback policy contract.
- Add focused test doubles/fixtures so specs do not depend on external network calls.

**Out**
- LLM-driven note-update or notes-management orchestration.
- MCP API payload/schema changes for query endpoint.
- Self-hosted embedding/model integration.

## Proposed approach
Implement a small OpenAI retrieval adapter under the retrieval domain and inject it through `RetrievalProviderFactory` when `MCP_RETRIEVAL_MODE=semantic`. Keep `SemanticRetrievalProvider` as the semantic-mode boundary, but replace placeholder lexical behavior with provider calls through a thin client interface that can be stubbed in tests. Normalize OpenAI config in runtime config surfaces so operators can validate effective mode and key identifiers via `/config` without exposing secrets. Preserve existing query response structure and keep fallback behavior owned by `RetrievalFallbackPolicy` so failures remain deterministic and contract-safe.

## Steps (agent-executable)
1. Add OpenAI semantic retrieval client/adapter services under `app/services/retrieval/` with a narrow interface consumed by `SemanticRetrievalProvider`.
2. Update `SemanticRetrievalProvider` to perform semantic ranking via the OpenAI adapter and raise `UnavailableError` for fallback-eligible provider/config failures.
3. Wire OpenAI adapter creation through `RetrievalProviderFactory` while keeping lexical default and existing fallback policy behavior.
4. Extend runtime config/config endpoint surfaces for non-secret semantic provider diagnostics required to operate the OpenAI path.
5. Add/adjust service specs for semantic provider behavior (success, unavailable, malformed result handling) and factory wiring.
6. Add/adjust request specs to confirm `/mcp/index/query` contract parity in semantic mode and lexical fallback mode.
7. Run targeted retrieval/runtime specs and fix regressions without widening endpoint contracts.

## Risks / Tech debt / Refactor signals
- Risk: provider/network failures may surface as noisy errors instead of deterministic fallback. -> Mitigation: map expected OpenAI/config failures to `UnavailableError` and assert fallback behavior in specs.
- Risk: introducing OpenAI config can create drift between runtime wiring and `/config` diagnostics. -> Mitigation: source semantic config from shared runtime config parsing.
- Debt: this slice introduces provider-specific adapter logic before full cross-provider abstraction for LLM update/management workflows.
- Refactor suggestion (if any): if OpenAI integration adds multiple endpoints/operations, extract a dedicated retrieval provider client interface (`embed`, `search`) with shared error taxonomy.

## Notes / Open questions
- Assumption: managed vector store credentials/IDs are available via environment variables in target environments.
- Assumption: deterministic ordering remains required when semantic scores tie (existing tie-break policy remains in effect).
