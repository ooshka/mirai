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
