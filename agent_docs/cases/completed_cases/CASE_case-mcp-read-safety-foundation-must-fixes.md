---
case_id: CASE_case-mcp-read-safety-foundation-must-fixes
created: 2026-02-22
---

# CASE: Seal Symlink Escape in Notes Read Path Validation

## Goal
Close the path-containment bypass so note reads cannot escape `NOTES_ROOT` through symlinks.

## Why this next
- Value: restores the core safety guarantee for untrusted runtime-agent file access.
- Dependency/Risk: all read and future write flows depend on containment correctness.
- Tech debt note: adds a missing edge-case test that prevents regressions in filesystem safety logic.

## Definition of Done
- [ ] Path resolution rejects any path whose resolved real location is outside `NOTES_ROOT`, including symlink escapes.
- [ ] `/mcp/notes/read` returns HTTP 400 `invalid_path` for symlink-escape attempts instead of reading external files.
- [ ] Tests/verification: `bundle exec rspec` passes with new symlink escape coverage.

## Scope
**In**
- `app/services/safe_notes_path.rb` containment validation logic.
- Specs for symlink escape handling in `spec/safe_notes_path_spec.rb` and/or `spec/mcp_notes_spec.rb`.
- Any minimal endpoint error-mapping adjustment needed to preserve stable error contract.

**Out**
- New endpoints or API shape changes.
- Non-blocking cleanup/refactors unrelated to symlink containment.

## Proposed approach
Update containment checks to compare canonicalized paths rather than string prefixes of `File.expand_path` results. Use `Pathname#realpath` (or equivalent) where safe to evaluate actual filesystem targets and reject when canonical target is outside canonical `NOTES_ROOT`. Preserve existing behavior for non-existent files while still validating requested path semantics. Add explicit tests that create a symlink under the notes root pointing outside and assert rejection both at service and request levels.

## Steps (agent-executable)
1. Add a failing spec that creates an out-of-root markdown file plus an in-root symlink to it, then asserts `SafeNotesPath#resolve` raises `InvalidPathError`.
2. Add/adjust request spec asserting `GET /mcp/notes/read` with the symlink path returns 400 with `invalid_path`.
3. Implement canonical path containment validation in `app/services/safe_notes_path.rb` to block symlink escapes without breaking existing missing-file behavior.
4. Run `bundle exec rspec` and ensure all safety and endpoint specs pass.

## Risks / Tech debt / Refactor signals
- Risk: canonicalization can raise errors for non-existent targets. → Mitigation: separate parent-directory canonicalization from file existence checks and keep 404 behavior for missing files.
- Debt: current listing path behavior for symlinked markdown files may still need policy clarification after this blocker is fixed.
- Refactor suggestion (if any): centralize path normalization/canonicalization helpers if additional filesystem operations are added.

## Notes / Open questions
- Assumption: symlink traversal outside `NOTES_ROOT` must be treated as `invalid_path` (400), not `not_found`.
