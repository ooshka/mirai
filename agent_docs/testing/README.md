# Testing Guide for LLM Agents

This document explains how to verify changes in this repository with the minimum safe test surface.

## Goal

Pick the smallest command set that still verifies the behavior you changed, then report exactly what was run and what passed/failed.

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

- The app expects `NOTES_ROOT` to exist at runtime (defaults to `/notes`).
- In Docker, `NOTES_ROOT=/notes` is already configured.
- In local non-Docker runs, ensure Ruby/Bundler dependencies are installed and set required env vars if tests depend on them.
- In tightly sandboxed agent environments, Docker commands require command escalation/approval.

## Sandbox Escalation Requirements

When running as an agent in a restricted sandbox, assume `docker compose ...` commands will fail unless escalated.

Approve only the narrow prefixes needed for verification:
- `docker compose run` (required for test and lint commands)
- `docker compose up` (optional, only for smoke testing)

Avoid broad approvals when possible; prefer the smallest prefix that still allows the required checks.

## Core Verification Commands

Run from repository root.

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
- `/config` returns JSON including `notes_root` (typically `"/notes"` in Docker)

## Agent Verification Workflow

1. Identify change type.
2. Run the narrowest relevant checks first.
3. If behavior changed broadly, run full test suite.
4. If code style changed, run lint.
5. Report command list and outcomes.

## Minimal Command Selection by Change Type

- Docs-only changes:
  - Usually no tests required.
- Small isolated app behavior change with targeted spec coverage:
  - `docker compose run --rm dev bundle exec rspec path/to/spec_file.rb`
- New endpoint or request/response behavior:
  - Targeted spec(s), then full suite:
  - `docker compose run --rm dev bundle exec rspec`
- Refactor touching shared paths/config/helpers:
  - Full suite + lint:
  - `docker compose run --rm dev bundle exec rspec`
  - `docker compose run --rm dev bundle exec standardrb`
- Runtime/config wiring concerns:
  - Optional smoke check with `docker compose up` + `curl`

## Current Baseline

At time of writing, the repository contains a minimal HTTP health spec:
- `spec/health_spec.rb`

As the codebase grows (path safety, patching, git operations), extend tests in `spec/` and keep this guide updated with any new mandatory verification commands.
