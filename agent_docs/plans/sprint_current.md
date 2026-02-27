# Current Sprint

## Active Case
- `agent_docs/cases/CASE_patch_proposal_validation_apply.md`

## Sprint Goal
Ship a constrained mutation safety slice for runtime-agent note edits:
- patch proposal validation for unified diffs targeting notes
- controlled patch apply endpoint limited to safe `.md` targets under `NOTES_ROOT`
- test-backed error contracts for invalid patch/path/conflict cases
