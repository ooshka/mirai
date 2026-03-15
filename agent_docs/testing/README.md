# Testing Guide for LLM Agents

This document explains how to verify changes in this repository with the minimum safe test surface.

## Goal

Pick the smallest command set that still verifies the behavior you changed, then report exactly what was run and what passed/failed.
On feature branches, treat branch CI as part of the normal verification flow before considering the work complete.

## Test Infrastructure Summary

- Language/runtime: Ruby
- Web framework: Sinatra
- Test framework: RSpec
- HTTP test helper: `rack-test`
- Lint/style checker: `standard`
- Preferred execution environment: Docker Compose service `dev`

Relevant files:
- `docker-compose.yml`
- `Gemfile`
- `spec/spec_helper.rb`
- `spec/`

## Environment Assumptions

- The app expects `NOTES_ROOT` to exist at runtime (application default: `/notes`).
- In Docker Compose, `NOTES_ROOT=/notes_repo/notes` is configured.
- In local non-Docker runs, ensure Ruby/Bundler dependencies are installed and set required env vars if tests depend on them.
- In tightly sandboxed agent environments, Docker commands require command escalation/approval.

## Sandbox Escalation Requirements

When running as an agent in a restricted sandbox, assume `docker compose ...` commands will fail unless escalated.

Approve only the narrow prefixes needed for verification:
- `docker compose run` (required for test and lint commands)
- `docker compose up` (optional, only for smoke testing)
- `docker compose exec` (optional, for canonical smoke execution inside `dev`)

Avoid broad approvals when possible; prefer the smallest prefix that still allows the required checks.

## Core Verification Commands

Run from repository root.

Branch CI requirement on feature branches:
- GitHub Actions runs `bundle exec rspec` and `bundle exec standardrb` on every branch push and via `workflow_dispatch`.
- Treat CI as the independent hosted verification signal before merge; local Docker Compose commands remain the canonical developer workflow.
- After local verification passes on a feature branch, push the branch and confirm the latest branch CI run is green.
- Do not treat a Case as fully verified on a feature branch until both local checks and branch CI have passed, unless network/CI access is unavailable and that limitation is reported explicitly.

## GitHub Actions CI Verification

When on a feature branch, push the feature branch and ensure it has an upstream before checking GitHub Actions status with the repo CI helper scripts.

Expected timing:
- The current CI workflow is small and typically finishes in well under a minute.
- Recent runs in this repo completed in about 15 to 45 seconds, but queue time can add delay.

Prerequisites:
- `gh` is installed and authenticated for the repository host.
- `jq` is installed locally for the pass/fail helper script.
- Network access to `api.github.com` is available.
- The current branch has been pushed at least once, for example:

```bash
git push -u origin "$(git branch --show-current)"
```

If the branch has not been pushed yet, the commands below may return no runs.

Suggested narrow approval prefixes when a sandboxed agent must shell out to a user shell:
- `/bin/bash scripts/ci_trigger_current_branch.sh`
- `/bin/bash scripts/ci_run_list_current_branch.sh`
- `/bin/bash scripts/ci_watch_latest_branch_run.sh`
- `/bin/bash scripts/ci_view_latest_branch_run.sh`
- `/bin/bash scripts/ci_assert_latest_branch_green.sh`

### List recent runs for the current branch

```bash
/bin/bash scripts/ci_run_list_current_branch.sh
```

Use this to find the latest run `STATUS`, `CONCLUSION`, and run ID for the branch you just pushed.

If this returns no rows, trigger a run by pushing the branch or manually starting the workflow:

```bash
/bin/bash scripts/ci_trigger_current_branch.sh
```

Then re-run `/bin/bash scripts/ci_run_list_current_branch.sh` until a run appears.

### Watch the latest run to completion

```bash
/bin/bash scripts/ci_watch_latest_branch_run.sh
```

