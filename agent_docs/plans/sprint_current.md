# Current Sprint

## Active Case
`CASE_local_semantic_retrieval_adapter_v1`

Reason:
- `local_llm` is now far enough along to justify the first adapter slice in `mirai`.
- The main seam gap is retrieval provider selection, which is still OpenAI-shaped despite a local retrieval artifact contract now existing.
- This slice is feature-forward, keeps `/mcp/index/query` stable, and opens the first reversible path for self-hosted retrieval.
