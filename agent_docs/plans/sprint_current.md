# Current Sprint

## Active Case
`agent_docs/cases/CASE_patch_index_concurrency_guardrails.md`

## Sprint Goal
Harden runtime mutation/index lifecycle determinism under concurrent traffic:
- serialize patch apply + index lifecycle mutations through one bounded lock seam
- prevent stale index artifact windows during concurrent patch/rebuild/invalidate operations
- preserve existing MCP response/error contracts while adding concurrency coverage
