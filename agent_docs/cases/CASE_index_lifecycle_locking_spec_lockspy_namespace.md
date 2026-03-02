---
case_id: CASE_index_lifecycle_locking_spec_lockspy_namespace
created: 2026-03-02
---

# CASE: LockSpy Namespacing In Index Lifecycle Locking Spec

## Goal
Prevent future test constant collisions by scoping or namespacing `LockSpy` used in index lifecycle locking specs.

## Why this next
- Value: improves long-term spec maintainability as the suite grows.
- Dependency/Risk: reduces accidental constant reuse conflicts across specs.
- Tech debt note: addresses a small but recurring Ruby spec hygiene risk.

## Definition of Done
- [ ] `LockSpy` is no longer a top-level constant in `spec/mcp_index_lifecycle_locking_spec.rb`.
- [ ] Spec behavior and assertions remain unchanged.
- [ ] Tests/verification: `bundle exec rspec spec/mcp_index_lifecycle_locking_spec.rb`

## Scope
**In**
- Local refactor in `spec/mcp_index_lifecycle_locking_spec.rb` for helper class/module scoping.
- Minimal formatting or naming updates required by this refactor.

**Out**
- Changes to runtime lock implementation.
- Broader spec architecture cleanup.

## Proposed approach
Move `LockSpy` into a local namespace (for example a spec support module or a namespaced constant) to avoid global constant pollution while preserving test readability.

## Steps (agent-executable)
1. Refactor `LockSpy` definition to avoid top-level constant scope.
2. Update local references in the same spec file.
3. Run the targeted locking spec to confirm behavior parity.

## Risks / Tech debt / Refactor signals
- Risk: over-abstracting a tiny helper can reduce readability. -> Mitigation: keep the helper colocated and small.
- Debt: pays down test namespace pollution risk.
- Refactor suggestion (if any): if multiple specs need lock doubles, introduce a shared `spec/support` helper with explicit require.

## Notes / Open questions
- Assumption: this helper remains specific to locking behavior tests unless reused intentionally.
