# Current Sprint

## Active Case
No active case.

## Sprint Goal
Eliminate stale index reuse immediately after note mutations:
- invalidate persisted index artifact on successful patch apply
- preserve existing `/mcp/patch/apply` response and error contracts
- ensure failed patch apply paths do not invalidate existing artifacts
