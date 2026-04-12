# Tech Debt

This file tracks current, unresolved technical debt that still affects planning or sequencing.
It is not intended to be a historical journal of every past planning discussion.

## Current Debt

### Workflow Response Correlation
- State: workflow apply/execute responses still make thin clients infer canonical action identity from endpoint choice and surrounding context.
- Impact: clients have to stitch planner output, dry-run output, and mutation results together with more implicit logic than necessary.
- Trigger to fix: current top-priority workflow response work after execute-envelope convergence.
- Likely next slice: `Workflow Apply Response Action Echo`.

### Policy Plumbing Test Fragility
- State: some policy-identity tests still rely on brittle mocking patterns such as `any_instance`.
- Impact: test intent is harder to read and future wiring changes are more likely to cause noisy failures.
- Trigger to fix: when touching policy/request-spec plumbing next.
- Likely next slice: `Policy Identity Plumbing Spec Without any_instance`.

### Index Lifecycle Spec Namespacing
- State: index lifecycle locking specs still carry a global naming/collision risk.
- Impact: suite growth can make these tests harder to maintain or reason about.
- Trigger to fix: when revisiting index lifecycle hardening.
- Likely next slice: `LockSpy Namespacing In Index Lifecycle Locking Spec`.

## Watchlist

### Workflow Action Parsing
- Watch for continued duplication across plan, draft/apply, and execute request parsing.
- If another slice adds more shared action-shape logic, extract a small workflow action request normalizer instead of growing endpoint-local validation branches.

### Workflow Trace And Audit Shape
- Watch for trace/audit metadata spreading independently across dry-run, apply, and execute responses.
- If more metadata is added in multiple places, extract a small workflow trace/audit builder or value object.

### CLI Surface Growth
- The CLI is intentionally thin today.
- If more operator commands appear, extract a shared CLI transport/render helper instead of adding per-script formatting and request code.

### Retrieval Policy Expansion
- Retrieval internals are still manageable, but richer lexical/semantic policy work could reintroduce scoring and provider-selection coupling.
- If retrieval ranking variants multiply, revisit explicit scoring/policy seams rather than continuing to grow one retriever path.

## Recently Resolved

- Workflow planning, draft/apply, and execute now share a cleaner canonical `workflow.draft_patch` request contract, including a deduplicated execute profile-resolution path.
- Planner-side workflow profile validation no longer carries its own source of truth; it now reuses shared workflow profile policy.
- Planner output can use a smaller internal semantic draft intent while `mirai` still returns the canonical `workflow.draft_patch` action shape to clients.
