---
case_id: CASE_semantic_retrieval_provider_seam
created: 2026-03-01
---

# CASE: Semantic Retrieval Provider Seam

## Goal
Introduce a retrieval provider abstraction seam so semantic retrieval can be added later without changing the MCP query contract.

## Why this next
- Value: creates a stable integration boundary before embedding/vector work, reducing future rewrite risk in retrieval paths.
- Dependency/Risk: de-risks provider portability goals by avoiding direct coupling between endpoint actions and a specific embedding backend.
- Tech debt note: pays down abstraction debt around retrieval internals while intentionally keeping lexical retrieval as the active default.

## Definition of Done
- [ ] A provider-facing retrieval interface (or equivalent strategy seam) exists and is used by retrieval orchestration code.
- [ ] Current lexical retrieval behavior and MCP `/mcp/index/query` response contract remain unchanged.
- [ ] At least one no-op or lexical-backed adapter is wired as the default implementation to preserve deterministic behavior.
- [ ] Tests cover seam wiring and contract preservation at service and request levels.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/notes_retriever_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Add a minimal retrieval-provider boundary in the current retrieval service layer.
- Keep lexical scoring path as default behavior behind the new seam.
- Add focused tests that prove query behavior is unchanged while seam wiring is exercised.

**Out**
- Real embedding provider integration.
- Vector database integration.
- MCP API shape changes for index query.

## Proposed approach
Introduce a small retrieval provider interface in `app/services` that takes query text and candidate chunks, returning scored/ranked chunks in current contract shape. Refactor `NotesRetriever` to depend on this provider boundary while defaulting to a lexical implementation that reuses existing scoring behavior. Keep `Mcp::IndexQueryAction` unchanged and avoid route-level conditionals. Add service-level tests for provider injection/default selection and request-level regression checks to ensure endpoint responses remain stable. This keeps the slice small while creating the portability seam needed for future semantic adapters.

## Steps (agent-executable)
1. Define a minimal retrieval provider contract and default lexical provider implementation in `app/services`.
2. Refactor `NotesRetriever` to delegate ranking to the provider while preserving existing chunk loading and limit behavior.
3. Keep `Mcp::IndexQueryAction` contract unchanged and ensure no API payload changes.
4. Add/adjust `spec/notes_retriever_spec.rb` to cover default provider behavior and injected-provider seam usage.
5. Run targeted specs for retrieval service and MCP query endpoint.
6. Update docs only if externally visible query behavior changed.

## Risks / Tech debt / Refactor signals
- Risk: over-generalizing the provider contract too early could add accidental complexity. -> Mitigation: keep interface minimal and shaped by current lexical behavior.
- Risk: seam extraction could alter ranking order subtly. -> Mitigation: preserve existing deterministic ordering specs and add injection regression coverage.
- Debt: semantic quality remains deferred while lexical retrieval stays default.
- Refactor suggestion (if any): if multiple provider modes are introduced, add a small provider selection policy object rather than branching in action classes.

## Notes / Open questions
- Assumption: provider selection remains internal/service-level for this slice and does not require new MCP parameters.
