---
case_id: CASE_retrieval_query_path_prefix_filter
created: 2026-03-03
---

# CASE: Retrieval Query Path Prefix Filter

## Slice metadata
- Type: feature
- User Value: agents and operators can constrain retrieval to a relevant notes subtree, improving precision and reducing noisy results.
- Why Now: retrieval contracts are stable and this adds user-visible capability without reopening recent policy hardening seams.
- Risk if Deferred: feature delivery remains skewed toward internal hardening and query consumers continue implementing brittle client-side filtering.

## Goal
Add an optional `path_prefix` query parameter to `GET /mcp/index/query` so retrieval can be scoped to matching note paths while preserving existing default behavior.

## Why this next
- Value: improves retrieval relevance in multi-folder note repositories and reduces downstream filtering complexity.
- Dependency/Risk: builds directly on existing deterministic lexical/semantic query contracts with bounded blast radius.
- Tech debt note: introduces one more query option; keep parsing/validation scoped and explicit to avoid option sprawl.

## Definition of Done
- [ ] `GET /mcp/index/query` accepts optional `path_prefix` and filters candidates to note paths that start with the given prefix.
- [ ] Omitted `path_prefix` preserves current response behavior and ordering.
- [ ] Invalid `path_prefix` values (absolute path, traversal, non-string) return deterministic `invalid_query` style errors.
- [ ] README endpoint docs include the new optional parameter and behavior notes.
- [ ] Tests/verification: `bundle exec rspec spec/requests/mcp_index_query_spec.rb spec/services/notes_retriever_spec.rb`

## Scope
**In**
- Request parsing/validation updates for optional `path_prefix` in query endpoint.
- Retrieval service/provider filtering of candidate chunks by `path_prefix`.
- Request and service spec coverage for default + filtered + invalid-path-prefix contracts.
- README contract updates for query parameter documentation.

**Out**
- Arbitrary include/exclude glob filtering.
- Ranking algorithm changes unrelated to path scoping.
- New indexing artifact schema fields.

## Proposed approach
Add `path_prefix` as an optional query option, normalize it once at request boundary, and pass it into retrieval orchestration. Apply filtering before scoring to preserve deterministic ranking semantics over the scoped subset. Reuse existing safe-path validation primitives (or equivalent policy) to reject unsafe prefixes. Keep query contract backward compatible by leaving default behavior unchanged when `path_prefix` is absent.

## Steps (agent-executable)
1. Extend query request handling to parse optional `path_prefix` and validate shape/safety constraints.
2. Thread normalized `path_prefix` through retrieval call chain with default `nil`.
3. Filter retrieval candidates by path prefix before scoring/ranking.
4. Add request specs for: no prefix (parity), valid prefix, and invalid prefix contracts.
5. Add/adjust service specs to cover scoped candidate selection behavior.
6. Update README query endpoint docs to include `path_prefix`.
7. Run targeted specs and ensure deterministic ordering remains stable.

## Risks / Tech debt / Refactor signals
- Risk: prefix normalization differences (trailing slashes, empty strings) could create confusing behavior. -> Mitigation: codify explicit normalization + tests for representative edge cases.
- Debt: query option surface grows by one parameter; keep ownership at request boundary to avoid retriever parsing drift.
- Refactor suggestion (if any): if query options expand further, introduce a dedicated query options object for typed parsing and validation.

## Notes / Open questions
- Assumption: prefix semantics are simple "starts with normalized relative path", not glob or regex matching.
