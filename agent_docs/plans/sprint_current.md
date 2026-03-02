# Current Sprint

## Active Case
`agent_docs/cases/CASE_symlink_listing_policy_contract_alignment.md`

## Sprint Goal
Align notes discovery and read safety contracts:
- enforce one deterministic symlink policy across `/mcp/notes` and `/mcp/notes/read`
- prevent listing of paths that violate read-time containment guarantees
- preserve existing endpoint response/error shapes while tightening safety consistency
