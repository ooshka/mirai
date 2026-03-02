# Current Sprint

## Active Case
`agent_docs/cases/CASE_runtime_config_semantic_flag_contract_hardening.md`

## Sprint Goal
Harden runtime config diagnostics and parsing consistency:
- centralize semantic-provider boolean parsing in one shared contract
- expose effective `mcp_semantic_provider_enabled` state via `/config`
- preserve existing retrieval behavior while reducing config drift risk
