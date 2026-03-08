# Backlog

## Now

1. Retrieval Query Result Snippet Offsets
- Type: `feature`
- Value: returns lightweight match location hints so callers can ground responses in note context faster.
- Size: ~1 day.

2. OpenAI LLM Workflow Seam For MCP Update/Management Actions
- Type: `feature`
- Value: starts Phase 1 non-retrieval model integration for note-update and repo-management flows behind provider-safe service boundaries.
- Size: ~1-2 days.

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
