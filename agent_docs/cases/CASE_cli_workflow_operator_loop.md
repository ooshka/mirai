---
case_id: CASE_cli_workflow_operator_loop
created: 2026-04-10
---

# CASE: CLI Workflow Operator Loop

## Slice metadata
- Type: feature
- User Value: gives an operator one repo-local command to submit a note-update intent, choose `local|hosted|auto`, inspect the dry-run trace, and explicitly apply the drafted patch without hand-crafting HTTP requests.
- Why Now: `mirai` now has the canonical workflow draft/apply/execute surfaces plus per-run profile selection, so the next MVP gap is an operator entrypoint that exercises those contracts against real notes.
- Risk if Deferred: real-notes workflow testing stays trapped in ad hoc curl payloads, which slows iteration on model-profile behavior and increases the chance that thin clients invent their own request and audit conventions.

## Goal
Add one minimal CLI operator command that runs the existing workflow dry-run/apply loop against `mirai` using the new `local|hosted|auto` profile seam.

## Why this next
- Value: turns the recent workflow contract work into a usable operator path for real-note testing, which is the stated near-term MVP direction in the roadmap.
- Dependency/Risk: builds directly on the completed dry-run trace contract and workflow model-profile seam without waiting for broader planner-envelope cleanup or a frontend.
- Tech debt note: pays down manual operator glue, but intentionally stops short of a richer session shell, retry flow, or prompt-management layer.

## Definition of Done
- [ ] There is one documented repo-local CLI entrypoint that accepts intent/instruction, note path, and optional `--profile local|hosted|auto`, then calls `POST /mcp/workflow/draft_patch`.
- [ ] The CLI prints a bounded dry-run summary using the server-owned trace, including selected profile/provider/model, target path, validation/apply readiness, and the drafted patch or a clearly labeled patch section.
- [ ] The same command supports one explicit apply step that calls `POST /mcp/workflow/apply_patch` only after operator confirmation or an explicit apply flag; dry-run remains the default.
- [ ] CLI request/response handling preserves the canonical `workflow.draft_patch` action envelope instead of inventing a CLI-specific workflow contract.
- [ ] Focused tests or script-level verification cover one successful dry-run path, one apply path, and one API error/reporting path.
- [ ] README and any targeted testing docs explain the command, required environment/base URL assumptions, and how `local|hosted|auto` maps to the workflow profile seam.
- [ ] Tests/verification: add one focused automated check for the CLI request shaping/response handling plus a documented manual smoke command against a running local app.

## Scope
**In**
- One thin CLI script or command wrapper under repo-owned tooling.
- Dry-run-first operator flow over existing workflow draft/apply endpoints.
- Optional apply confirmation/flag behavior.
- Documentation and focused verification for the new command.

**Out**
- A TUI, REPL, or long-lived interactive shell.
- New workflow server endpoints or contract changes beyond what the CLI consumes.
- Automatic retry/fallback routing between profiles.
- Prompt separation or model-capability policy beyond passing the selected profile through the existing seam.

## Proposed approach
Implement a small CLI wrapper around the current canonical `workflow.draft_patch` action contract rather than adding another server-side workflow layer. The command should collect the operator's instruction, path, and optional `profile`, POST the existing action envelope to `/mcp/workflow/draft_patch`, render the returned dry-run trace in a readable terminal format, and stop there by default. When the operator explicitly requests apply, the same command should reuse the same payload against `/mcp/workflow/apply_patch` after a confirmation gate so mutation remains deliberate. Keep transport and formatting logic local to the CLI entrypoint, and reuse server-owned trace/audit fields instead of re-deriving provider or patch metadata client-side. Likely touch points are a new script under `scripts/`, README workflow usage docs, and a focused spec for CLI request shaping or helper behavior.

## Steps (agent-executable)
1. Inspect existing repo scripts and workflow docs to choose the smallest command surface that matches local development conventions.
2. Add one CLI entrypoint that accepts instruction, path, base URL, and optional `--profile`, and builds the canonical `workflow.draft_patch` request payload.
3. Implement dry-run request handling and bounded terminal rendering from the server-owned trace fields, keeping dry-run the default behavior.
4. Add an explicit apply path that reuses the same payload against `/mcp/workflow/apply_patch`, guarded by confirmation or an apply flag.
5. Add focused automated coverage for payload shaping/response handling and one error-reporting path, plus document a manual smoke command for real-note usage.
6. Update README and any targeted testing guidance so operators know the prerequisites and expected dry-run/apply flow.

## Risks / Tech debt / Refactor signals
- Risk: the CLI could drift from canonical workflow payloads and become another contract owner. -> Mitigation: post the existing `workflow.draft_patch` action envelope unchanged and treat server responses as the source of truth.
- Risk: terminal formatting could overfit the current trace shape and become brittle as audit fields evolve. -> Mitigation: keep formatting narrow and centered on documented trace fields already intended for operator inspection.
- Debt: pays down ad hoc manual workflow invocation; adds a small client surface that may later want shared request/format helpers if more operator commands appear.
- Refactor suggestion (if any): if multiple operator commands emerge, extract shared CLI transport/render helpers after this first command proves stable instead of introducing a CLI framework now.

## Notes / Open questions
- Assumption: one command with dry-run default and explicit apply support is the right first operator shape; a richer interactive loop can remain a later slice if real use justifies it.
- Assumption: the command can target a running local `mirai` app via configurable base URL rather than owning app bootstrapping.
