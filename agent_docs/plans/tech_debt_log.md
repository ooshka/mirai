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
