---
case_id: CASE_symlink_listing_policy_contract_alignment
created: 2026-03-02
---

# CASE: Symlink Listing Policy Contract Alignment

## Goal
Make `/mcp/notes` and `/mcp/notes/read` follow one deterministic symlink policy so listed markdown paths are always readable under the same safety constraints.

## Why this next
- Value: removes list/read contract ambiguity that currently yields operator/runtime-agent confusion and avoidable 400/404 flows.
- Dependency/Risk: derisks future automation that assumes `/mcp/notes` output is directly consumable by `/mcp/notes/read`.
- Tech debt note: pays down boundary drift between file discovery and path containment validation.

## Definition of Done
- [ ] Symlink handling policy is explicit and enforced consistently in listing and read paths.
- [ ] `GET /mcp/notes` does not return paths that violate the selected read-path safety contract.
- [ ] Request/spec coverage locks the selected policy for symlink-inside-root and symlink-escape cases.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- Choose and implement one policy for symlinked markdown files (recommended: exclude escaped symlinks from listing while preserving strict read containment).
- Update `SafeNotesPath` listing behavior and related request/service specs.
- Keep endpoint response/error shape unchanged.

**Out**
- New endpoint fields for file metadata/symlink flags.
- Relaxing read containment rules.
- Broader filesystem abstraction refactors beyond what is needed for policy alignment.

## Proposed approach
Keep current strict read containment as the safety source of truth and align listing to it. In `SafeNotesPath#list_markdown_files`, filter candidates through the same containment rules used by `resolve` (or a shared helper) before returning relative paths. Add focused specs to capture both safe symlink-in-root behavior and symlink-escape exclusion so listing remains predictable and safe. Limit changes to `SafeNotesPath`, affected request specs (`/mcp/notes`), and service-level safety tests.

## Steps (agent-executable)
1. Confirm current symlink behavior with targeted specs (list vs read mismatch baseline).
2. Implement listing filter logic in `SafeNotesPath` to enforce the selected containment policy.
3. Add/update specs in `spec/safe_notes_path_spec.rb` and relevant MCP notes request specs to lock behavior.
4. Run targeted notes/path specs, then run full RSpec.
5. Update docs only if externally visible behavior guidance needs clarification.

## Risks / Tech debt / Refactor signals
- Risk: over-filtering could hide legitimate in-root symlinked notes. -> Mitigation: add explicit positive test for symlink target inside `NOTES_ROOT`.
- Debt: pays down duplicated policy interpretation between listing and read paths by unifying containment semantics.
- Refactor suggestion (if any): if file discovery rules grow (hidden files, ignore patterns, metadata), extract a dedicated notes-discovery policy object from `SafeNotesPath`.

## Notes / Open questions
- Assumption: listing should be "read-safe by construction" rather than exposing potentially unreadable paths.
