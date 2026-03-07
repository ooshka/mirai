---
case_id: CASE_case-openai-semantic-retrieval-adapter-v1-semantic-candidate-scope-must-fix
created: 2026-03-07
---

# CASE: Semantic Candidate Scope Must Match Local Query Set

## Slice metadata
- Type: hardening
- User Value: prevents semantic mode from returning chunks outside the user-requested query scope and avoids stale/incorrect chunk content in responses.
- Why Now: current feature branch introduces semantic ranking as primary in `semantic` mode; this behavior can leak out-of-scope results immediately.
- Risk if Deferred: semantic query responses can ignore `path_prefix` filtering and may return stale provider content, causing incorrect MCP outputs.

## Goal
Ensure semantic ranking only returns candidates present in the local candidate chunk set and preserves canonical chunk content from local chunks when available.

## Why this next
- Value: restores contract parity between lexical and semantic retrieval paths for scoped queries.
- Dependency/Risk: unblocks safe merge of semantic retrieval feature by removing a correctness regression.
- Tech debt note: keep provider normalization logic simple and deterministic; no broader provider abstraction changes in this slice.

## Definition of Done
- [ ] `SemanticRetrievalProvider` ignores semantic candidates that do not map to an existing local chunk key (`path`, `chunk_index`).
- [ ] For mapped candidates, response `content` is sourced from the local chunk set (canonical) rather than remote provider payload.
- [ ] Semantic mode preserves `path_prefix`-scoped query results (no out-of-scope paths emitted via provider payload).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/retrieval/semantic_retrieval_provider_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- `SemanticRetrievalProvider` normalization logic for candidate acceptance/content source.
- Focused specs proving out-of-scope candidate exclusion and canonical-content behavior.

**Out**
- OpenAI API protocol changes or new endpoints.
- Broader retrieval architecture refactors.
- Timeout/retry policy tuning for network calls.

## Proposed approach
Change semantic candidate normalization to require a matching local fallback chunk entry for each returned candidate key. When a key is missing, drop that candidate from semantic results. For candidates that do match, always source `content` from the local fallback chunk to keep response content aligned with the active notes/index snapshot. Add targeted specs covering (1) candidate exclusion when not present in the local chunk set and (2) content precedence from local chunks even when provider content is present.

## Steps (agent-executable)
1. Update `SemanticRetrievalProvider` candidate normalization to require lookup-hit membership in `chunk_lookup`.
2. Adjust content extraction to prefer local chunk content for matched candidates.
3. Add/adjust provider spec examples for out-of-scope candidate exclusion and canonical-content precedence.
4. Add/adjust request/spec coverage to guard `path_prefix` scope behavior under semantic mode.
5. Run the targeted verification command and fix any regressions.

## Risks / Tech debt / Refactor signals
- Risk: aggressively dropping candidates could reduce semantic recall if local chunk keys are inconsistent. -> Mitigation: keep key format aligned with existing index chunk schema and assert via specs.
- Debt: normalization logic still assumes current chunk-key contract (`path`, `chunk_index`) across providers.
- Refactor suggestion (if any): if provider payload diversity increases, extract candidate-key normalization into a dedicated helper with explicit schema tests.

## Notes / Open questions
- Assumption: local index chunk metadata (`path`, `chunk_index`) is the source of truth for query response scoping.
