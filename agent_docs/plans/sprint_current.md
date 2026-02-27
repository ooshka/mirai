# Current Sprint

## Active Case
- `agent_docs/cases/CASE_retrieval_query_contract.md`

## Sprint Goal
Deliver first retrieval-path API contract without embedding coupling:
- add deterministic chunk query endpoint with stable rank ordering
- validate query inputs and bounded result size with explicit error contracts
- keep scoring local/simple so semantic retrieval can be introduced later behind the same endpoint surface
