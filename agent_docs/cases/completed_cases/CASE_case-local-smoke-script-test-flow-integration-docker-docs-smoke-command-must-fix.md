---
case_id: CASE_case-local-smoke-script-test-flow-integration-docker-docs-smoke-command-must-fix
created: 2026-03-01
---

# CASE: Align Docker Notes Path Docs and Canonical Smoke Command

## Goal
Ensure Docker-related documentation matches actual compose configuration and clearly states the canonical smoke-test invocation in Docker.

## Why this next
- Value: removes misleading setup guidance that can cause avoidable local test/debug failures.
- Dependency/Risk: derisks staging prep by making smoke execution reproducible in the supported Docker workflow.
- Tech debt note: pays down documentation drift introduced when compose mounts/env changed.

## Definition of Done
- [ ] Docker notes path references are consistent with `docker-compose.yml` (`NOTES_ROOT=/notes_repo/notes`) in key docs.
- [ ] Testing docs clearly identify the canonical Docker smoke command as running via `docker compose exec` inside the `dev` container.
- [ ] Documentation also notes when host-run smoke command is optional and why cross-container `dev:4567` may fail host authorization.
- [ ] Tests/verification: validate docs by running `docker compose up -d` then `docker compose exec -T dev bash -lc 'BASE_URL=http://localhost:4567 bash scripts/smoke_local.sh'` and confirming successful completion.

## Scope
**In**
- Update Docker notes path text in `README.md` and `agent_docs/testing/README.md`.
- Update smoke-test section in `agent_docs/testing/README.md` to state canonical Docker command and brief host-authorization caveat.

**Out**
- Any runtime code/config behavior changes to host authorization, Sinatra settings, or networking.

## Proposed approach
Review current docs for path and smoke-command statements that no longer match `docker-compose.yml`. Replace outdated `/notes` references where they describe Docker defaults with `/notes_repo/notes`. In the testing guide, keep the host-run smoke command as optional and add the canonical Docker invocation using `docker compose exec -T dev ... localhost:4567`. Add one concise note that `http://dev:4567` may return host-authorization errors depending on app host checks. Verify by running the documented canonical command successfully.

## Steps (agent-executable)
1. Audit `README.md` and `agent_docs/testing/README.md` for Docker `NOTES_ROOT` references and smoke command guidance.
2. Update Docker path references to match `docker-compose.yml` (`/notes_repo/notes`) where applicable.
3. Update smoke section to include canonical Docker command (`docker compose exec -T dev ... localhost:4567`) and mark host-run command as optional.
4. Add a short host-authorization caveat for cross-container hostnames (e.g., `dev:4567`) without changing runtime behavior.
5. Run the documented canonical smoke command and confirm success.
6. Summarize exact commands run and outcomes in implementation notes.

## Risks / Tech debt / Refactor signals
- Risk: over-updating docs could blur differences between Docker and non-Docker execution contexts. → Mitigation: explicitly label context for each command.
- Debt: duplicate command snippets in multiple docs can drift again.
- Refactor suggestion (if any): consider a single source section for canonical dev/test commands and link to it from other docs.

## Notes / Open questions
- Assumption: current Docker compose service name remains `dev`; if service naming changes, update commands accordingly.
