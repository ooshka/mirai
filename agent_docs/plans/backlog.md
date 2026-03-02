# Backlog

## Next 3 Candidate Slices

1. ActionPolicy Identity Context Explicit Contract
- Value: removes ambiguity in a core policy seam and derisks future identity-aware authorization work.
- Scope cue: clarify identity-context ownership in `Mcp::ActionPolicy` while preserving allow/deny behavior.
- Size: ~0.5 day.

2. Policy Action Inventory Centralization
- Value: keeps action constants and read-only allowlist ownership explicit as MCP endpoints continue to grow.
- Scope cue: reduce policy drift risk by codifying a single action inventory contract in policy specs.
- Size: ~0.5 day.

3. MCP Helper-Level Policy Wiring Contract Hardening
- Value: strengthens route-helper policy plumbing confidence without expanding runtime behavior.
- Scope cue: add focused request-level assertions that each guarded endpoint maps to the intended policy action.
- Size: ~0.5-1 day.

## Additional queued slices

1. Runtime Config Surface Parity + Boolean Parsing Contract (follow-up only)
- Value: reopen only if semantic config diagnostics/parsing regress after retrieval policy refactors.
- Size: ~0.5 day, conditional.

2. Planning Artifact Hygiene: reconcile superseded open Cases
- Value: reduces planner/implementor confusion by closing or archiving stale Cases whose intent is already satisfied.
- Size: ~0.5 day.
