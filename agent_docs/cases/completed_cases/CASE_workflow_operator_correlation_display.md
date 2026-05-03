---
case_id: CASE_workflow_operator_correlation_display
created: 2026-05-03
---

# CASE: Workflow Operator Correlation Display

## Context
- Type: feature
- Milestone: Real Notes Operator MVP
- User value: operators can connect planner, dry-run, and apply output as one auditable workflow.
- Why now: backend responses already expose canonical action and correlation metadata; the CLI is the remaining visibility gap.
- Risk if deferred: real-notes operator runs remain harder to inspect even though the server provides the needed identifiers.

## Goal
Show workflow action and correlation metadata in `scripts/workflow_operator.rb` dry-run/apply output without changing server contracts.

## Definition of Done
- [ ] CLI dry-run output displays canonical workflow action identity and available correlation identifiers.
- [ ] CLI apply output displays the same workflow identity/correlation fields when returned by the server.
- [ ] Tests/verification: focused CLI/operator spec or equivalent Ruby test plus `docker compose run --rm dev bundle exec rspec <focused spec>`.

## Scope
- In: `scripts/workflow_operator.rb`, focused tests around response rendering, and README wording only if output examples need refreshing.
- Out: endpoint contract changes, new workflow actions, new profile policy, or real-notes smoke scenario expansion.

## Implementation Notes
- Touch likely: `scripts/workflow_operator.rb`, existing script specs if present, otherwise the closest workflow/operator spec surface.
- Approach: reuse response fields already emitted by workflow dry-run/apply/execute paths; keep formatting readable and absent-field tolerant.

## Steps (agent-executable)
1. Inspect current operator CLI rendering and existing workflow response specs to identify available action/correlation fields.
2. Add a small formatter/helper for workflow identity metadata if it keeps dry-run/apply output consistent.
3. Update dry-run and apply output paths to render the metadata when present and skip cleanly when absent.
4. Add focused coverage for dry-run/apply rendering and run the focused verification command.

## Risks / Debt
- Risk: CLI output could become noisy or brittle against optional response fields -> Mitigation: render a compact block and guard missing fields.
- Debt impact: pays down workflow cross-step correlation visibility debt without widening CLI architecture.

## Notes / Open questions
- Assume this slice only consumes existing response metadata; any missing backend field should be reported rather than added here unless trivial and already covered by current contracts.
