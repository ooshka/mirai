---
case_id: CASE_patch_parser_boundary_extraction
created: 2026-03-01
---

# CASE: Patch Parser Boundary Extraction

## Goal
Extract unified-diff syntax parsing into a dedicated service so patch policy decisions remain explicit, testable, and easier to evolve safely.

## Why this next
- Value: reduces mutation-path fragility by separating diff syntax concerns from validation policy and apply behavior.
- Dependency/Risk: de-risks future patch grammar growth by creating a stable parser seam before adding new diff features.
- Tech debt note: pays down coupling debt in `PatchValidator`; intentionally keeps single-file markdown-only mutation boundaries.

## Definition of Done
- [ ] A dedicated patch parser service returns structured, validated diff components currently required by `PatchValidator`.
- [ ] `PatchValidator` consumes parser output and remains the owner of safety policy decisions and path validation.
- [ ] Existing MCP patch propose/apply behavior and error mapping remain unchanged for current supported diff inputs.
- [ ] Targeted specs cover parser contracts and validator integration paths (valid, malformed header, malformed hunk, unsupported metadata).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/patch_validator_spec.rb spec/patch_applier_spec.rb spec/mcp_patch_spec.rb`

## Scope
**In**
- Introduce a minimal parser object for unified-diff structure extraction used by current single-file patch flow.
- Refactor `PatchValidator` to delegate syntax parsing while preserving current policy/error contracts.
- Add focused specs for parser and validator integration to prevent behavior drift.

**Out**
- Multi-file patch support.
- New-file/delete/rename patch support.
- Changes to patch apply commit semantics or MCP route shape.

## Proposed approach
Create a small `PatchParser` service that performs deterministic extraction of file header and hunks for the currently supported unified-diff subset. Keep semantic guardrails in `PatchValidator` (path safety, single-file restriction, supported markers, and count checks) so the parser remains a syntax utility, not a policy engine. Refactor `PatchValidator` in place to call parser methods and translate parser failures into existing `InvalidPatchError` messages where possible. Add parser-focused unit coverage and regression checks on validator/request specs to keep endpoint-visible behavior stable. Avoid changing `PatchApplier` logic except where adapter shape alignment is required.

## Steps (agent-executable)
1. Add `app/services/patch_parser.rb` with minimal deterministic parsing for current unified-diff header/hunk shapes.
2. Add parser error class(es) and failure modes for invalid header/hunk structure.
3. Refactor `PatchValidator` to consume parser output and preserve existing patch policy checks.
4. Add `spec/patch_parser_spec.rb` for valid/invalid parse contracts.
5. Update `spec/patch_validator_spec.rb` only where necessary to align with delegated parsing.
6. Run targeted patch-related specs and ensure no MCP patch contract regressions.
7. Update docs only if visible API/error contracts changed.

## Risks / Tech debt / Refactor signals
- Risk: parser/validator responsibility drift could weaken safety checks. -> Mitigation: keep policy checks explicitly in validator and lock with regression specs.
- Risk: changing error text can break endpoint contract assertions. -> Mitigation: preserve existing error messages for covered malformed inputs.
- Debt: parser still only supports narrow diff grammar by design.
- Refactor suggestion (if any): if grammar expansion continues, introduce parser fixtures for real-world diff corpus to reduce ad hoc rule growth.

## Notes / Open questions
- Assumption: preserving current error payload codes/messages is a hard compatibility requirement for MCP patch endpoints.
