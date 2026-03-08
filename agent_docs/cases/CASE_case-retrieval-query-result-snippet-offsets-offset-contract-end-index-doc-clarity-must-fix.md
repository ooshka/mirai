---
case_id: CASE_case-retrieval-query-result-snippet-offsets-offset-contract-end-index-doc-clarity-must-fix
created: 2026-03-08
---

# CASE: Document Snippet Offset Index Semantics Explicitly

## Slice metadata
- Type: docs
- User Value: prevents client-side parsing mistakes by making `snippet_offset` index semantics explicit and unambiguous.
- Why Now: the new response field is implemented, but README currently does not explicitly state whether `end` is inclusive or exclusive.
- Risk if Deferred: integrators may implement incorrect highlight slicing and produce off-by-one rendering bugs.

## Goal
Update project docs and contract-facing tests to explicitly define `snippet_offset.start`/`end` semantics.

## Why this next
- Value: improves API contract clarity immediately after introducing a new response field.
- Dependency/Risk: no behavior changes required; this is a narrow documentation/contract-hardening follow-up.
- Tech debt note: pays down ambiguity debt from the initial feature rollout.

## Definition of Done
- [ ] README explicitly states offset index semantics (including whether `end` is exclusive).
- [ ] At least one request/spec assertion reflects and protects the documented offset interpretation.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_index_query_spec.rb`

## Scope
**In**
- Documentation clarification for `snippet_offset` contract.
- Minimal spec assertion updates/additions tied to offset semantics clarity.

**Out**
- Changes to offset computation behavior.
- Additional snippet metadata fields.

## Proposed approach
Add a concise, explicit contract statement in README for `snippet_offset` index interpretation (`start` zero-based inclusive, `end` exclusive if that is current behavior). Add a focused spec expectation that would fail if interpretation changes unexpectedly.

## Steps (agent-executable)
1. Confirm current implementation semantics for `start` and `end`.
2. Update README query endpoint section with explicit index interpretation language.
3. Add/adjust one targeted request/spec assertion to anchor the documented behavior.
4. Run the targeted query spec to verify no regressions.

## Risks / Tech debt / Refactor signals
- Risk: docs may claim semantics that differ from implementation. -> Mitigation: derive wording directly from current behavior and lock it in spec.
- Debt: none; this reduces contract ambiguity debt.
- Refactor suggestion (if any): if more positional metadata is added later, centralize response-field docs in a dedicated API contract section.

## Notes / Open questions
- Assumption: zero-based character offsets are the intended unit for this v1 contract.
