---
case_id: CASE_case-retrieval-query-contract-default-limit-request-spec-must-fix
created: 2026-02-27
---

# CASE: Add Request Spec For Default Retrieval Limit

## Goal
Add request-level coverage proving `/mcp/index/query` uses the default limit when `limit` is omitted.

## Why this next
- Value: locks down the public retrieval contract so clients can rely on stable default paging behavior.
- Dependency/Risk: prevents accidental regressions if validation or endpoint wiring changes later.
- Tech debt note: pays down a coverage gap identified during review without expanding retrieval scope.

## Definition of Done
- [ ] A request spec verifies `GET /mcp/index/query?q=...` (without `limit`) returns `"limit": 5`.
- [ ] The same spec verifies returned `chunks` are capped at 5 for matching data.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb`

## Scope
**In**
- Add one focused endpoint spec in `spec/mcp_index_query_spec.rb` for omitted `limit` behavior.
- Keep fixture setup deterministic and consistent with existing MCP query specs.

**Out**
- Any ranking algorithm changes or retrieval service refactors.
- Any endpoint contract changes beyond default-limit coverage.

## Proposed approach
Extend `spec/mcp_index_query_spec.rb` with a new example that seeds more than 5 matching chunks across markdown notes, calls the endpoint with only `q`, and asserts the response includes `"limit" => 5` and exactly 5 ranked chunks. Reuse current temporary notes-root setup and existing JSON assertion style for consistency. Avoid touching app/service code unless the test reveals a real mismatch.

## Steps (agent-executable)
1. Add a new request example in `spec/mcp_index_query_spec.rb` for query without `limit`.
2. Seed deterministic matching note content producing more than 5 result candidates.
3. Assert response status, `limit` value of `5`, and `chunks.length == 5`.
4. Run `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb` and ensure green.

## Risks / Tech debt / Refactor signals
- Risk: test data may accidentally produce fewer than 5 matches and give false confidence. -> Mitigation: create explicit fixtures with clear token overlap for >5 candidates.
- Debt: minimal; this closes test debt rather than introducing new debt.
- Refactor suggestion (if any): if pagination behavior evolves, centralize response contract assertions with shared examples.

## Notes / Open questions
- Assumption: default retrieval limit remains `5` as defined by `NotesRetriever::DEFAULT_LIMIT`.
