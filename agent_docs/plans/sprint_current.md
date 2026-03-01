# Current Sprint

## Active Case
No active case.

## Sprint Goal
Make index staleness observable before lifecycle automation:
- add deterministic stale/fresh signal to `/mcp/index/status`
- preserve existing rebuild/query behavior and error contracts
- keep lifecycle controls explicit (no query-time rebuild side effects)
