# Backlog

## Now

1. Local Workflow Plan/Draft Loop Smoke Case
- Type: `feature`
- Value: adds one bounded end-to-end verification seam for the self-hosted planner-to-drafter loop after local draft-provider wiring landed.
- Size: ~1 day.

## Next

1. Workflow Draft Apply Operator Loop Case
- Type: `feature`
- Value: enables one explicit operator-run follow-on from planner/drafter output into patch apply without forcing consumers to invent glue around the canonical workflow action payload.
- Size: ~1-2 days.

2. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

## Later

1. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
