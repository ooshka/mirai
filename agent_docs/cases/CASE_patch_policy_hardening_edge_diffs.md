---
case_id: CASE_patch_policy_hardening_edge_diffs
created: 2026-02-28
---

# CASE: Patch Policy Hardening for Edge-Case Diffs

## Goal
Harden patch validation/apply contracts for common unified-diff edge cases so runtime note mutations fail safely and predictably.

## Why this next
- Value: reduces mutation-path regressions by turning ambiguous diff behavior into explicit, test-backed contracts.
- Dependency/Risk: de-risks future runtime-agent autonomy by ensuring patch inputs are consistently accepted or rejected.
- Tech debt note: pays down parser fragility debt while intentionally deferring broader patch format support (renames/new-file patches).

## Definition of Done
- [ ] `PatchValidator` explicitly handles edge-case diff lines we expect in practice (including newline markers) with deterministic outcomes.
- [ ] `PatchApplier` contract remains unchanged for valid diffs and continues to reject conflicts safely.
- [ ] Request and service specs cover accepted/rejected edge-case payloads with stable MCP error mapping.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/patch_validator_spec.rb spec/patch_applier_spec.rb spec/mcp_patch_spec.rb`

## Scope
**In**
- Expand unified-diff validation policy for edge-case hunk content and metadata lines.
- Add focused tests for parser/apply behavior and endpoint-level error contracts.
- Preserve current single-file markdown-only mutation boundary.

**Out**
- Multi-file patch support.
- File creation/deletion/rename patch support.
- Any changes to commit metadata policy.

## Proposed approach
Introduce a narrow policy update in `PatchValidator` for known unified-diff edge markers (notably `\ No newline at end of file`) and any currently ambiguous hunk parsing behavior uncovered by specs. Keep the parser restrictive: only extend behavior where semantics are clear and testable. Ensure `PatchApplier` behavior for accepted patches stays deterministic and conflict-safe. Add request/service specs that assert both acceptance and rejection paths so endpoint error contracts remain stable. Avoid broad parser rewrites; this slice is contract hardening, not feature expansion.

## Steps (agent-executable)
1. Audit current patch validator/apply specs and identify untested edge-case diff forms that are likely in real workflows.
2. Define explicit accept/reject policy for each targeted edge case (with an emphasis on deterministic safety).
3. Update `PatchValidator` parsing logic minimally to enforce the selected policy.
4. Add/adjust `PatchValidator` unit specs for each new edge-case contract.
5. Add/adjust `PatchApplier` and MCP request specs where endpoint-visible behavior changes.
6. Run targeted RSpec commands and capture results.
7. Update docs only if API/error contract text changed.

## Risks / Tech debt / Refactor signals
- Risk: over-broad parser changes could accidentally admit unsafe patch shapes. -> Mitigation: keep policy narrow and spec-driven.
- Risk: edge-case handling drift between validator and applier. -> Mitigation: add paired validator/apply tests for each accepted edge case.
- Debt: full unified-diff compatibility remains intentionally out of scope.
- Refactor suggestion (if any): if patch grammar keeps expanding, extract a dedicated patch parser object to isolate syntax concerns from validation policy.

## Notes / Open questions
- Assumption: preserving strict single-file markdown scope remains the right safety boundary for this phase.
- Open question: for unsupported metadata lines beyond newline markers, should we reject with `invalid_patch` or ignore safely?
