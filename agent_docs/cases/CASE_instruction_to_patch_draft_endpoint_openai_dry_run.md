---
case_id: CASE_instruction_to_patch_draft_endpoint_openai_dry_run
created: 2026-03-08
---

# CASE: Instruction-to-Patch Draft Endpoint (OpenAI, Dry-Run)

## Slice metadata
- Type: feature
- User Value: converts natural-language edit intent into patch drafts that users/tools can validate before any mutation is applied.
- Why Now: planning-only workflow seam is now live, so the next incremental unlock is generating concrete patch proposals without executing writes.
- Risk if Deferred: workflow planning remains abstract and cannot yet accelerate real note-editing flows, limiting practical value of the new LLM seam.

## Goal
Add a read-safe dry-run endpoint that turns edit instructions into unified-diff patch drafts for an explicit target note path.

## Why this next
- Value: bridges the gap between action planning and existing patch safety pipeline by producing actionable patch text.
- Dependency/Risk: reuses established patch validator/propose contracts and avoids apply-time risk by staying dry-run only.
- Tech debt note: first pass will be OpenAI-specific and may use simple prompt/response parsing before stronger schema tooling is added.

## Definition of Done
- [ ] Add `POST /mcp/workflow/draft_patch` (or equivalent) that accepts instruction + target path and returns a proposed unified diff string only.
- [ ] Endpoint validates target path intent inputs and rejects malformed payloads with deterministic error codes.
- [ ] Draft generation remains non-mutating (no write/apply/commit side effects).
- [ ] Service/request specs cover success path, invalid payload, provider unavailable, and malformed provider response contracts.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_draft_patch_spec.rb spec/mcp_patch_spec.rb spec/services/llm/workflow_patch_drafter_spec.rb spec/mcp_error_mapper_spec.rb`

## Scope
**In**
- Introduce an LLM patch-drafter service seam under `app/services/llm/` that outputs unified diff text.
- Add MCP dry-run endpoint wiring and payload validation for instruction + target path.
- Reuse patch policy constraints via existing patch proposal validation path where practical.
- Add focused runtime/error mapping coverage for new drafter error contracts.

**Out**
- Direct patch apply execution or auto-commit behavior.
- Multi-file patch drafting.
- Non-OpenAI provider support.

## Proposed approach
Add a small workflow patch-drafter service that prompts OpenAI for a single-file unified diff draft scoped to a provided note path. Route endpoint requests through strict payload validation and existing MCP error mapping. Before returning a draft, pass it through existing patch validation/propose logic (or equivalent contract checks) so malformed model output is rejected deterministically. Keep the endpoint explicitly dry-run and read-safe to preserve mutation boundaries.

## Steps (agent-executable)
1. Add workflow patch-drafter interface + OpenAI-backed implementation under `app/services/llm/`.
2. Add MCP action class and route for draft-patch requests with strict JSON payload validation.
3. Validate generated diff through existing patch proposal/validator path before returning draft payload.
4. Extend error mapper with draft-specific invalid/unavailable failure mapping.
5. Add request specs for endpoint success and failure paths; add service specs for drafter response-shape handling.
6. Run targeted MCP patch/workflow/LLM specs and keep behavior read-safe (no apply side effects).

## Risks / Tech debt / Refactor signals
- Risk: model-generated diff format drift can produce invalid patches. -> Mitigation: enforce patch validator pass before response.
- Risk: instruction ambiguity may produce over-broad edits. -> Mitigation: require explicit target path and single-file diff contract.
- Debt: prompt/response handling remains OpenAI-centric in this slice.
- Refactor suggestion (if any): if draft contracts expand (multi-file/structured edits), introduce explicit patch-draft schema objects and provider adapters.

## Notes / Open questions
- Assumption: first iteration targets one explicit file path per request.
- Open question: whether to include optional current-file content in request context or always read server-side before prompting.
