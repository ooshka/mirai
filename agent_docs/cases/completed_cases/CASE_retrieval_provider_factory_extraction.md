---
case_id: CASE_retrieval_provider_factory_extraction
created: 2026-03-01
---

# CASE: Retrieval Provider Factory Extraction

## Goal
Extract retrieval provider mode/config selection from `NotesRetriever` into a small factory so retrieval orchestration stays simple as provider options grow.

## Why this next
- Value: keeps retrieval behavior easier to reason about while preserving current semantic/lexical contract behavior.
- Dependency/Risk: derisks future provider additions (real semantic adapters, hybrid modes) by centralizing mode parsing and fallback wiring.
- Tech debt note: pays down complexity introduced by environment-driven provider selection inside `NotesRetriever`.

## Definition of Done
- [ ] A dedicated retrieval provider factory (or selector object) owns mode parsing and provider construction.
- [ ] `NotesRetriever` no longer owns env-driven mode/config parsing beyond consuming a resolved provider setup.
- [ ] Semantic unavailable fallback behavior remains deterministic and unchanged.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/notes_retriever_spec.rb spec/mcp_index_query_spec.rb spec/mcp_error_mapper_spec.rb`

## Scope
**In**
- Add a small service under `app/services/` for retrieval provider selection/construction.
- Update `NotesRetriever` to depend on the factory output rather than inline mode/env parsing.
- Add/adjust specs around provider selection behavior and fallback parity.

**Out**
- New retrieval modes, endpoint contract changes, or vector/embedding infra expansion.
- Route-level config branching for retrieval behavior.

## Proposed approach
Create a focused `RetrievalProviderFactory` that accepts mode/config input (`MCP_RETRIEVAL_MODE`, semantic enabled flag) and returns lexical + primary provider wiring. Keep fallback behavior inside `NotesRetriever#query` or in a tiny wrapper if cleaner, but ensure mode parsing is removed from retriever. Update tests so mode normalization and provider selection are covered at factory/unit level while existing request specs confirm unchanged `/mcp/index/query` contracts.

## Steps (agent-executable)
1. Add retrieval provider factory service with explicit mode normalization and provider construction.
2. Refactor `NotesRetriever` initialization to use factory output and remove direct env parsing logic.
3. Add/adjust unit specs for factory selection and retriever fallback parity.
4. Run targeted query/retriever/error specs and fix only wiring/selection regressions.

## Risks / Tech debt / Refactor signals
- Risk: factory extraction could accidentally change default mode behavior. → Mitigation: preserve lexical default and assert with focused tests.
- Debt: semantic adapter remains intentionally minimal after extraction.
- Refactor suggestion (if any): if provider policy keeps growing, promote factory config into an immutable retrieval policy object.

## Notes / Open questions
- Assumption: lexical remains the default mode when retrieval mode is missing or unknown.
