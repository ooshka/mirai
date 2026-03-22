# Backlog

## Now

1. Local Workflow Patch Drafter Provider Handoff
- Type: `feature`
- Value: completes the self-hosted workflow loop by letting planner-produced draft actions use the local runtime path instead of falling back to the hosted drafter seam.
- Size: ~1 day.

## Next

1. Local Workflow Plan/Draft Loop Smoke Case
- Type: `feature`
- Value: adds one bounded end-to-end verification seam for the self-hosted planner-to-drafter loop after local draft-provider wiring lands.
- Size: ~1 day.

## Later

1. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

2. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
