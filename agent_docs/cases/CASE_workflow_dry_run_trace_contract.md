---
case_id: CASE_workflow_dry_run_trace_contract
created: 2026-04-10
---

# CASE: Workflow Dry-Run Trace Contract

## Slice metadata
- Type: feature
- User Value: gives workflow operators an inspectable dry-run result before mutation, including the normalized edit intent, generated patch, provider/model identity, and apply readiness.
- Why Now: the workflow draft path now accepts provider `edit_intent` JSON and the execute/apply paths already translate it through the server-owned patch safety path, so the next MVP blocker is operator visibility before applying real notes.
- Risk if Deferred: the upcoming CLI/operator loop will either apply changes with too little audit context or invent a client-local trace shape that later has to be reconciled with the server contract.

## Goal
Expose one mutation-free workflow dry-run trace that shows what `mirai` would apply and why it is ready, without requiring a client to stitch together draft, patch, and validation details.

## Why this next
- Value: makes real-note testing safer by letting an operator inspect the selected target, model boundary, normalized `edit_intent`, generated patch, and validation result before any commit.
- Dependency/Risk: directly builds on the completed edit-intent bridge and unblocks the CLI operator dry-run/apply loop without taking on model-profile routing yet.
- Tech debt note: pays down the current hidden dry-run work in `WorkflowDraftPatchAction#call_with_patch`, where patch generation and proposal validation happen but only the edit intent is returned to dry-run callers.

## Definition of Done
- [ ] `POST /mcp/workflow/draft_patch` returns the existing top-level `edit_intent` plus a documented nested dry-run trace that includes provider/model identity, target path/read-context summary, generated patch, validation status, and apply readiness.
- [ ] The trace is explicitly mutation-free: it may reuse patch proposal validation, but it must not call patch apply, commit notes, or trigger semantic ingestion.
- [ ] The trace keeps sensitive note content bounded by default; include request context and target/read metadata only where useful, and put the generated patch under an audit/trace field already intended for operator inspection.
- [ ] `WorkflowDraftPatchAction` owns the dry-run result shape rather than duplicating response assembly in route code; route/helper changes should be limited to passing provider/model metadata if needed.
- [ ] Existing `/mcp/workflow/apply_patch` and `/mcp/workflow/execute` response shapes remain stable unless they naturally reuse the same trace object inside their existing `audit` envelope.
- [ ] Focused service and request specs cover one successful dry-run trace, invalid draft behavior, and a regression proving no note mutation or git commit occurs on the dry-run endpoint.
- [ ] README workflow docs describe the new dry-run trace response and how operators should use it before apply/execute.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_draft_patch_spec.rb spec/services/mcp/workflow_draft_patch_action_spec.rb spec/services/mcp/workflow_edit_intent_patch_builder_spec.rb`

## Scope
**In**
- Extend the `/mcp/workflow/draft_patch` success response with a nested dry-run trace.
- Add the minimum service-level trace shaping needed around `WorkflowDraftPatchAction#call` / `#call_with_patch`.
- Surface provider/model identity from current workflow drafter settings without adding profile selection.
- Update focused request/service specs and README endpoint docs.

**Out**
- Adding a new workflow endpoint.
- Implementing local/hosted/auto model profile selection.
- Building the CLI operator loop itself.
- Changing patch apply, git commit, semantic ingestion, or workflow execute mutation behavior beyond optional trace reuse inside existing audit fields.

## Proposed approach
Keep `/mcp/workflow/draft_patch` as the dry-run endpoint and enrich its response instead of creating another route. Let `WorkflowDraftPatchAction` continue to normalize the edit intent, build a server-owned patch with `WorkflowEditIntentPatchBuilder`, and validate that patch through `PatchProposeAction`; then return those artifacts under a stable trace shape alongside the existing top-level `edit_intent`. Pass a small metadata object from route/helper construction for the configured drafter provider and workflow model so the action can include provider/model identity without reading global settings. Keep the first read-context summary bounded to target path and request context, plus small non-content metadata if useful. Avoid changing execute/apply contracts except where reusing the same trace internally is simpler and does not remove existing response fields.

## Steps (agent-executable)
1. Inspect `WorkflowDraftPatchAction`, `/mcp/workflow/draft_patch` request specs, and README workflow docs to confirm the current edit-intent-only dry-run response.
2. Choose and document one nested trace shape that preserves the top-level `edit_intent`; include provider/model identity, target/read-context summary, generated patch, validation status, and `apply_ready`.
3. Update `WorkflowDraftPatchAction` to build and return the trace from the same existing edit-intent-to-patch/propose flow used by `call_with_patch`, avoiding route-local response assembly.
4. Add minimal constructor/helper metadata plumbing so `WorkflowDraftPatchAction` can include `MCP_WORKFLOW_DRAFTER_PROVIDER` and `MCP_OPENAI_WORKFLOW_MODEL` (or equivalent configured identity) in the trace.
5. Update request and service specs for a successful trace response, invalid draft behavior, and no-mutation/no-commit behavior on `/mcp/workflow/draft_patch`.
6. Refresh README workflow docs to show the dry-run trace contract and clarify when to use draft versus apply/execute.
7. Run the focused verification command and adjust any directly affected specs if the trace object is reused by apply/execute audit output.

## Risks / Tech debt / Refactor signals
- Risk: the trace could leak too much note content in a dry-run response. -> Mitigation: keep read-context content bounded or summarized, and expose the generated patch only under an explicit operator-audit trace field.
- Risk: adding provider/model metadata in route code could spread configuration coupling. -> Mitigation: pass one small metadata object into the action rather than having the service read app settings directly.
- Debt: pays down hidden dry-run work and client-side trace-shape pressure; may add a small response-shaping seam that should be revisited when model/profile selection lands.
- Refactor suggestion (if any): if apply/execute also need the same dry-run details, extract a tiny workflow trace/value object after this contract proves useful rather than growing multiple endpoint-local hashes.

## Notes / Open questions
- Assumption: preserving the existing top-level `edit_intent` field is preferable so current thin clients can adopt the trace without losing the current dry-run contract.
- Assumption: model identity should initially reflect configured provider/model settings, not a future per-request profile, because model selection is a separate backlog slice.