This blocks until the latest branch run finishes and exits non-zero if the watched run fails.
If the workflow was just triggered, expect the watch step to usually complete within about a minute.

### View run details for the latest branch run

```bash
/bin/bash scripts/ci_view_latest_branch_run.sh
```

Use this for a human-readable summary of jobs, steps, and the final conclusion.

### Check only the final conclusion programmatically

```bash
/bin/bash scripts/ci_assert_latest_branch_green.sh
```

This exits zero only when the latest branch run is both `completed` and `success`.
If it exits non-zero, either there is no branch run yet or the latest run is not green.

## Local Verification

### Recommended (containerized, reproducible)

```bash
docker compose run --rm dev bundle exec rspec
```

### Run one spec file (faster feedback)

```bash
docker compose run --rm dev bundle exec rspec spec/health_spec.rb
```

### Run a single example by line number

```bash
docker compose run --rm dev bundle exec rspec spec/health_spec.rb:4
```

### Lint/style check

```bash
docker compose run --rm dev bundle exec standardrb
```

## Local Smoke Test

### Optional: run app and smoke-test endpoints

Start server:

```bash
docker compose up
```

Then in another shell:

```bash
curl -sS http://localhost:4567/health
curl -sS http://localhost:4567/config
```

Expected:
- `/health` returns JSON with `{"ok":true}`
- `/config` returns JSON including `notes_root` (typically `"/notes_repo/notes"` in Docker Compose)

### Local end-to-end smoke script

Prerequisites:
- App running locally (for example via `docker compose up`)
- Notes mount contains at least one markdown file (script uses an existing note and reverts the content change)

Canonical Docker run (recommended):

```bash
docker compose exec -T dev bash -lc 'BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh'
```

Optional host run:

```bash
BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh
```

Note:
- `BASE_URL=http://dev:4567` from another container may fail with host-authorization errors (`Host not permitted`) depending on app host checks.

What it covers:
- Health/config checks
- Notes list/read checks
- Patch propose/apply and cleanup revert
- Index rebuild/status/query lifecycle checks

## Agent Verification Workflow

1. Identify change type.
2. Run the narrowest relevant checks first.
3. If behavior changed broadly, run full test suite.
4. If code style changed, run lint.
5. If on a feature branch, push the branch or confirm the current HEAD is already pushed.
6. On a feature branch, run the branch CI helper flow and wait for a green result:
   - `/bin/bash scripts/ci_run_list_current_branch.sh`
   - `/bin/bash scripts/ci_watch_latest_branch_run.sh`
7. Report command list and outcomes, including CI status when applicable.

## Minimal Command Selection by Change Type

- Docs-only changes:
  - Usually no local tests required.
  - If the docs change is on a feature branch that will be reviewed or merged, still run branch CI after pushing so hosted verification stays current for the branch head.
- Small isolated app behavior change with targeted spec coverage:
  - `docker compose run --rm dev bundle exec rspec path/to/spec_file.rb`
  - Then on a feature branch: push and watch branch CI to green.
- New endpoint or request/response behavior:
  - Targeted spec(s), then full suite:
  - `docker compose run --rm dev bundle exec rspec`
  - Then on a feature branch: push and watch branch CI to green.
- Refactor touching shared paths/config/helpers:
  - Full suite + lint:
  - `docker compose run --rm dev bundle exec rspec`
  - `docker compose run --rm dev bundle exec standardrb`
  - Then on a feature branch: push and watch branch CI to green.
- Runtime/config wiring concerns:
  - Optional smoke check with `docker compose up` + `curl`
- Endpoint orchestration or environment-level risk:
  - Run targeted specs first, then smoke:
  - `docker compose run --rm dev bundle exec rspec <relevant-specs>`
  - `BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh`
  - Then on a feature branch: push and watch branch CI to green.

## Upkeep

As the codebase grows (path safety, patching, git operations), extend tests in `spec/` and keep this guide updated with any new mandatory verification commands.
