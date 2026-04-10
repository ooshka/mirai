---
case_id: CASE_workflow_model_selection_profile_seam
created: 2026-04-10
---

# CASE: Workflow Model Selection Profile Seam

## Slice metadata
- Type: feature
- User Value: lets workflow callers choose a local, hosted, or automatic model profile per run without editing process-wide provider environment variables.
- Why Now: the dry-run trace now exposes provider/model identity and the roadmap's real-notes MVP needs an operator-facing `local|hosted|auto` choice before the CLI dry-run/apply loop can be useful.
- Risk if Deferred: the upcoming CLI loop will either keep relying on process-wide provider settings or invent client-local routing rules that `mirai` later has to pull back into the server contract.

## Goal
Add one server-owned workflow model profile selection seam that can route planner and drafter construction for a single workflow request while preserving the common validation, audit, patch, commit, and index safety path.

## Why this next
- Value: moves the workflow MVP from static environment-based provider selection toward an operator-selectable run profile.
- Dependency/Risk: directly unblocks the CLI operator dry-run/apply loop by giving it a stable request field and response trace identity to use.
- Tech debt note: pays down process-wide provider coupling, but intentionally defers richer capability policy and fallback implementation until the first profile contract is proven.

## Definition of Done
- [ ] Workflow plan, draft, apply, and execute request handling accept one optional profile selector for the first supported values: `hosted`, `local`, and `auto`.
- [ ] Profile selection is normalized and validated in a small server-owned object or helper rather than scattered through route handlers; invalid profile values fail deterministically with workflow request errors.
- [ ] `hosted` selects OpenAI-backed planner/drafter clients, `local` selects local planner/drafter clients, and `auto` initially resolves through a documented deterministic default without implementing broad fallback or quality-based routing.
- [ ] Dry-run/apply/execute audit or trace output reports the resolved provider/model identity so operators can see which profile actually ran.
- [ ] Existing environment defaults continue to work when no profile is supplied, preserving current smoke and request-spec behavior.
- [ ] Focused request/service specs cover default behavior, explicit hosted/local selection, invalid profile rejection, and trace identity for the resolved drafter path.
- [ ] README workflow docs describe the new optional profile selector, supported values, and the fact that `auto` is a deterministic first-step policy rather than adaptive fallback.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_workflow_plan_spec.rb spec/mcp_workflow_draft_patch_spec.rb spec/mcp_workflow_apply_patch_spec.rb spec/mcp_workflow_execute_spec.rb spec/services/llm/workflow_planner_spec.rb spec/services/llm/workflow_patch_drafter_spec.rb`

## Scope
**In**
- Define the first workflow profile selector contract for plan/draft/apply/execute requests.
- Add minimal provider resolution plumbing around current planner and drafter client factories.
- Preserve the existing process-wide env provider settings as the no-profile default.
- Update focused request/service specs and README workflow docs.

**Out**
- Building adaptive fallback from local to hosted on provider failure.
- Capability matrix enforcement beyond the three first profile names.
- Changing mutation safety, patch validation, git commit, semantic ingestion, or index lifecycle behavior.
- Adding new model defaults beyond the current configured workflow model value.
- Building the CLI operator loop itself.

## Proposed approach
Introduce a small workflow profile resolver near the LLM workflow services that accepts `nil`, `hosted`, `local`, or `auto` and returns planner/drafter provider choices plus a resolved profile label. Thread the optional profile from workflow request payloads through route/helper construction into the existing planner and drafter factories, leaving the current environment-derived providers untouched when the selector is absent. Keep `auto` deterministic in this first slice, likely by resolving to the current environment defaults or a simple documented preference, and report the resolved provider/model in existing plan provider fields and draft/apply/execute trace/audit metadata. Avoid changing patch execution semantics; the selected profile should affect model calls only.

## Steps (agent-executable)
1. Inspect current workflow request parsing, planner/drafter factory construction, and trace metadata in `app/routes/mcp_helpers.rb`, `app/routes/mcp_routes.rb`, and the workflow request specs.
2. Add a small workflow model profile resolver with focused unit coverage for `nil`, `hosted`, `local`, `auto`, and invalid values.
3. Extend workflow request parsing so optional profile data can be read from plan requests and canonical `workflow.draft_patch` action params without breaking existing payloads.
4. Thread the resolved planner and drafter providers into `WorkflowPlannerClientFactory`, `WorkflowPatchClientFactory`, `WorkflowPlanner`, and workflow trace metadata construction.
5. Update request specs for plan, draft, apply, and execute to cover default behavior, explicit hosted/local profile behavior, invalid profile rejection, and trace identity.
6. Update README workflow docs with the profile selector contract and the current deterministic `auto` behavior.
7. Run the focused verification command and add any adjacent service spec needed if profile resolution is not already covered by request specs.

## Risks / Tech debt / Refactor signals
- Risk: `auto` could imply adaptive fallback before the system has capability evidence. -> Mitigation: document it as deterministic in this slice and keep real fallback/capability routing out of scope.
- Risk: passing profile selection through route helpers could spread provider policy across endpoints. -> Mitigation: centralize normalization/resolution in one small resolver and keep route code as plumbing.
- Debt: this adds a modest profile layer before full capability policy exists, but it reduces the larger debt of process-wide model selection for operator workflows.
- Refactor suggestion (if any): if planner and drafter construction keep gaining shared provider/model policy, extract a workflow runtime factory after this slice rather than expanding endpoint-local helper methods.

## Notes / Open questions
- Assumption: `hosted` means the existing OpenAI workflow provider and `local` means the existing local OpenAI-compatible provider.
- Assumption: `auto` should not call two providers or retry across providers in this first slice; it should resolve once and be visible in trace/audit metadata.
