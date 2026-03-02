# Backlog

## Next 3 Candidate Slices

1. Runtime-Agent Policy Identity Extension Seam (selected)
- Value: introduces a narrow identity-context policy input so future identity-aware controls do not require route/action rewrites.
- Active case: `agent_docs/cases/CASE_runtime_agent_policy_identity_extension_seam.md`
- Scope cue: add identity context defaults and thread them through policy checks with no behavior change.
- Size: ~0.5-1 day.

2. Retrieval Fallback Policy Extraction
- Value: keeps retrieval orchestration small if semantic/lexical fallback rules continue to expand.
- Size: ~0.5-1 day.

3. Retrieval Storage Lifecycle Controls (Phase 2)
- Value: introduces bounded retention/cleanup controls after lifecycle telemetry/status contracts are fully stabilized.
- Size: ~1-2 days.

## Additional queued slices

1. Runtime Config Surface Parity + Boolean Parsing Contract
- Value: centralizes semantic-flag parsing ownership and keeps `/config` diagnostics aligned.
- Status note: completed as a main slice; only reopen for narrow parity regressions.
- Size: ~0.5 day follow-up if reopened.
