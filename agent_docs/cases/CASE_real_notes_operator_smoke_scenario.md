---
case_id: CASE_real_notes_operator_smoke_scenario
created: 2026-05-03
---

# CASE: Real Notes Operator Smoke Scenario

## Context
- Type: feature
- Milestone: Real Notes Operator MVP
- User value: operators get one repeatable proof that dry-run/apply works against a real notes repo path.
- Why now: the CLI now displays workflow correlation metadata, so the next milestone gate is an end-to-end operator proof path.
- Risk if deferred: endpoint specs and CLI unit tests remain disconnected from a realistic operator workflow.

## Goal
Add a documented smoke scenario that runs the workflow operator dry-run/apply loop against a git-backed notes root without requiring live model providers.

## Definition of Done
- [ ] A repeatable smoke command sets up a temporary git-backed notes root, starts `mirai`, runs operator dry-run/apply, and verifies note mutation plus git commit behavior.
- [ ] The scenario uses deterministic local test doubles or existing fake-provider seams; it must not require OpenAI, Ollama, or a developer's real notes.
- [ ] Tests/verification: focused smoke/script spec plus `docker compose run --rm dev bundle exec rspec <focused spec>` and `docker compose run --rm dev bundle exec standardrb`.

## Scope
- In: smoke script or test support under `scripts/`/`spec/`, README operator-smoke documentation, and minimal app hooks only if needed for deterministic local provider behavior.
- Out: hosted/local provider matrix coverage, model quality evaluation, new workflow endpoint contracts, or web UI work.

## Implementation Notes
- Touch likely: `scripts/`, `spec/scripts/` or request specs, `README.md`.
- Approach: prefer a fast Ruby/RSpec-backed smoke around existing Rack/app seams before adding shell-heavy orchestration.

## Steps (agent-executable)
1. Inspect current smoke scripts, workflow operator specs, and test support for temporary notes-root setup.
2. Add the smallest deterministic smoke path that exercises operator dry-run/apply against a temporary git notes repo.
3. Assert output includes dry-run/apply markers and verify the target note content plus git commit after apply.
4. Document the command and run focused verification plus lint.

## Risks / Debt
- Risk: smoke setup could become slow or environment-sensitive -> Mitigation: keep providers stubbed/fake and notes root temporary.
- Debt impact: reduces gap between endpoint-level coverage and real operator milestone proof without adding provider-routing complexity.

## Notes / Open questions
- If a true subprocess app server is too heavy, an RSpec smoke that drives the CLI against a deterministic local HTTP test server is acceptable only if it also validates git-backed mutation semantics through existing app code.
