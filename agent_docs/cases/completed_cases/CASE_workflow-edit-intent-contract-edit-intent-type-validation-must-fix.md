---
case_id: CASE_workflow-edit-intent-contract-edit-intent-type-validation-must-fix
created: 2026-04-08
---

# CASE: Workflow Edit Intent Type Validation Must Fix

## Slice metadata
- Type: hardening
- User Value: keeps the new `edit_intent` draft seam deterministic by rejecting malformed provider payload field types before they can escape as internal server errors.
- Why Now: the branch moved draft generation onto a stricter `edit_intent` contract, but one malformed content-path from provider output can still reach the patch builder and fail with an unhandled Ruby exception instead of the intended unavailable/invalid-draft behavior.
- Risk if Deferred: a malformed hosted or local provider payload could produce a 500 on `/mcp/workflow/draft_patch`, `/mcp/workflow/apply_patch`, or `/mcp/workflow/execute`, weakening the core reliability goal of this refactor.

## Goal
Close the remaining type-validation gap in the `edit_intent` normalization seam so malformed provider payloads fail deterministically instead of crashing later in patch translation.

## Why this next
- Value: protects the central contract this feature just introduced.
- Dependency/Risk: keeps the current implementation shape intact while fixing one correctness gap in provider-output validation.
- Tech debt note: pays down a temporary under-validation shortcut in `WorkflowPatchDrafter` without widening scope into planner or execute redesign.

## Definition of Done
- [ ] `WorkflowPatchDrafter` (or the shared edit-intent schema helper it relies on) validates `edit_intent` field types and supported operations strongly enough that malformed provider payloads cannot reach the patch builder with invalid `content` or other required fields.
- [ ] Malformed provider payloads with wrong field types map to the existing deterministic unavailable behavior instead of surfacing as unhandled exceptions.
- [ ] Focused specs cover at least one malformed `edit_intent.content` type regression and any adjacent malformed-field case needed to lock the boundary.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/llm/workflow_patch_drafter_spec.rb spec/mcp_workflow_draft_patch_spec.rb spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb`

## Scope
**In**
- Tighten `edit_intent` type validation at the workflow drafter/schema boundary.
- Add focused regression specs for malformed provider payloads that currently bypass validation.

**Out**
- New `edit_intent` operation types.
- Planner contract changes.
- Broader patch-builder redesign beyond the minimum needed to prevent the crash path.

## Proposed approach
Validate the returned provider hash with the same schema-level rules used for parsed JSON instead of only checking key presence. The simplest fix is to route provider-returned hashes back through the strict `WorkflowEditIntent` normalization helper or an equivalent validator before `WorkflowDraftPatchAction` sees them. Then add one request-level regression showing that malformed provider content types still surface as `draft_unavailable` rather than a 500. Keep the fix centered on the normalization seam and its tests.

## Steps (agent-executable)
1. Reproduce the malformed `edit_intent.content` type path in a focused spec using a provider double that returns a hash with non-string content.
2. Tighten `WorkflowPatchDrafter` or `WorkflowEditIntent` so provider-returned hashes go through full field-type validation, not just key-presence checks.
3. Ensure invalid typed payloads map to the existing deterministic unavailable error path.
4. Update targeted request/service specs to lock the regression and rerun the listed verification commands.

## Risks / Tech debt / Refactor signals
- Risk: duplicating edit-intent validation rules between parsed JSON and already-built hashes would create drift. -> Mitigation: reuse one shared validator/normalizer for both paths.
- Debt: pays down an under-validated contract seam introduced by the feature branch.
- Refactor suggestion (if any): if more internal callers start constructing `edit_intent` hashes directly, expose one canonical `normalize_hash` entry point in `WorkflowEditIntent` rather than scattering ad hoc checks.

## Notes / Open questions
- Assumption: the existing external error contract should stay unchanged; the fix should map malformed provider payloads back to the current unavailable boundary rather than inventing a new public error shape.
