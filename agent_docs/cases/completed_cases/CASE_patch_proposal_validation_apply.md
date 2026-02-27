---
case_id: CASE_patch_proposal_validation_apply
created: 2026-02-27
---

# CASE: Constrained Patch Proposal Validation + Apply

## Goal
Add a safe, test-backed patch workflow that validates markdown-only diffs under `NOTES_ROOT` and applies accepted patches through a controlled endpoint.

## Why this next
- Value: unlocks the first reversible mutation path using diff context instead of raw file writes.
- Dependency/Risk: this is the prerequisite for mandatory git-commit wrapping in the next slice.
- Tech debt note: we will likely keep patch parsing rules intentionally narrow at first (single-file markdown patches) to reduce risk.

## Definition of Done
- [ ] Add a patch validation service that accepts a unified diff payload and rejects unsafe edits (path traversal, non-`.md`, absolute paths, unsupported patch shapes).
- [ ] Add endpoint(s) for proposal + apply where proposal returns validation details/dry-run summary and apply writes only validated patch hunks under `NOTES_ROOT`.
- [ ] Endpoint error mapping is explicit and stable (`invalid_patch`, `invalid_path`, `invalid_extension`, `not_found`, `conflict` as applicable).
- [ ] Tests cover happy path and rejection cases, including traversal and extension failures.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`.

## Scope
**In**
- Patch payload validation and normalization for markdown note targets.
- Minimal apply mechanism with constrained scope (single-file, text patch hunks only).
- Sinatra route wiring and JSON response contract.
- RSpec coverage for service behavior and request-level responses.

**Out**
- Git commit creation/wrapping (handled in next slice).
- Multi-file or binary patch support.
- Auto-reindexing/vector updates.

## Proposed approach
Add a small patch service layer (for example `app/services/patch_validator.rb` and `app/services/patch_applier.rb`) that reuses `SafeNotesPath` for every target path. Keep the contract narrow: require unified diff format and reject unsupported patch headers/hunks early. Introduce a proposal endpoint that validates and returns a dry-run summary (target path, hunk count, net line delta) without writing. Add an apply endpoint that executes only previously valid patch payloads against files under `NOTES_ROOT`, with conflict handling when file content no longer matches expected context. Map typed service errors to stable 4xx responses. Back this with focused unit + request specs.

## Steps (agent-executable)
1. Add service specs that define accepted/rejected patch shapes and path safety enforcement.
2. Implement patch validation primitives and typed errors in a dedicated service.
3. Add apply service logic for constrained single-file markdown patching with conflict detection.
4. Add proposal/apply Sinatra endpoints and stable JSON error mapping.
5. Add request specs for success and failure paths, including traversal/non-md/conflict scenarios.
6. Run `docker compose run --rm dev bundle exec rspec` and fix deterministic failures.
7. Update README endpoint docs with the patch workflow contract.

## Risks / Tech debt / Refactor signals
- Risk: parser edge cases could permit malformed diffs or reject valid ones unexpectedly. → Mitigation: intentionally narrow accepted patch grammar and codify with tests.
- Debt: applying patches before mandatory git-commit wrapping leaves a temporary reversibility gap.
- Refactor suggestion (if any): if mutation endpoints grow, extract route orchestration out of `app.rb` into dedicated endpoint/service wiring.

## Notes / Open questions
- Assumption: first iteration supports only single-file markdown patches to stay within a 1-2 day slice.
- Open question: should proposal return a short canonicalized patch digest to bind apply requests to a validated payload?
