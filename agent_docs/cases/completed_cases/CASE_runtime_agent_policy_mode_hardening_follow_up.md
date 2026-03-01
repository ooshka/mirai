---
case_id: CASE_runtime_agent_policy_mode_hardening_follow_up
created: 2026-03-01
---

# CASE: Runtime-Agent Policy Mode Hardening Follow-up

## Goal
Improve operator-facing policy mode diagnostics and startup-time validation so misconfiguration is surfaced early without changing MCP endpoint contracts.

## Why this next
- Value: reduces avoidable runtime surprises by making policy mode behavior explicit at boot and in config visibility.
- Dependency/Risk: derisks upcoming runtime-agent autonomy work by tightening safety control ergonomics before new action surfaces are added.
- Tech debt note: pays down configuration/observability debt left after initial action-policy layer delivery.

## Definition of Done
- [ ] Policy mode parsing is centralized so startup validation and runtime enforcement use one deterministic source of truth.
- [ ] Invalid `MCP_POLICY_MODE` can be detected at startup with a clear failure/diagnostic path (rather than only surfacing at request time).
- [ ] `GET /config` exposes policy mode diagnostics suitable for operators (active mode and allowed values) without leaking secrets.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_action_policy_spec.rb spec/mcp_notes_spec.rb spec/mcp_patch_spec.rb spec/mcp_index_spec.rb`

## Scope
**In**
- Add a small policy mode config/diagnostic seam in `app/services/mcp/` that can validate and report supported modes.
- Wire app boot/config reporting to that seam while preserving existing route behavior and error codes for request-time enforcement.
- Update/extend request and service specs for startup validation path and config endpoint diagnostics.

**Out**
- Identity-aware policy controls, API authn/authz, or per-endpoint role systems.
- New policy modes beyond `allow_all` and `read_only`.

## Proposed approach
Extract mode normalization/allowed-mode metadata from `Mcp::ActionPolicy` into a focused config helper (or class method seam) used by both app boot and helper policy initialization. Validate `settings.mcp_policy_mode` during app configuration so invalid values fail clearly before traffic. Extend `GET /config` response to include stable policy diagnostics (`mcp_policy_mode`, `mcp_policy_modes_supported`) while keeping existing `notes_root` behavior intact. Keep deny behavior for `read_only` unchanged and continue mapping invalid modes through existing error contract paths where runtime checks still apply.

## Steps (agent-executable)
1. Introduce a policy-mode configuration seam in `app/services/mcp/` that exposes normalization + supported modes.
2. Update app configuration/boot path to validate `MCP_POLICY_MODE` deterministically using that seam.
3. Extend `/config` route payload with policy mode diagnostics and align README docs to the new visibility.
4. Add/adjust specs covering boot/config diagnostics and regression-check existing deny/invalid-mode contracts.
5. Run targeted MCP/policy specs and iterate until behavior is deterministic.

## Risks / Tech debt / Refactor signals
- Risk: strict startup validation could break misconfigured local environments unexpectedly. -> Mitigation: keep default mode `allow_all`, provide explicit error text, and document valid values in README.
- Debt: introducing config diagnostics adds a small maintenance surface that must stay aligned with policy service constants.
- Refactor suggestion (if any): if runtime settings grow beyond policy/retrieval modes, consolidate environment parsing into a single typed app-config object.

## Notes / Open questions
- Assumption: exposing supported policy mode names in `/config` is acceptable because values are non-secret operational metadata.
