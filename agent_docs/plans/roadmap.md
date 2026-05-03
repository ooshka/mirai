# Roadmap

## North Star

`mirai` is a deterministic, safety-first agent harness for git-backed markdown knowledge state. The first product surface is notes: model-assisted read, plan, draft, validate, mutate, commit, and re-index workflows must be predictable, auditable, provider-aware, and safe by default.

## Current Milestone

### Real Notes Operator MVP

Outcome: an operator can run a scoped note-update workflow against a real notes mount, inspect the dry-run, choose a local or hosted profile, and explicitly apply approved changes through the existing patch, commit, audit, and index safety path.

Exit criteria:
- [ ] A real notes repo can be mounted and targeted without weakening path, policy, or patch validation.
- [ ] The operator CLI can run a dry-run for a scoped note edit and display the selected path, profile/model identity, edit intent, generated patch, validation result, apply readiness, and correlation metadata.
- [ ] The operator CLI can apply the approved dry-run through the server-owned patch/commit/index path.
- [ ] At least one hosted workflow path and one local workflow path are documented or smoke-tested for the same bounded operator scenario.
- [ ] The README documents the canonical real-notes dry-run/apply workflow and the expected safety boundaries.

## Milestone Ladder

1. Real Notes Operator MVP
- Owner: `mirai`
- Purpose: prove the core product loop with real notes before adding broader routing, retrieval quality, or UI surface area.
- Exit: operator dry-run and apply work end-to-end with auditable hosted/local profile evidence.

2. Provider Choice MVP
- Owner: `mirai`, backed by `local_llm`
- Purpose: let callers choose hosted, local, or later automatic profiles by capability without changing mutation safety behavior.
- Exit: request/profile selection is explicit, documented, and covered for workflow planner/drafter paths; unsafe or unsupported profile choices fail closed.

3. Knowledge Interaction MVP
- Owner: `mirai`
- Purpose: connect retrieval, question answering, and bounded note-edit workflows so the harness can support useful knowledge work instead of isolated endpoint demos.
- Exit: an operator can query notes, inspect why results matched, and initiate a scoped edit from selected context while preserving explicit approval.

4. Product Surface MVP
- Owner: `mirai`
- Purpose: add a minimal web/operator surface after backend contracts are stable enough to avoid frontend churn.
- Exit: browser UI supports knowledge Q&A, dictated or captured knowledge input, dry-run review, explicit apply, and basic repository status.

## Cross-Repo Contract

- `mirai` owns MCP/API contracts, mutation safety, workflow orchestration, provider/profile policy, audit shape, and user-facing operator behavior.
- `local_llm` owns local runtime evidence, retrieval artifacts, workflow fixtures, capability measurements, and local-provider failure interpretation.
- Handoff rule: `local_llm` proves provider behavior; `mirai` decides product/API behavior and keeps all providers on the same safety path.
- Contract-change rule: while external consumers are still limited, prefer clean coordinated contract changes over compatibility shims that preserve ambiguous early shapes.

## Next Slices

1. Hosted And Local Profile Smoke Coverage
- Repo: `mirai`, backed by `local_llm`
- Advances: Real Notes Operator MVP and Provider Choice MVP
- Why next: proves the same bounded workflow can run through both provider families while preserving shared validation and apply semantics.

2. LockSpy Namespacing In Index Lifecycle Locking Spec
- Repo: `mirai`
- Advances: maintenance guardrail, not the current milestone directly
- Why next: keep queued as small hardening only when index lifecycle specs are already being touched or suite growth makes the collision risk active.
