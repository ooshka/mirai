# Current Sprint

## Active Case
`agent_docs/cases/CASE_runtime_config_mode_contract_hardening.md`

## Sprint Goal
Harden runtime mode configuration safety and diagnostics:
- centralize `MCP_POLICY_MODE` and retrieval mode parsing under one validated config seam
- fail fast on invalid mode values to prevent silent runtime drift
- extend `/config` with retrieval mode diagnostics while preserving MCP endpoint behavior
