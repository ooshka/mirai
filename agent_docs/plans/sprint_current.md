# Current Sprint

## Active Case
`agent_docs/cases/CASE_index_auto_invalidation_on_patch_apply.md`

## Sprint Goal
Eliminate stale index reuse immediately after note mutations:
- invalidate persisted index artifact on successful patch apply
- preserve existing `/mcp/patch/apply` response and error contracts
- ensure failed patch apply paths do not invalidate existing artifacts
