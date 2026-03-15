# Backlog

## Now

No currently tracked items.

## Next

1. Retrieval Query Path Metadata Echo
- Type: `feature`
- Value: returns source path metadata consistently in query chunks so callers can audit grounding without post-processing.
- Size: ~0.5-1 day.

2. Planner-to-Draft Handoff Payload Contract
- Type: `feature`
- Value: aligns `/mcp/workflow/plan` output with `/mcp/workflow/draft_patch` input shape for low-friction operator/tool workflows.
- Size: ~0.5-1 day.

3. Retrieval Query Result Match Explainability
- Type: `feature`
- Value: adds basic match rationale fields to improve operator trust in retrieval ranking decisions.
- Size: ~1 day.

4. Planning Artifact Hygiene: Reconcile Superseded Open Cases
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
