# Current Sprint

## Active Case
`agent_docs/cases/CASE_semantic_retrieval_runtime_integration.md`

## Sprint Goal
Integrate semantic retrieval behind the existing query contract:
- preserve current `/mcp/index/query` response shape while adding provider-backed ranking path
- keep lexical retrieval as deterministic fallback when semantic mode is unavailable
- maintain provider portability by isolating retrieval-mode selection in service wiring
