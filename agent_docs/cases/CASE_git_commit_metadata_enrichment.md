---
case_id: CASE_git_commit_metadata_enrichment
created: 2026-02-27
---

# CASE: Git Commit Metadata Enrichment

## Goal
Improve notes-repo auditability by enriching patch-apply git commit messages with stable MCP operation metadata while preserving current mutation behavior.

## Why this next
- Value: makes mutation history easier to inspect and debug as runtime tools expand.
- Dependency/Risk: de-risks future multi-tool mutation support by establishing a deterministic commit metadata contract now.
- Tech debt note: pays down observability/audit debt; may add a small formatting abstraction that should stay minimal.

## Definition of Done
- [ ] Successful `POST /mcp/patch/apply` commits include deterministic metadata beyond just file path (for example action/tool context).
- [ ] Existing patch apply API response and error contracts remain unchanged.
- [ ] Tests/verification: `bundle exec rspec spec/patch_applier_spec.rb spec/mcp_patch_spec.rb`

## Scope
**In**
- Commit message construction path used by patch apply mutation flow.
- Service/request specs that assert commit message format for successful apply.
- Minimal documentation/test-readme note only if verification workflow changes.

**Out**
- New mutation endpoints, commit signing, or git author/identity policy changes.

## Proposed approach
Introduce a small commit-message builder seam in the patch-apply flow so message construction is explicit and testable instead of hard-coded inline strings. Keep metadata intentionally narrow (tool/action + path) and deterministic to avoid contract churn. Update specs to assert the new commit subject format end-to-end and at service level. Preserve current error mapping and rollback semantics by limiting changes to successful commit-path metadata generation.

## Steps (agent-executable)
1. Identify where patch apply currently builds commit messages and define a single message format constant or helper for MCP patch apply.
2. Update `PatchApplier`/`NotesGitCommitter` wiring so successful apply uses the enriched deterministic message.
3. Add/update service specs to assert the exact commit subject for a successful apply.
4. Update request spec assertions to match the new commit subject while preserving existing status/body behavior.
5. Run targeted specs and confirm no regression in failure-path contracts.

## Risks / Tech debt / Refactor signals
- Risk: changing commit subject may break assumptions in existing tests or tooling. → Mitigation: keep change scoped and codify one stable format with explicit assertions.
- Debt: pays down auditability debt but may still leave metadata as plain commit text rather than structured trailers.
- Refactor suggestion (if any): if more mutation tools are added, centralize metadata formatting in a shared commit-message policy object.

## Notes / Open questions
- Assumption: commit subject format is an internal contract and can be updated now before external consumers depend on it.
