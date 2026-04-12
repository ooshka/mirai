# Backlog

## Next

1. Policy Identity Plumbing Spec Without `any_instance`
- Type: `hardening`
- Value: reduces brittle request-spec behavior and keeps policy plumbing tests reliable.
- Size: ~0.5 day.

2. Workflow Planner-to-Execute Correlation Metadata
- Type: `feature`
- Value: adds one small correlation/audit signal after execute-envelope cleanup so thin clients can pair planner output, dry runs, and apply results without endpoint-specific inference.
- Size: ~0.5 day.

## Later

1. LockSpy Namespacing In Index Lifecycle Locking Spec
- Type: `hardening`
- Value: avoids global spec constant collisions as suite surface grows.
- Size: ~0.5 day.
