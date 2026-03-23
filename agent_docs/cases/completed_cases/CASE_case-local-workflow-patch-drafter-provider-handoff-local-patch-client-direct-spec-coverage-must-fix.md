---
case_id: CASE_case-local-workflow-patch-drafter-provider-handoff-local-patch-client-direct-spec-coverage-must-fix
created: 2026-03-22
---

# CASE: Local Workflow Patch Client Direct Spec Coverage Must Fix

## Slice metadata
- Type: hardening
- User Value: keeps the local workflow draft path reviewable and safe to change by adding direct coverage for the adapter that normalizes provider responses into the public patch contract.
- Why Now: the local patch client was introduced in the current slice, but its normalization and malformed-response behavior are only covered indirectly through higher-level tests.
- Risk if Deferred: later edits to local response parsing can silently break malformed-response mapping or JSON-vs-diff normalization while targeted route specs still pass through broad stubbing.

## Goal
Add direct specs for `Llm::LocalWorkflowPatchClient` so the local provider’s response normalization and malformed/unreachable behavior are tested at the adapter boundary.

## Why this next
- Value: gives the new local draft adapter a direct contract test at the exact boundary where provider responses are normalized.
- Dependency/Risk: reduces regression risk in the most provider-specific logic added by the local drafter handoff.
- Tech debt note: pays down missing low-level coverage before the local draft path gains more response-shaping logic.

## Definition of Done
- [ ] `Llm::LocalWorkflowPatchClient` has direct specs for raw unified-diff success and JSON `{ "patch": "..." }` success normalization.
- [ ] Direct specs cover malformed `choices/message/content` payloads and invalid/empty patch content mapping to `ResponseError`.
- [ ] Direct specs cover unreachable request failure mapping to `RequestError` without relying on request-spec stubs alone.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/services/llm/local_workflow_patch_client_spec.rb spec/mcp_workflow_draft_patch_spec.rb`

## Scope
**In**
- New direct unit/service specs for `Llm::LocalWorkflowPatchClient`.
- Minimal production adjustments only if needed to make the adapter behavior testable without changing public draft behavior.

**Out**
- Broader request-spec expansion that duplicates the same parsing cases at the endpoint layer.
- Prompt tuning or local provider payload redesign beyond the current smoke-aligned contract.

## Proposed approach
Test the adapter at the HTTP/JSON normalization seam rather than adding more indirect route examples. Mirror the style used by other provider client specs in the repo: stub HTTP results close to `Net::HTTP`, assert successful extraction for both accepted content shapes, and verify malformed or unreachable responses raise the client’s existing typed errors. Keep the endpoint contract unchanged and only touch production code if testability reveals a small missing seam.

## Steps (agent-executable)
1. Inspect existing provider-client specs in `spec/services/` for the repo’s preferred pattern around `Net::HTTP` stubbing and typed error assertions.
2. Add a focused `spec/services/llm/local_workflow_patch_client_spec.rb` covering raw diff success, JSON patch success, malformed content, and request failure cases.
3. Make the smallest production adjustment only if direct testability exposes an avoidable parsing blind spot.
4. Re-run the focused local patch client and draft endpoint verification commands.

## Risks / Tech debt / Refactor signals
- Risk: duplicating too much endpoint-level coverage in low-level specs. -> Mitigation: keep the new spec focused on adapter parsing and request failure boundaries only.
- Debt: the current local draft adapter still embeds prompt text inline.
- Refactor suggestion (if any): if more workflow clients appear, extract shared OpenAI-compatible chat request helpers so provider-client specs can stay consistent and compact.

## Notes / Open questions
- Assumption: direct adapter coverage is the right boundary for local response-shape hardening, not additional route-level examples.
