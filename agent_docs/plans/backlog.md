# Backlog

## Now

No currently tracked items.

## Next

1. Real-Notes MVP Smoke Scenario Pack
- Type: `feature`
- Value: adds a small scripted/manual scenario set for testing against a real notes mount, covering at least one local-model run and one hosted-model or hosted-profile run without requiring broad UI polish.
- Size: ~1 day.

2. Workflow Planner Intent Contract Simplification
- Type: `feature`
- Value: reduces local-model contract pressure further by letting planners emit a smaller semantic intent payload that `mirai` expands into the canonical execution action shape.
- Size: ~1 day.

3. Workflow Execute Request Envelope Cleanup
- Type: `feature`
- Value: trims any temporary wrapper or validation awkwardness left by the first canonical execute endpoint so planner action payloads stay the single obvious client contract.
- Size: ~0.5 day.

4. Workflow Apply Response Action Echo
- Type: `hardening`
- Value: gives thin workflow clients one explicit action-identity field in apply responses so they can correlate planner output with execution results without inferring it from endpoint choice alone.
- Size: ~0.5 day.

5. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

## Later

1. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
