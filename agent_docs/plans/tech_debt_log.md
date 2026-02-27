# Tech Debt Log

## 2026-02-19

### Observed signals
- App currently concentrates all behavior in `app.rb`; boundaries for controllers/services are not yet established.
- No filesystem safety primitives exist yet despite architecture requiring path hardening.
- Test coverage is minimal (health endpoint only), making regression risk high as MCP surface grows.

### Debt posture for next slice
- Debt paid down: establish reusable path validation service and focused endpoint specs.
- Debt potentially added: MCP schema may remain minimal/hand-rolled initially.
- Follow-up refactor signal: if endpoint count grows, split route handlers into modular service objects early.

## 2026-02-27

### Observed signals
- Read-path safety is in place, but mutation flow is still missing, leaving architecture incomplete for runtime knowledge evolution.
- `app.rb` now carries multiple endpoint responsibilities and will become harder to reason about once mutation paths are added.
- No diff parsing/patch validation abstraction exists yet; implementing directly in routes would create fragile, hard-to-test logic.

### Debt posture for next slice
- Debt paid down: introduces explicit patch validation/apply services and test-backed mutation error contracts.
- Debt potentially added: initial patch grammar will likely be intentionally narrow (single-file markdown diffs).
- Refactor signal: if endpoint count or service wiring keeps growing, extract route orchestration from `app.rb` into focused endpoint modules.

### Planner follow-up (next slice)
- Debt paid down next: reduce route-layer duplication by extracting MCP endpoint orchestration and shared error mapping from `app.rb`.
- Debt potentially added: temporary adapter/wrapper objects may introduce a thin indirection layer before broader modular route structure is established.
- Refactor signal: if additional MCP tools are introduced after this slice, move Sinatra route wiring into separate route files/modules to avoid a second controller-style bottleneck.

## 2026-02-27 (post-orchestration planning pass)

### Observed signals
- Patch apply currently commits with a generic subject line that omits explicit MCP operation context.
- As mutation capabilities expand, commit history readability and incident debugging will depend on stable, descriptive metadata.
- Commit message formatting appears flow-local; without a small policy seam, future tool-specific subjects are likely to drift.

### Debt posture for next slice
- Debt paid down next: establish deterministic commit metadata for patch apply so mutation history remains auditable.
- Debt potentially added: metadata remains encoded in plain commit subjects (not structured trailers/events) for now.
- Refactor signal: if multiple mutation tools need distinct commit semantics, introduce a shared commit-message policy object instead of endpoint-local string construction.
