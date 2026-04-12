---
case_id: CASE_workflow_operator_real_notes_mvp_scenario_pack
created: 2026-04-12
---

# CASE: Workflow Operator Real-Notes MVP Scenario Pack

## Slice metadata
- Type: feature
- User Value: gives operators one documented, repeatable way to exercise the existing workflow CLI against real notes with both local and hosted profile paths before a frontend exists.
- Why Now: the workflow operator CLI, dry-run trace contract, and per-run `local|hosted|auto` profile seam have all landed, so the next MVP gap is a small scenario pack that proves those seams work together on real notes without ad hoc command assembly.
- Risk if Deferred: real-note testing will remain informal and inconsistent, slowing profile evaluation, weakening reviewability, and increasing the chance that later clients invent their own operator conventions.

## Goal
Add one small workflow-operator scenario pack that makes the real-notes MVP path obvious, repeatable, and reviewable across at least one local-profile run and one hosted or hosted-profile run.

## Why this next
- Value: turns the recent workflow feature stack into an operator-usable verification path instead of leaving it spread across README snippets and ad hoc shell history.
- Dependency/Risk: builds directly on completed CLI/profile/trace work without reopening workflow contract design.
- Tech debt note: pays down operator-run drift, but intentionally avoids a larger scenario framework or per-model capability matrix inside `mirai`.

## Definition of Done
- [ ] There is one repo-owned scenario pack for the workflow operator CLI, likely under `scripts/` and/or `agent_docs/testing/`, that documents or runs the real-notes MVP flow from dry run through optional apply.
- [ ] The scenario pack covers at least two profile-oriented paths: one `--profile local` run and one `--profile hosted` or hosted-default run.
- [ ] Each scenario makes the required preconditions explicit, including app startup, notes mount expectations, workflow profile prerequisites, and any provider configuration assumptions.
- [ ] The scenario output or docs show the operator what to inspect in the existing CLI dry-run trace: selected profile, resolved provider/model, target path, validation/apply readiness, and drafted patch content.
- [ ] The pack stays profile-based rather than model-name-based; it must not turn `mirai` into the owner of a per-model capability matrix.
- [ ] Focused automated coverage exists for any new helper logic introduced by the scenario pack, and manual verification instructions are documented for the real-notes path.
- [ ] README and targeted testing docs point to the scenario pack as the canonical MVP operator verification path.

## Scope
**In**
- One small scenario pack or runner for `scripts/workflow_operator.rb`.
- Local-profile and hosted-profile real-notes flows.
- Clear preconditions, invocation commands, and expected operator checks.
- Minimal test/doc updates needed to keep the scenario pack trustworthy.

**Out**
- New workflow endpoints or workflow contract changes.
- A model-by-model smoke matrix.
- Automatic profile fallback or retry orchestration.
- A TUI, REPL, or broader operator shell.

## Proposed approach
Treat this as an operator verification slice, not a backend workflow redesign. Build a thin scenario pack around the existing `scripts/workflow_operator.rb` entrypoint so the repo has one obvious path for real-note MVP testing. Prefer a small script plus concise documentation over prose-only notes or a large bash harness: the goal is to make the local/hosted profile flows easy to run and review while reusing the existing server-owned dry-run/apply contracts and trace fields. Keep assertions bounded to operator-visible contract signals rather than model-specific content quality.

## Steps (agent-executable)
1. Inspect the current workflow operator CLI, README workflow docs, and testing guidance to identify the smallest reusable scenario surface.
2. Add a small scenario pack or runner that invokes `scripts/workflow_operator.rb` for a local-profile dry run and a hosted or hosted-default dry run against a real notes mount.
3. Make scenario prerequisites explicit, including environment/config expectations and which note path/instruction shape the operator should use.
4. Ensure the scenario pack highlights the trace fields the operator must inspect before apply, without reimplementing server-side validation logic.
5. Add an optional apply-oriented scenario or documented manual follow-up step that keeps apply explicit and deliberate.
6. Add focused automated coverage for any new helper or formatting code introduced by the scenario pack.
7. Update `README.md` and `agent_docs/testing/README.md` to make this the canonical real-notes MVP verification path.

## Risks / Tech debt / Refactor signals
- Risk: a scripted scenario could become brittle if it hard-codes trace formatting that belongs to the CLI or server. -> Mitigation: validate only stable operator-facing fields already exposed by the CLI and dry-run contract.
- Risk: mixing profile verification with model-specific expectations would create the wrong ownership boundary in `mirai`. -> Mitigation: keep scenarios framed around `local|hosted|auto` profiles and contract signals, not concrete model SKUs or quality scoring.
- Debt: may temporarily keep scenario orchestration and command examples split between script and docs until there is evidence for a richer shared smoke helper.
- Refactor signal: if more operator scenarios appear, extract a small shared helper for CLI invocation and trace checks instead of duplicating shell glue across scripts.

## Notes / Open questions
- Assumption: the first scenario pack can rely on a running local app and a real notes mount rather than owning app/bootstrap lifecycle.
- Assumption: one local and one hosted profile path are enough for the first MVP slice; `auto` can remain a follow-on unless implementation stays trivially small.

