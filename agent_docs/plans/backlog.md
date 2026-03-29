# Backlog

## Now

No currently tracked items.

## Next

1. Canonical Workflow Execute Endpoint
- Type: `feature`
- Value: reduces client-side stitching across planning, drafting, and applying by giving `mirai` one server-owned workflow path from intent to committed note update with explicit audit output.
- Size: ~1 day.

2. Workflow Apply Response Action Echo
- Type: `hardening`
- Value: gives thin workflow clients one explicit action-identity field in apply responses so they can correlate planner output with execution results without inferring it from endpoint choice alone.
- Size: ~0.5 day.

3. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

## Later

1. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
