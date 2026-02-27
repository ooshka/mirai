---
case_id: CASE_case-patch-proposal-validation-apply-json-payload-shape-must-fix
created: 2026-02-27
---

# CASE: Guard patch endpoints against non-object JSON payloads

## Goal
Ensure `/mcp/patch/propose` and `/mcp/patch/apply` return structured `invalid_patch` errors (HTTP 400) instead of raising server exceptions when request JSON is not an object.

## Why this next
- Value: Prevents avoidable 500s on malformed-but-valid JSON inputs and keeps API error behavior deterministic.
- Dependency/Risk: This is required for safe runtime-agent interaction because payload shape is untrusted input.
- Tech debt note: Pays down input-validation debt in shared request parsing.

## Definition of Done
- [ ] Non-object JSON bodies (for example `[]`, `"text"`, `123`) to both patch endpoints return HTTP 400 with `error.code = invalid_patch`.
- [ ] Existing valid patch behavior remains unchanged for propose/apply.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_patch_spec.rb`

## Scope
**In**
- Request JSON parsing/validation path used by patch endpoints in `app.rb`.
- Endpoint-level request specs for malformed payload-shape coverage.

**Out**
- Changes to patch parsing semantics in `PatchValidator`/`PatchApplier`.
- Any merge/branch orchestration or unrelated endpoint behavior.

## Proposed approach
Harden `parsed_json_body` (or a patch-specific helper) so it accepts only JSON objects and rejects everything else with the existing invalid-patch contract. Keep error mapping centralized to avoid duplicating checks in each route. Add request specs that post non-object JSON payloads to both patch endpoints and assert 400 + `invalid_patch` response body. Re-run patch endpoint specs to confirm no regressions.

## Steps (agent-executable)
1. Update `app.rb` JSON parsing helper to validate payload type is a Hash-like object for patch routes.
2. Ensure non-object payloads map to `render_error(400, "invalid_patch", "patch is required")` (or an intentional equivalent message) without uncaught exceptions.
3. Add/extend `spec/mcp_patch_spec.rb` examples for `[]` and at least one scalar JSON payload on both endpoints.
4. Run `bundle exec rspec spec/mcp_patch_spec.rb` and confirm green.

## Risks / Tech debt / Refactor signals
- Risk: Over-tight parsing could break future endpoints expecting non-object JSON. → Mitigation: keep validation scoped to patch helper/routes only.
- Debt: Current helper name implies generic parsing but has patch-specific semantics.
- Refactor suggestion (if any): split generic JSON parsing from patch-payload extraction to make intent explicit.

## Notes / Open questions
- Assumption: preserving current error message `"patch is required"` is acceptable for payload shape failures to avoid contract churn.
