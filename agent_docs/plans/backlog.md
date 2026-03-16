# Backlog

## Now

1. Retrieval Query Result Match Explainability
- Type: `feature`
- Value: adds bounded match rationale fields so operators can see why a chunk matched without rescanning or guessing ranking behavior.
- Size: ~1 day.

## Next

1. Semantic Retrieval Match Explainability Parity
- Type: `feature`
- Value: extends the new explanation contract across semantic hits without leaking provider-specific payloads or weakening lexical fallback behavior.
- Size: ~0.5-1 day.

2. Planning Artifact Hygiene: Reconcile Superseded Open Cases
- Type: `docs`
- Value: reduces planner/implementor confusion by resolving stale open case files.
- Size: ~0.5 day.

## Later

1. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

2. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
