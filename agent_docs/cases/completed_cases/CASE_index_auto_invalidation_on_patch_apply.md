---
case_id: CASE_index_auto_invalidation_on_patch_apply
created: 2026-03-01
---

# CASE: Index Auto-Invalidation on Patch Apply

## Goal
Automatically invalidate the persisted index artifact after successful patch application so MCP query behavior does not rely on stale index state.

## Why this next
- Value: removes stale-index ambiguity after note mutations and reduces operator burden for manual invalidation.
- Dependency/Risk: de-risks retrieval correctness as mutation volume grows and before semantic retrieval internals become more complex.
- Tech debt note: pays down lifecycle debt by coupling mutation success to deterministic index invalidation; still defers incremental/async indexing.

## Definition of Done
- [ ] Successful `/mcp/patch/apply` invalidates `NOTES_ROOT/.mirai/index.json` when present.
- [ ] `/mcp/patch/apply` remains successful when no artifact exists; response payload stays unchanged.
- [ ] Invalidation must happen only after successful patch apply + git commit (no invalidation on failed apply).
- [ ] Request/service tests cover artifact-present and artifact-missing behavior plus failure-path non-invalidation.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_patch_spec.rb spec/index_store_spec.rb`

## Scope
**In**
- Add bounded invalidation hook in patch-apply orchestration layer.
- Reuse `IndexStore` deletion semantics (deterministic true/false) without API shape changes.
- Add focused tests around patch apply lifecycle interaction with index artifact.

**Out**
- Automatic index rebuild after invalidation.
- Incremental indexing.
- Any MCP response schema changes for patch apply/query/status.

## Proposed approach
Extend `Mcp::PatchApplyAction` orchestration to coordinate `PatchApplier` and `IndexStore`: call patch apply first, then attempt index artifact deletion as post-success side effect. Keep patch apply response contract unchanged by not returning invalidation metadata in this slice. Preserve error mapping by ensuring failed patch apply paths do not trigger invalidation attempts. Add request specs that seed an index artifact and verify deletion after successful apply, plus a failure-path regression where apply conflict leaves artifact intact.

## Steps (agent-executable)
1. Inject `IndexStore` into `Mcp::PatchApplyAction` and delete artifact after successful applier call.
2. Preserve current `Mcp::PatchApplyAction` return payload and endpoint contract.
3. Add request specs in `spec/mcp_patch_spec.rb` for:
4. successful apply with existing artifact -> artifact removed,
5. successful apply with missing artifact -> unchanged success response,
6. failed apply -> artifact remains.
7. Add or adjust unit specs only if action/service seams require direct coverage.
8. Run targeted patch/index specs and verify no endpoint contract regressions.

## Risks / Tech debt / Refactor signals
- Risk: invalidating too early (before commit success) could hide failures and lose reusable artifact unexpectedly. -> Mitigation: run invalidation strictly after successful apply return.
- Risk: lifecycle coupling could spread across route layer if not contained. -> Mitigation: keep logic in MCP action orchestration only.
- Debt: invalidation remains delete-only; rebuild is still explicit/manual.
- Refactor suggestion (if any): if more mutation tools are added, introduce a shared post-mutation lifecycle hook coordinator.

## Notes / Open questions
- Assumption: deterministic correctness is prioritized over short-term query performance; invalidating stale artifacts is preferable to serving outdated chunks.
