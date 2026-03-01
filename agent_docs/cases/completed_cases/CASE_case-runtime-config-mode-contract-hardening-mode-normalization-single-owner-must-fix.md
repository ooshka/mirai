---
case_id: CASE_case-runtime-config-mode-contract-hardening-mode-normalization-single-owner-must-fix
created: 2026-03-01
---

# CASE: Retrieval Mode Normalization Single Owner (Must Fix)

## Goal
Ensure retrieval mode normalization and supported-mode metadata are owned by one dedicated contract instead of being coupled to provider factory implementation details.

## Why this next
- Value: removes fragile load-order coupling and keeps mode semantics stable across boot/config and retrieval execution paths.
- Dependency/Risk: unblocks safe reuse of mode diagnostics without requiring provider-factory loading side effects.
- Tech debt note: pays down boundary drift where config behavior depends on service-construction classes.

## Definition of Done
- [ ] Retrieval mode constants/normalization are defined in one dedicated runtime-mode contract.
- [ ] `RuntimeConfig`, `/config` diagnostics, and `RetrievalProviderFactory` all consume that shared contract.
- [ ] Existing behavior remains: blank retrieval mode defaults to lexical, unknown mode fails fast with deterministic error text.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- Introduce a dedicated retrieval-mode contract module/class for mode constants + normalization.
- Rewire runtime config parsing and config diagnostics to use that contract directly.
- Keep provider factory focused on provider construction while delegating mode validation to the shared contract.

**Out**
- Any changes to retrieval ranking behavior or fallback strategy.
- Policy-mode semantics or action policy behavior.

## Proposed approach
Create a small retrieval-mode contract under MCP service namespace that exposes `supported_modes` and strict `normalize_mode!` behavior with the existing invalid-mode error message. Update `RuntimeConfig` to depend on this contract instead of `RetrievalProviderFactory`. Update `/config` route diagnostics and related specs to reference the new contract so diagnostics no longer depend on provider-factory load order. Keep backward compatibility in `RetrievalProviderFactory` by delegating mode operations to the shared contract.

## Steps (agent-executable)
1. Add a retrieval-mode contract module/class with constants, `supported_modes`, and strict normalization.
2. Update `RuntimeConfig` to consume the retrieval-mode contract for mode parsing.
3. Update `/config` diagnostics and associated specs to read supported retrieval modes from the retrieval-mode contract.
4. Update `RetrievalProviderFactory` to delegate mode validation/constants to the shared contract.
5. Run targeted specs, then full RSpec.

## Risks / Tech debt / Refactor signals
- Risk: changing constant ownership can break specs or callers expecting factory-owned constants. → Mitigation: keep compatibility aliases/delegators in factory.
- Debt: pays down hidden coupling between config diagnostics and provider factory internals.
- Refactor suggestion (if any): if more mode-driven runtime toggles appear, group them under a shared runtime-mode contract namespace.

## Notes / Open questions
- Assumption: retaining current error message text (`invalid MCP retrieval mode: <value>`) is required for compatibility.
