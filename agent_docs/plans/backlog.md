# Backlog

## Now

1. Workflow Apply Response Contract Tightening
- Type: `feature`
- Value: keeps the first workflow apply loop reviewable by tightening its returned audit fields before other workflow consumers depend on an ad hoc response shape.
- Size: ~0.5-1 day.

## Next

1. Workflow Apply Response Action Echo
- Type: `feature`
- Value: gives thin workflow clients one explicit action-identity field in apply responses so they can correlate planner output with execution results without inferring it from endpoint choice alone.
- Size: ~0.5 day.

2. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

## Later

1. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
