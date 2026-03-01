# Current Sprint

## Active Case
`agent_docs/cases/CASE_runtime_agent_policy_mode_hardening_follow_up.md`

## Sprint Goal
Harden policy mode operator ergonomics after action-policy rollout:
- add one deterministic policy-mode config seam used by both boot-time validation and runtime enforcement
- surface policy mode diagnostics in `/config` for easier local/staging troubleshooting
- preserve existing deny and invalid-mode MCP request contracts while tightening startup behavior
