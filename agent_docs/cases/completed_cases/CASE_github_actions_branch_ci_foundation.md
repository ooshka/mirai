---
case_id: CASE_github_actions_branch_ci_foundation
created: 2026-03-10
---

# CASE: GitHub Actions Branch CI Foundation

## Slice metadata
- Type: hardening
- User Value: branch pushes get an independent pass/fail signal for the full spec suite and lint before manual merge.
- Why Now: the repo already has stable local verification commands and a growing HTTP/runtime-config surface, so branch CI is the smallest operational guardrail that improves review confidence before deployment work begins.
- Risk if Deferred: merges will continue to depend on local agent discipline and machine-specific environments, making regressions and config drift easier to miss until later staging.

## Goal
Add a minimal GitHub Actions workflow that runs the canonical test and lint checks on every pushed branch and by manual dispatch, without coupling the slice to deployment automation.

## Why this next
- Value: creates a clean-environment merge gate for the existing reviewer-driven branch workflow without requiring PR adoption first.
- Dependency/Risk: unblocks safer feature delivery and future deploy work by making full-suite verification repeatable outside the local dev machine.
- Tech debt note: this is a justified hardening slice despite a recent hardening-heavy run because it closes a reliability gap in the active implementation/review loop.

## Definition of Done
- [ ] A GitHub Actions workflow exists under `.github/workflows/` and triggers on push to branches plus `workflow_dispatch`.
- [ ] The workflow runs `bundle exec rspec` and `bundle exec standardrb` as separate CI steps with dependency caching.
- [ ] The workflow does not depend on checking out a separate notes repository for the existing spec suite.
- [ ] Project docs briefly describe the branch-CI intent and the checks the workflow runs.
- [ ] Tests/verification: `bundle exec rspec` and `bundle exec standardrb` still pass locally; first branch push can validate the hosted workflow.

## Scope
**In**
- Add one minimal CI workflow for branch verification in GitHub Actions.
- Prefer native Ruby setup in Actions (`ruby/setup-ruby` + Bundler cache) if it keeps the workflow simpler than Docker Compose while preserving command parity.
- Update lightweight docs for how CI fits the non-PR branch/reviewer flow.

**Out**
- Automated deployment, release workflows, or secrets management.
- End-to-end smoke tests in CI.
- Production container/image packaging changes beyond what CI strictly requires.

## Proposed approach
Use a single workflow job on `ubuntu-latest` that checks out the repo, installs the project Ruby version with Bundler caching, and runs the same `rspec` and `standardrb` commands developers use locally. Prefer native Ruby Actions setup over Docker Compose here because the current specs isolate `NOTES_ROOT` with temporary directories and do not require the external notes bind mount for core verification. Keep the workflow intentionally small: one job, two verification steps, no deploy hooks. Update the testing docs to explain that branch CI is the independent full-suite signal before merge, while local Docker-based commands remain the canonical developer workflow.

## Steps (agent-executable)
1. Add `.github/workflows/ci.yml` with `push` and `workflow_dispatch` triggers.
2. Configure the workflow to use `ruby/setup-ruby` with Bundler caching and the repo’s Gemfile.
3. Add explicit CI steps for `bundle exec rspec` and `bundle exec standardrb`.
4. Confirm the workflow does not assume `../notes_repo` or other local-only Docker mount behavior.
5. Update `README.md` and/or `agent_docs/testing/README.md` with one short section describing branch CI usage and scope.
6. Run local `bundle exec rspec` and `bundle exec standardrb` to ensure the workflow’s commands match a passing local baseline.

## Risks / Tech debt / Refactor signals
- Risk: GitHub-hosted Ruby environment can drift from the local Docker-based dev environment. -> Mitigation: keep CI commands identical to local Bundler commands and avoid extra workflow-only setup logic.
- Risk: missing explicit Ruby-version metadata can make CI less deterministic. -> Mitigation: use the existing project/runtime signal if present; otherwise add the smallest explicit version pin required for `ruby/setup-ruby`.
- Debt: this slice intentionally leaves smoke tests and deployment validation out of CI so the workflow stays small and reliable.
- Refactor suggestion (if any): if additional CI jobs appear later (smoke, packaging, deploy), split shared setup into a composite action or reusable workflow rather than growing one monolithic file.

## Notes / Open questions
- Assumption: automatic branch CI is preferred over reviewer-only manual triggering because it removes the “remember to run CI” failure mode while still fitting the current no-PR workflow.
