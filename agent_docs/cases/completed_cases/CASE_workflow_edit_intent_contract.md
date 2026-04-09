---
case_id: CASE_workflow_edit_intent_contract
created: 2026-04-08
---

# CASE: Workflow Edit Intent Contract

## Slice metadata
- Type: feature
- User Value: gives workflow operators and provider implementors a smaller, more reliable draft contract by replacing model-authored unified diffs with a typed `edit_intent` payload that `mirai` can validate and translate itself.
- Why Now: the recent local drafter work showed that requiring `qwen3:14b` to emit valid patch text is an avoidable reliability bottleneck, while `mirai` already owns the patch safety and execution boundaries needed to absorb that formatting responsibility.
- Risk if Deferred: self-hosted workflow progress will continue to depend on brittle prompt tuning around unified-diff syntax, and the current patch-first drafter seam will harden across more workflow endpoints and fixtures before the contract is simplified.

## Goal
Define and adopt a `mirai`-owned `edit_intent` drafting contract so workflow providers return bounded edit semantics instead of raw unified diffs.

## Why this next
- Value: reduces the highest current local-model failure mode without forcing a larger workflow redesign.
- Dependency/Risk: unblocks the follow-on execution bridge by first making the provider-facing output shape explicit and testable.
- Tech debt note: pays down duplicated responsibility between untrusted model output and `mirai`'s existing patch-validation layer, while intentionally deferring broader planner-envelope simplification and endpoint cleanup.

## Definition of Done
- [ ] A canonical `edit_intent` JSON shape is documented for workflow drafting, including required fields, allowed operation bounds, and explicit single-note/single-target constraints for the first slice.
- [ ] The workflow drafter/provider seam in `app/services/llm/` normalizes provider responses to the new `edit_intent` contract and rejects malformed or incomplete intent payloads deterministically.
- [ ] `/mcp/workflow/draft_patch` exposes the new draft contract clearly enough for thin clients and fixtures to consume, while keeping request validation aligned to the existing canonical `workflow.draft_patch` action envelope.
- [ ] Existing patch validation and mutation safety ownership remains in `mirai`; no provider is trusted to bypass patch policy or apply notes directly.
- [ ] Focused request/service specs cover at least one successful `edit_intent` draft and key malformed/unavailable regressions for both hosted and local provider normalization paths.
- [ ] README workflow docs describe the new `edit_intent` contract, the server-owned translation boundary, and the fact that broader execute/apply bridging is intentionally deferred to the next slice.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_draft_patch_spec.rb spec/services/llm/workflow_patch_drafter_spec.rb spec/services/llm/local_workflow_patch_client_spec.rb`

## Scope
**In**
- Define the first canonical `edit_intent` shape for workflow drafting in `mirai`.
- Update workflow drafter/provider normalization and the dry-run draft endpoint/docs/specs around that shape.
- Add only the minimal translation boundary needed to keep patch-policy ownership server-side.

**Out**
- Reworking planner output into a smaller semantic intent envelope.
- Full execute/apply endpoint migration to consume `edit_intent` end to end.
- Broad multi-file edit support, free-form operations, or direct provider-authored patch/application bypasses.

## Proposed approach
Keep the slice contract-first and bounded to the drafter seam. Introduce a typed `edit_intent` payload for the existing canonical `workflow.draft_patch` action, likely centered on one markdown target path plus one bounded content-change operation or replacement block that `mirai` can turn into a patch through server-owned logic. Update `Llm::WorkflowPatchDrafter`, `OpenaiWorkflowPatchClient`, `LocalWorkflowPatchClient`, and `Mcp::WorkflowDraftPatchAction` so providers return or are normalized into the new intent shape instead of raw patch text. Preserve the current request envelope and defer broader execute/apply path rewiring to the follow-on bridge slice. Limit public-contract changes to the draft endpoint, focused specs, and README workflow docs.

## Steps (agent-executable)
1. Inspect the current workflow drafter clients, `WorkflowPatchDrafter`, `WorkflowDraftPatchAction`, and `/mcp/workflow/draft_patch` request/response specs to locate the smallest shared normalization boundary.
2. Define the first canonical `edit_intent` schema in code/docs, including required fields, allowed operation type(s), and the single-file markdown constraints this slice will enforce.
3. Update the hosted and local workflow patch clients to request and parse `edit_intent` JSON, failing closed on malformed JSON, missing fields, or unsupported operations.
4. Refactor `WorkflowPatchDrafter` and `WorkflowDraftPatchAction` so the workflow draft path returns the normalized `edit_intent` contract while preserving deterministic unavailable behavior for malformed provider responses.
5. Update focused request/service specs to lock one valid `edit_intent` response and key invalid/unavailable regressions across hosted and local provider paths.
6. Refresh README workflow docs and any workflow contract notes so downstream fixtures and `local_llm` follow-on work target the new `edit_intent` shape instead of unified-diff text.

## Risks / Tech debt / Refactor signals
- Risk: trying to support too many edit primitives in the first `edit_intent` version would recreate the same ambiguity as raw patch text. -> Mitigation: keep v1 narrowly typed and single-file, with explicit unsupported-operation failures.
- Risk: partially changing the drafter seam could blur whether `/mcp/workflow/draft_patch` is a dry-run intent endpoint or a dry-run patch endpoint. -> Mitigation: make the response contract explicit in docs/specs and defer execute/apply bridge work to the next slice instead of mixing both migrations here.
- Debt: pays down the current syntax-heavy provider contract, but may temporarily add a translation seam while execute/apply still depend on the older patch pipeline.
- Refactor suggestion (if any): if `edit_intent` parsing and translation spread across multiple classes, extract a dedicated workflow edit-intent schema/translator object before adding broader planner or execute changes.

## Notes / Open questions
- Assumption: the first `edit_intent` version should stay intentionally narrow, even if that means a follow-on slice adds a second allowed operation type after the contract proves out.
- Assumption: coordinated contract cleanup is acceptable here, so `local_llm` and any hosted-provider prompts/fixtures can be updated to match `mirai` rather than carrying a long-lived patch compatibility layer.
