---
case_id: CASE_case-runtime-agent-policy-mode-hardening-follow-up-config-policy-mode-spec-env-coupling-must-fix
created: 2026-03-01
---

# CASE: Decouple Config Policy Mode Spec From Environment Defaults (Must Fix)

## Goal
Make `/config` policy mode assertions deterministic in test runs regardless of external `MCP_POLICY_MODE` environment settings.

## Why this next
- Value: prevents false-negative test failures in CI/local runs when environment defaults differ from `allow_all`.
- Dependency/Risk: required to close review finding before merge of the policy-mode hardening case.
- Tech debt note: pays down brittle test coupling to process-level environment state.

## Definition of Done
- [ ] The `/config` response spec no longer hardcodes `allow_all` as the active mode expectation.
- [ ] Spec expectation derives from explicit test setup or app settings so behavior is stable across environments.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/health_spec.rb spec/mcp_notes_spec.rb`

## Scope
**In**
- Update assertions in `spec/health_spec.rb` for `mcp_policy_mode` to remove environment-coupled default assumptions.
- Add minimal setup/reset in the spec if needed to keep test isolation explicit.

**Out**
- Any changes to production policy enforcement logic, mode parsing, or `/config` response schema.

## Proposed approach
Adjust the `/config` spec to assert against `App.settings.mcp_policy_mode` (or a value explicitly set within the example) instead of `Mcp::ActionPolicy::MODE_ALLOW_ALL`. Keep the test focused on contract shape and setting reflection, not global default assumptions. If explicit setup is used, ensure settings are restored after the example to avoid cross-test leakage. Run the focused health spec and one MCP request spec to confirm no side effects.

## Steps (agent-executable)
1. Edit `spec/health_spec.rb` to replace hardcoded mode expectation with a deterministic source (`App.settings.mcp_policy_mode` or explicit setup).
2. If introducing test-local setting overrides, add setup/teardown to restore original settings.
3. Run `docker compose run --rm dev bundle exec rspec spec/health_spec.rb`.
4. Run `docker compose run --rm dev bundle exec rspec spec/mcp_notes_spec.rb` as regression coverage for mode-related request behavior.

## Risks / Tech debt / Refactor signals
- Risk: setting overrides in one example can leak and affect other specs. → Mitigation: capture original setting and restore in ensure/after block.
- Debt: small amount of repeated settings setup may remain in request specs until shared test helpers are introduced.
- Refactor suggestion (if any): if more config endpoint assertions are added, consider a small shared helper for stable app-setting expectations.

## Notes / Open questions
- Assumption: `/config` should reflect current app settings exactly, not a fixed compile-time default.
