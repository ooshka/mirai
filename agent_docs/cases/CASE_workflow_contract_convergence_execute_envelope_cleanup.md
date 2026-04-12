---
case_id: CASE_workflow_contract_convergence_execute_envelope_cleanup
created: 2026-04-12
---

# CASE: Workflow Contract Convergence Execute Envelope Cleanup

## Slice metadata
- Type: feature
- User Value: gives thin clients and operators one clearer workflow action contract by trimming temporary execute-request envelope awkwardness without changing the core draft/apply semantics.
- Why Now: `mirai` now owns planner-intent expansion, `edit_intent` normalization, model-profile selection, dry-run trace output, and a canonical execute path, but the current execute request still carries some transitional wrapper/validation shape that keeps the workflow surface less uniform than it should be.
- Risk if Deferred: more client and test code will continue to encode slightly different expectations between plan output, draft/apply requests, and execute requests, increasing change cost and slowing later CLI or frontend work.

## Goal
Tighten the canonical workflow execute request so the returned planner action payload is the single obvious client contract across planning and execution surfaces.

## Why this next
- Value: improves the highest-leverage workflow seam by converging plan output and execute input around one clearer action shape instead of layering more client-side interpretation on top.
- Dependency/Risk: builds directly on the completed planner-intent simplification and keeps the change within the server-owned workflow contract, without reopening provider behavior or CLI design.
- Tech debt note: pays down lingering contract translation debt in the execute boundary while intentionally deferring richer apply correlation metadata and any broader action-registry redesign.

## Definition of Done
- [ ] `/mcp/workflow/execute` accepts the canonical planner-returned `workflow.draft_patch` action payload with no extra client-side wrapper or duplicate translation fields beyond what is strictly required by the action contract itself.
- [ ] Execute request parsing and validation reuse the same workflow action assumptions already expressed by planner output and draft/apply request handling, reducing special-case execute-only shape rules.
- [ ] Invalid execute payloads fail deterministically with explicit request errors rather than depending on ambiguous wrapper behavior.
- [ ] Existing draft/apply public request contracts remain unchanged unless one minimal shared helper extraction is required for correctness.
- [ ] Focused request/service specs cover one valid planner-action-to-execute path and the key invalid execute-shape regressions this cleanup is meant to eliminate.
- [ ] README workflow docs describe the execute request as the same canonical action contract returned by planning, clarifying when clients should use execute versus draft/apply directly.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_execute_spec.rb spec/services/mcp/workflow_execute_action_spec.rb`

## Scope
**In**
- Narrow cleanup of execute request envelope/parsing around the canonical `workflow.draft_patch` action shape.
- Minimal shared validation/helper extraction only if needed to keep planner/draft/apply/execute assumptions aligned.
- Focused docs/spec updates for execute contract convergence.

**Out**
- Changing the canonical `workflow.draft_patch` action fields themselves.
- Apply-response metadata expansion beyond what execute needs for request-shape convergence.
- Generic multi-action workflow execution or a broader workflow action registry.

## Proposed approach
Treat this as a contract-convergence cleanup, not a new capability slice. Start from the planner-returned canonical action payload and make `/mcp/workflow/execute` consume that same shape as directly as possible, eliminating any transitional wrapper or endpoint-local parsing awkwardness that remains from earlier slices. Reuse existing workflow action validation patterns where practical, and extract only the smallest shared helper if execute currently duplicates request-shape logic differently from draft/apply. Keep the returned planner action shape stable, keep execute limited to the existing `workflow.draft_patch` action, and update the README plus targeted request/service specs so the canonical contract is unambiguous to future CLI or frontend consumers.

## Steps (agent-executable)
1. Inspect current `/mcp/workflow/execute` request parsing, helper methods, and request/service specs to identify the exact wrapper or validation differences from the canonical planner-returned action shape.
2. Define the smallest execute-request cleanup that lets the canonical `workflow.draft_patch` action payload serve as the direct execute input.
3. Update execute request parsing/validation and any affected helper/service seams to consume that shape consistently.
4. Extract one small shared helper only if needed to keep execute aligned with draft/apply action validation semantics.
5. Update focused execute request/service specs for one valid canonical action path plus invalid-shape regressions.
6. Refresh README workflow documentation so execute is clearly described as consuming the same canonical action contract returned by planning.

## Risks / Tech debt / Refactor signals
- Risk: tightening execute parsing could accidentally diverge from draft/apply request handling instead of converging it. -> Mitigation: anchor the cleanup to the planner-returned canonical action payload and lock the shared expectations in request specs.
- Risk: trying to generalize execute beyond `workflow.draft_patch` in the same slice would expand scope and weaken reviewability. -> Mitigation: keep the cleanup specific to the current supported action only.
- Debt: pays down temporary execute-envelope translation debt while keeping the broader action-registry question out of scope.
- Refactor suggestion (if any): if draft/apply/execute continue to share more action parsing rules after this slice, extract a small workflow action request normalizer instead of growing endpoint-local helpers.

## Notes / Open questions
- Assumption: the current execute endpoint still has enough wrapper awkwardness that a small cleanup materially improves contract clarity even without changing capabilities.
- Assumption: keeping one canonical client-facing action payload across plan and execute matters more right now than adding richer operator UX in the CLI.
