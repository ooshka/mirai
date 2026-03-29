# Backlog

## Now

1. Canonical Workflow Execute Endpoint
- Type: `feature`
- Value: gives `mirai` one server-owned path that can accept the planned `workflow.draft_patch` action and carry it through draft generation plus patch apply without client-side stitching.
- Size: ~1 day.

## Next

1. Workflow Apply Response Action Echo
- Type: `hardening`
- Value: gives thin workflow clients one explicit action-identity field in apply responses so they can correlate planner output with execution results without inferring it from endpoint choice alone.
- Size: ~0.5 day.

2. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

3. Workflow Execute Request Envelope Cleanup
- Type: `feature`
- Value: trims any temporary wrapper or validation awkwardness left by the first canonical execute endpoint so planner action payloads stay the single obvious client contract.
- Size: ~0.5 day.

## Later

1. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
