# Current Sprint

## Active Case
`agent_docs/cases/CASE_retrieval_fallback_policy_extraction.md`

## Sprint Goal
Keep retrieval orchestration maintainable while preserving contract stability:
- extract semantic fallback behavior from `NotesRetriever` into one explicit policy seam
- preserve existing lexical fallback behavior for semantic unavailability
- keep `GET /mcp/index/query` request/response contracts unchanged
