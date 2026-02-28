# Current Sprint

## Active Case
- `CASE_retrieval_scoring_strategy_seam`

## Sprint Goal
Establish a retrieval scoring policy seam before semantic retrieval work:
- isolate lexical scoring behind a small strategy boundary
- preserve deterministic MCP `/mcp/index/query` response ordering and limits
- reduce retriever complexity growth as scoring variants are introduced
