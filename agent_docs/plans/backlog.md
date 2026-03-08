# Backlog

## Now

1. Instruction-to-Patch Draft Endpoint (OpenAI, Dry-Run)
- Type: `feature`
- Value: turns natural-language edit intent into patch proposals that still flow through existing validation/apply safety gates.
- Size: ~1 day.

2. Workflow Plan Context Enrichment (Notes/Status Snapshot)
- Type: `feature`
- Value: improves plan quality by providing bounded repository context summaries without enabling execution.
- Size: ~0.5-1 day.

## Next

1. Retrieval Query Path Metadata Echo
- Type: `feature`
- Value: returns source path metadata consistently in query chunks so callers can audit grounding without post-processing.
- Size: ~0.5-1 day.

2. Planning Artifact Hygiene: Reconcile Superseded Open Cases
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
