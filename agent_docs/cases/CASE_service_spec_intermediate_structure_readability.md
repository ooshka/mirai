---
case_id: CASE_service_spec_intermediate_structure_readability
created: 2026-03-03
---

# CASE: Service/Spec Intermediate Structure Readability

## Slice metadata
- Type: refactor
- User Value: contributors can navigate service and test code faster, reducing review and onboarding friction.
- Why Now: service and spec file counts have grown and top-level flat directories are becoming scan-heavy during feature work.
- Risk if Deferred: continued flat growth will increase merge friction and make architectural boundaries harder to preserve.

## Goal
Introduce intermediate directory structure for core service domains and matching specs so repository navigation is clearer without changing behavior.

## Why this next
- Value: improves repo readability at a glance and reduces time-to-locate logic/tests during ongoing feature delivery.
- Dependency/Risk: low behavioral risk because this is file organization and require-path rewiring only.
- Tech debt note: pays down structure debt from early flat-layout velocity while avoiding a broad architecture rewrite.

## Definition of Done
- [ ] Introduce intermediate folders for selected service domains (`retrieval`, `indexing`, `notes`, `patch`) and move relevant files.
- [ ] Mirror moved units in `spec/services/...` folders and keep spec discovery/execution unchanged.
- [ ] Update require paths/wiring so app boot and existing endpoint contracts behave exactly as before.
- [ ] README or contributor docs include a short note describing the new layout intent.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- File moves for a bounded subset of services and directly associated unit specs.
- Minimal require/path updates in app boot and spec files.
- One short documentation note about the folder conventions.

**Out**
- Behavior or contract changes to MCP endpoints.
- Renaming classes/modules solely for style.
- Large dependency injection or architecture rewrites.

## Proposed approach
Create domain-focused intermediate folders under `app/services/` and group high-churn files by responsibility instead of leaving everything at top-level. Mirror that structure in `spec/services/` for service-level tests so code and tests stay mentally paired. Keep class names stable and rely on deterministic `require_relative` updates to preserve runtime behavior. Use a small, explicit move map so the refactor stays reviewable and reversible.

## Steps (agent-executable)
1. Define a move map for selected service files into `app/services/retrieval/`, `app/services/indexing/`, `app/services/notes/`, and `app/services/patch/`.
2. Move corresponding service specs into `spec/services/<domain>/` with no example-behavior changes.
3. Update `require_relative` paths in moved files and app/spec entry points.
4. Run full RSpec and fix any load-order/path regressions.
5. Update docs with a brief “service/spec folder conventions” note.

## Risks / Tech debt / Refactor signals
- Risk: missed require-path updates could cause boot/test load failures. -> Mitigation: explicit move checklist plus full-suite run.
- Debt: pays down directory sprawl and weak domain signaling in service/spec layout.
- Refactor suggestion (if any): if this pattern holds, add a lightweight naming/loading convention to keep future files in-domain by default.

## Notes / Open questions
- Assumption: keep constant/module names unchanged in this slice to avoid coupling structural cleanup with semantic renames.
