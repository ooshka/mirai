---
case_id: CASE_local_workflow_draft_prompt_contract_hardening
created: 2026-04-04
---

# CASE: Local Workflow Draft Prompt Contract Hardening

## Slice metadata
- Type: hardening
- User Value: restores the self-hosted workflow draft path by making the local drafter prompt reliably produce a full single-file unified diff that `mirai` can validate and operators can use end to end.
- Why Now: the host-network and local-model wiring now reaches the local planner and drafter successfully, and the first live smoke failure is a contract miss at the draft seam rather than connectivity. This is the smallest blocker preventing the self-hosted workflow path from completing.
- Risk if Deferred: the local workflow smoke remains red, operators cannot trust local draft generation despite the runtime being reachable, and downstream work risks adding normalization shortcuts around malformed model output instead of fixing the contract at the prompt boundary.

## Goal
Strengthen the local workflow draft prompt and its focused validation coverage so the self-hosted drafter consistently returns a full single-file unified diff with valid `--- a/<path>` and `+++ b/<path>` headers.

## Why this next
- Value: unblocks the next real self-hosted workflow milestone by turning a reachable local draft provider into a usable one.
- Dependency/Risk: protects the existing strict patch parser contract instead of weakening it to accept ambiguous or partial diffs.
- Tech debt note: pays down prompt-contract ambiguity between `mirai` and `local_llm` while intentionally deferring broader model-evaluation or fallback-policy work.

## Approach Outline

### Utility (Why this helps now)
- Converts the current smoke failure from an operator-visible blocker into a test-backed local workflow success path.
- Preserves the existing patch validation safety boundary while making the model instruction clearer at the only seam currently failing in live use.

### Rationale (Why this approach)
- Prefer strengthening the drafter prompt over relaxing `PatchParser`, because hunk-only acceptance would blur the mutation safety contract and make malformed model output easier to apply accidentally.
- Prefer a narrow prompt-and-spec slice over broader output-normalization heuristics, because the current failure is deterministic and shared with `local_llm`; clearer instructions are lower-risk than inventing implicit patch reconstruction.
- Assume the current `qwen3:8b` local baseline can satisfy the contract with more explicit format requirements and a minimal example, since the planner JSON path already succeeds against the same runtime.

### Implementation Shape (How it will be done)
- Tighten the local draft system/user prompt in `app/services/llm/local_workflow_patch_client.rb` so it explicitly requires diff headers, target-path echo, and no prose outside the JSON `patch` field.
- Consider adding one bounded in-prompt diff example or header-specific constraint block if plain wording alone is still ambiguous.
- Keep the public `/mcp/workflow/draft_patch` endpoint and `PatchParser` contract unchanged; this slice should improve producer behavior, not widen consumer acceptance.
- Extend `spec/services/llm/local_workflow_patch_client_spec.rb` to lock the stronger request prompt shape and any new constraints/example text that define the contract.
- Add or update request-level smoke-adjacent coverage where useful so failures continue surfacing as invalid draft output rather than hidden coercion.

### Risk & Validation Preview
- Risk: prompt changes may improve headers but accidentally encourage multi-hunk or prose-wrapped responses. Validation: keep existing strict parser boundary and add focused client-spec assertions for exact request contents.
- Risk: prompt wording may overfit one model revision and still drift later. Validation: rerun `scripts/smoke_local.sh` against the local provider after the prompt change and keep the contract narrow and explicit.
- Risk: duplicated prompt wording could drift from `local_llm`’s smoke guidance. Validation: compare the updated prompt against `../local_llm/scripts/ollama/smoke.py` expectations during implementation and note any intentional divergence.

## Definition of Done
- [ ] The local draft prompt in `Llm::LocalWorkflowPatchClient` explicitly requires a full single-file unified diff with `--- a/<path>` and `+++ b/<path>` headers inside the JSON `patch` field.
- [ ] `POST /mcp/workflow/draft_patch` and the existing patch parser contract remain unchanged; no parser relaxation is introduced in this slice.
- [ ] Focused specs cover the strengthened prompt/request payload and preserve malformed-response failure behavior.
- [ ] Local smoke verification demonstrates the drafter no longer fails on missing patch headers, or if the model still fails, the remaining failure is narrower and clearly attributable.
- [ ] Tests/verification: `docker compose --env-file .env.local exec -T dev bash -lc 'BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh'` and `docker compose run --rm dev bundle exec rspec spec/services/llm/local_workflow_patch_client_spec.rb spec/mcp_workflow_draft_patch_spec.rb`

## Scope
**In**
- Local draft prompt text and request-payload shaping in `Llm::LocalWorkflowPatchClient`.
- Focused spec updates for local draft prompt contract and failure handling.
- Minimal doc or inline contract-note updates only if the new prompt wording changes operator-facing assumptions.

**Out**
- Relaxing `PatchParser` or reconstructing diff headers from hunk-only model output.
- Broader local workflow evaluation, fallback policy, or multi-model routing changes.
- Changes to planner prompt behavior or hosted-provider draft behavior.

## Proposed approach
Treat the missing diff header as a producer-contract problem, not a parser problem. Update the local draft client prompt so it names the required header lines explicitly, reinforces that the `patch` value must be a complete unified diff for the provided path, and forbids commentary or partial hunks. Keep the downstream parser and endpoint contract strict, then prove the stronger prompt with focused client specs and the existing local smoke path. If one short example diff is needed to anchor the format, keep it minimal and path-generic so the prompt remains maintainable.

## Steps (agent-executable)
1. Inspect the current local draft request payload and the sibling `local_llm` draft smoke wording to identify the smallest prompt strengthening that targets header omission directly.
2. Update `app/services/llm/local_workflow_patch_client.rb` to require explicit `--- a/<path>` and `+++ b/<path>` headers and prohibit returning only a hunk.
3. Extend `spec/services/llm/local_workflow_patch_client_spec.rb` to assert the updated request payload shape and keep malformed-response behavior intact.
4. Update any request/spec coverage needed to show `/mcp/workflow/draft_patch` behavior is unchanged except for improved local-provider success potential.
5. Run the focused RSpec coverage and the local smoke script against the host-networked dev container.
6. If the smoke still fails, capture the narrower remaining local draft output mismatch as follow-up evidence instead of widening this slice.

## Risks / Tech debt / Refactor signals
- Risk: a stronger prompt could become too verbose and reduce model compliance elsewhere. -> Mitigation: keep changes narrowly targeted at the missing header defect and reuse existing constraints rather than rewriting the entire prompt.
- Risk: `mirai` and `local_llm` could drift on draft expectations again. -> Mitigation: compare wording/constraints during implementation and prefer shared contract language where practical.
- Debt: prompt-contract details are still embedded in client code rather than a shared workflow prompt policy object.
- Refactor suggestion (if any): if planner/drafter prompt tuning continues across providers, extract small shared prompt builders or contract constants instead of duplicating string policy in each client.

## Notes / Open questions
- Assumption: the current local baseline model `qwen3:8b` remains the intended planner/drafter model for the Windows-hosted Ollama path.
- Assumption: one bounded prompt-strengthening pass is the right first move before considering any response normalization beyond current JSON patch extraction.
