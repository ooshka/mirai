# Backlog

## Next 3 Candidate Slices

1. Runtime Config Surface Parity + Boolean Parsing Contract (selected)
- Value: reduces config drift by centralizing boolean env parsing and exposing effective semantic-provider state in `/config` diagnostics.
- Active case: `agent_docs/cases/CASE_runtime_config_semantic_flag_contract_hardening.md`
- Scope cue: unify truthy parsing ownership and add deterministic config visibility for `MCP_SEMANTIC_PROVIDER_ENABLED`.
- Size: ~0.5-1 day.

2. Runtime-Agent Policy Identity Extension Seam
- Value: prepares policy architecture for future identity-aware controls once mode config contracts are stable.
- Size: ~1 day.

3. Retrieval Fallback Policy Extraction
- Value: keeps retrieval orchestration small if semantic/lexical fallback rules continue to expand.
- Size: ~0.5-1 day.

## Additional queued slices

1. Retrieval Storage Lifecycle Controls (Phase 2)
- Value: introduces bounded retention/cleanup controls after lifecycle telemetry/status contracts are fully stabilized.
- Size: ~1-2 days.
