# Backlog

## Now

1. Workflow Planner-to-Execute Correlation Metadata
- Type: `feature`
- Value: adds one small correlation/audit signal after execute-envelope cleanup so thin clients can pair planner output, dry runs, and apply results without endpoint-specific inference.
- Size: ~0.5 day.

## Next

1. Workflow Operator Correlation Display
- Type: `feature`
- Value: uses planner-to-execution correlation metadata in CLI/operator output so dry-run/apply flows are easier to inspect against the originating planned action.
- Size: ~0.5 day.

2. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
