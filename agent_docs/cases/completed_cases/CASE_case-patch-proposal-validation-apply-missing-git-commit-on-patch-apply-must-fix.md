---
case_id: CASE_case-patch-proposal-validation-apply-missing-git-commit-on-patch-apply-must-fix
created: 2026-02-27
---

# CASE: Commit note mutations after patch apply

## Goal
Ensure `/mcp/patch/apply` persists successful note edits as git commits so every runtime mutation is reversible and auditable.

## Why this next
- Value: Restores the core safety guarantee that all note mutations are traceable and undoable.
- Dependency/Risk: Current direct file writes bypass version control and can silently lose provenance.
- Tech debt note: Introduces a minimal git-integration seam needed by later mutation endpoints.

## Definition of Done
- [ ] Successful `POST /mcp/patch/apply` creates a git commit in the notes repo containing the patched file change.
- [ ] Commit failures (for example, repo missing/uninitialized, git command failure) return a structured error without partially reporting success.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_patch_spec.rb` (plus any new git-integration specs added for apply flow)

## Scope
**In**
- Patch apply execution path and service boundaries where write + commit occurs.
- Error mapping from git failure modes to stable API responses.
- Automated tests covering successful commit and representative git failure handling.

**Out**
- Non-patch mutation endpoints or background re-indexing.

## Proposed approach
Add a small service responsible for committing a specific changed note path inside `NOTES_ROOT` (stage file + commit with deterministic message). Invoke it only after patch application succeeds, and fail the endpoint if commit does not succeed. Ensure commit execution is constrained to the notes repo root and handles common failure states explicitly. Extend request/service specs to assert that apply both updates file content and creates a commit, and that git failures produce deterministic error behavior.

## Steps (agent-executable)
1. Introduce/extend a git commit service for notes-root operations with clear success/failure return values.
2. Wire `PatchApplier` (or orchestration layer) to commit the changed file immediately after a successful patch write.
3. Map git failure scenarios to a structured non-2xx API error in `app.rb` (without claiming patch success).
4. Add or update specs to cover successful commit and at least one git failure path, then run the patch endpoint specs.

## Risks / Tech debt / Refactor signals
- Risk: File write succeeds but commit fails, leaving uncommitted state. → Mitigation: treat as error and report explicitly so caller can retry/repair.
- Debt: Git shelling may be scattered if not encapsulated. → Mitigation: keep git logic in a dedicated service.
- Refactor suggestion (if any): introduce a small transaction-style orchestration object to coordinate validate/apply/commit with clear rollback strategy.

## Notes / Open questions
- Assumption: notes repository has a writable git working tree available at `NOTES_ROOT`.
