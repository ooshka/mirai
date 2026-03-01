# Current Sprint

## Active Case
`agent_docs/cases/CASE_semantic_retrieval_provider_seam.md`

## Sprint Goal
Establish a retrieval provider seam before semantic adapter work:
- introduce a provider-facing retrieval boundary in service layer
- keep lexical retrieval as deterministic default implementation
- preserve `/mcp/index/query` request/response contract unchanged
