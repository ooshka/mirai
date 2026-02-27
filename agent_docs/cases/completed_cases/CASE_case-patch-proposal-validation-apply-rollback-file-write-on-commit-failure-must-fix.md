---
case_id: CASE_case-patch-proposal-validation-apply-rollback-file-write-on-commit-failure-must-fix
created: 2026-02-27
---

# CASE: Roll back file write when patch commit fails

## Goal
Ensure `/mcp/patch/apply` leaves note content unchanged when git commit fails, so failed patch applications do not bypass version-control safety guarantees.

## Why this next
- Value: Preserves atomic behavior for mutation requests and keeps runtime outcomes auditable.
- Dependency/Risk: Current flow can return `git_error` while still mutating note content on disk, violating the mutation-through-git invariant.
- Tech debt note: Introduces explicit failure-compensation behavior in patch apply orchestration.

## Definition of Done
- [ ] If commit step fails after patch write, note file content is restored to pre-apply content before returning error.
- [ ] `/mcp/patch/apply` still returns structured `git_error` response on commit failure.
- [ ] Tests/verification: `bundle exec rspec spec/patch_applier_spec.rb spec/mcp_patch_spec.rb`

## Scope
**In**
- `PatchApplier` failure handling around write + commit sequence.
- Tests asserting no persistent file mutation on commit failure (service and/or request level).

**Out**
- Broader transactional semantics beyond patch apply.
- Git-history repair for previously failed runs.

## Proposed approach
Capture original file content before applying hunks. After writing patched content, attempt commit. If commit fails, restore original content as compensating action and raise/propagate commit error. Keep endpoint error contract unchanged (`500 git_error`). Update failing-path specs to expect restored file content (not patched content) after commit failure.

## Steps (agent-executable)
1. Update `PatchApplier` to retain original content and restore it if commit step raises `NotesGitCommitter::CommitError`.
2. Preserve current error propagation as `PatchApplier::CommitError` so API mapping remains stable.
3. Update `spec/patch_applier_spec.rb` commit-failure example to assert file rollback to original content.
4. Update `spec/mcp_patch_spec.rb` commit-failure example to assert endpoint returns `git_error` and file content remains unchanged.
5. Run targeted specs and confirm green.

## Risks / Tech debt / Refactor signals
- Risk: Rollback write can also fail (permissions/disk). → Mitigation: raise clear failure and add logging/diagnostics follow-up if needed.
- Debt: Apply+commit+rollback logic is becoming transactional. → Mitigation: consider dedicated orchestration object if flow grows.
- Refactor suggestion (if any): encapsulate mutation transaction semantics in one service to avoid endpoint-level leakage.

## Notes / Open questions
- Assumption: best-effort rollback via file rewrite is acceptable for this iteration; explicit fsync/locking is out of scope.
