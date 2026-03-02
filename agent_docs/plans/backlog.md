# Backlog

## Next 3 Candidate Slices

1. Action Policy Identity Context Storage Clarity
- Value: clarifies whether policy identity context is truly needed as stored state and reduces ambiguity in policy behavior ownership.
- Scope cue: make identity context handling explicit in `ActionPolicy` without changing current enforcement behavior.
- Size: ~0.5 day.

2. Index Lifecycle Locking Spec LockSpy Namespace
- Value: tightens locking-spec reliability by avoiding broad `any_instance` stubbing and making lock-observation scope explicit.
- Scope cue: update locking tests to use targeted spies/fakes with stable namespace ownership.
- Size: ~0.5 day.

3. Policy Identity Plumbing Spec Reduce `any_instance` Usage
- Value: keeps policy-plumbing specs more deterministic and maintainable by replacing broad stubs with local collaborators.
- Scope cue: narrow test doubles around identity context flow while preserving current API contracts.
- Size: ~0.5 day.

## Additional queued slices

1. Runtime Config Surface Parity + Boolean Parsing Contract (follow-up only)
- Value: reopen only if semantic config diagnostics/parsing regress after retrieval policy refactors.
- Size: ~0.5 day, conditional.
