---
case_id: CASE_runtime_config_mode_contract_hardening
created: 2026-03-01
---

# CASE: Runtime Config Mode Contract Hardening

## Goal
Make runtime mode configuration explicit and fail-fast so operators can detect invalid policy/retrieval settings before serving MCP traffic.

## Why this next
- Value: reduces silent misconfiguration risk for `MCP_POLICY_MODE` and retrieval mode wiring.
- Dependency/Risk: creates a stable config seam needed before adding identity-aware policy controls.
- Tech debt note: pays down scattered env parsing debt in `App` and retrieval provider wiring.

## Definition of Done
- [ ] App startup validates and normalizes runtime modes through one shared config boundary.
- [ ] `GET /config` exposes retrieval-mode diagnostics alongside existing policy diagnostics.
- [ ] Invalid runtime mode inputs fail with deterministic boot errors instead of silent fallback.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- Introduce a focused app-config service/object for runtime mode parsing/validation.
- Wire `App` boot/config endpoint and retrieval provider factory consumers to the shared config contract.
- Add request/service specs covering valid and invalid policy/retrieval mode scenarios.

**Out**
- Identity-aware authorization or authentication.
- Semantic provider scoring/ranking behavior changes.
- Any MCP endpoint contract change outside `/config` diagnostics.

## Proposed approach
Add a small `AppConfig` (or similarly named) service that reads env/config, normalizes supported modes, and raises typed errors for invalid values. Use it during Sinatra boot so mode errors fail startup consistently. Reuse this config object in retrieval provider selection instead of ad hoc normalization defaults. Extend `/config` to include retrieval mode and supported retrieval modes for operator visibility. Keep existing MCP action/query behaviors unchanged except for stricter invalid-mode handling. Cover boot policy mode, retrieval mode normalization, and `/config` payload additions with focused specs.

## Steps (agent-executable)
1. Add a runtime config service that owns policy/retrieval mode constants, normalization, and invalid-mode errors.
2. Update `app.rb` startup wiring to consume the runtime config service instead of direct env parsing.
3. Update retrieval provider factory wiring to use validated retrieval mode from runtime config.
4. Extend `GET /config` response with retrieval mode diagnostics and supported values.
5. Add/adjust specs for startup validation, retrieval mode validation behavior, and `/config` payload shape.
6. Run full RSpec suite and adjust only for intentional contract changes.

## Risks / Tech debt / Refactor signals
- Risk: stricter retrieval mode validation may break existing environments relying on silent lexical fallback. -> Mitigation: document supported values and return explicit startup error text.
- Debt: pays down duplicated mode parsing and scattered env access logic.
- Refactor suggestion (if any): if more env-controlled runtime toggles are introduced, extend this config service rather than adding route/service-local parsing.

## Notes / Open questions
- Assumption: changing invalid retrieval mode from silent fallback to startup failure is acceptable for this phase.
