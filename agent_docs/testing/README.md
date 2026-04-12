# Testing Guide for LLM Agents

This document explains how to verify changes in this repository with the minimum safe test surface.

## Goal

Pick the smallest command set that still verifies the behavior you changed, then report exactly what was run and what passed/failed.
On feature branches, treat branch CI as part of the normal verification flow before considering the work complete.
Default to targeted local verification; only broaden to full local suite runs when the touched surface is shared enough that targeted checks would leave obvious blind spots.

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

Local-vs-CI balance:
- Prefer targeted local specs that exercise the changed implementation details directly.
- Do not run the full local suite by default just because CI exists or because a request/response contract changed.
- Use the full local suite when changes touch shared wiring, broad config/runtime behavior, or common helpers where targeted coverage is unlikely to expose integration regressions quickly.
- Let branch CI provide the broad clean-environment regression signal after the targeted local checks pass.

## GitHub Actions CI Verification

When on a feature branch, use the repo CI helper script to push the branch and check GitHub Actions status for the current branch.

Expected timing:
- The current CI workflow is small and typically finishes in well under a minute.
- Recent runs in this repo completed in about 15 to 45 seconds, but queue time can add delay.

Prerequisites:
- `gh` is installed and authenticated for the repository host.
- `jq` is installed locally for the pass/fail helper script.
- Network access to `api.github.com` is available.

Suggested narrow approval prefixes when a sandboxed agent must shell out to a user shell:
- `/bin/bash scripts/ci_current_branch.sh`

### Push the current branch and set upstream

```bash
/bin/bash scripts/ci_current_branch.sh push
```

Use this when the branch has not been pushed yet or when you want an explicit push step before inspecting CI.

### Push the current branch and require a green CI run for the current HEAD

```bash
/bin/bash scripts/ci_current_branch.sh verify
```

This is the canonical agent flow on feature branches. It pushes `HEAD`, waits for the matching branch CI run to appear, watches it to completion, and exits non-zero unless that exact run succeeds.

### List recent runs for the current branch

```bash
/bin/bash scripts/ci_current_branch.sh list
```

Use this to find the latest run `STATUS`, `CONCLUSION`, and run ID for the branch you just pushed.

If this returns no rows, trigger a run by pushing the branch or manually starting the workflow:

```bash
/bin/bash scripts/ci_current_branch.sh trigger
```

Then re-run `/bin/bash scripts/ci_current_branch.sh list` until a run appears.

### Watch the latest run to completion

```bash
/bin/bash scripts/ci_current_branch.sh watch
```

This blocks until the latest branch run finishes and exits non-zero if the watched run fails.
If the workflow was just triggered, expect the watch step to usually complete within about a minute.

### View run details for the latest branch run

```bash
/bin/bash scripts/ci_current_branch.sh view
```

Use this for a human-readable summary of jobs, steps, and the final conclusion.

### Check only the final conclusion programmatically

```bash
/bin/bash scripts/ci_current_branch.sh assert
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
- `MCP_WORKFLOW_PLANNER_ENABLED=true`
- `MCP_WORKFLOW_PLANNER_PROVIDER=local`
- `MCP_WORKFLOW_DRAFTER_PROVIDER=local`
- `MCP_OPENAI_WORKFLOW_MODEL` is set to a local workflow model name that exists on the configured runtime (for example `qwen2.5:7b-instruct`)
- `MCP_LOCAL_WORKFLOW_BASE_URL` points at a reachable OpenAI-compatible local workflow runtime

Docker Compose defaults `MCP_LOCAL_WORKFLOW_BASE_URL` to `http://host.docker.internal:11434` and maps `host.docker.internal` to the host gateway so the `dev` container can reach a locally running Ollama instance. Override the env var if your runtime is elsewhere.

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
- Workflow plan -> canonical `workflow.draft_patch` handoff -> dry-run draft patch checks
- Patch propose/apply and cleanup revert
- Index rebuild/status/query lifecycle checks

If workflow planning is disabled or the local workflow providers are not configured, the smoke script now fails early with a prerequisite error instead of silently skipping the workflow section.

## Workflow Operator MVP Scenario Pack

Use this when you want the operator-facing real-notes MVP path rather than the lower-level local smoke script.

Prerequisites:
- App running locally and reachable at the selected `--base-url`
- Notes mount contains the target markdown note path
- The profile paths you plan to exercise are configured on the running app
- Review the dry-run output before running any apply scenario

Canonical dry-run pack:

```bash
ruby scripts/workflow_operator_mvp_scenarios.rb \
  --path notes/today.md \
  --base-url http://localhost:4567
```

Optional explicit apply follow-up:

```bash
ruby scripts/workflow_operator_mvp_scenarios.rb \
  --path notes/today.md \
  --base-url http://localhost:4567 \
  --include-apply \
  --apply-profile local \
  --yes
```

What to inspect in each scenario:
- requested profile
- resolved provider/model
- target path
- validation status and apply readiness
- drafted patch content

Boundary note:
- This scenario pack is intentionally profile-based (`local` and `hosted`) rather than model-name-based.
- Model capability evidence remains owned by `local_llm`; this pack verifies the `mirai` operator path.

## Agent Verification Workflow

1. Identify change type.
2. Run the narrowest relevant checks first.
3. Stay targeted unless the change touches shared wiring, runtime config, or other broad integration seams.
4. Run the full local suite only when the changed surface is broad enough that targeted specs would be a weak signal.
5. If code style changed or new files were added, run lint for the touched files or the relevant scope.
6. Use smoke checks only when runtime wiring or orchestration risk justifies them.
7. If on a feature branch, push the branch or confirm the current HEAD is already pushed.
8. On a feature branch, run the branch CI helper flow and wait for a green result:
   - Prefer `/bin/bash scripts/ci_current_branch.sh verify`
   - Or use `/bin/bash scripts/ci_current_branch.sh list`
   - Then `/bin/bash scripts/ci_current_branch.sh watch`
9. Report command list and outcomes, including CI status when applicable.

## Minimal Command Selection by Change Type

- Docs-only changes:
  - Usually no local tests required.
  - If the docs change is on a feature branch that will be reviewed or merged, still run branch CI after pushing so hosted verification stays current for the branch head.
- Small isolated app behavior change with targeted spec coverage:
  - `docker compose run --rm dev bundle exec rspec path/to/spec_file.rb`
  - Then on a feature branch: push and watch branch CI to green.
- New endpoint or request/response behavior:
  - Target the request spec plus the closest service/spec seam first:
  - `docker compose run --rm dev bundle exec rspec <relevant-request-specs> <relevant-service-specs>`
  - Only add the full local suite if the endpoint change also touched shared wiring, shared helpers, or broad runtime config.
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
