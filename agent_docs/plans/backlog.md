# Backlog

## Now

1. Notes Batch Read Endpoint
- Type: `feature`
- Value: reduces request round-trips for runtime workflows that need multiple known notes.
- Size: ~1 day.

2. Retrieval Query Result Snippet Offsets
- Type: `feature`
- Value: returns lightweight match location hints so callers can ground responses in note context faster.
- Size: ~1 day.

## Next

1. Planning Artifact Hygiene: Reconcile Superseded Open Cases
- Type: `docs`
- Value: reduces planner/implementor confusion by resolving stale open case files.
- Size: ~0.5 day.

2. ActionPolicy Identity Context Storage Clarity
- Type: `hardening`
- Value: removes ambiguity in policy identity-context ownership before identity-aware rules expand.
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
