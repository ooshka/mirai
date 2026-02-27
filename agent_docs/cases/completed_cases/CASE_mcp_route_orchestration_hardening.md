---
case_id: CASE_mcp_route_orchestration_hardening
created: 2026-02-27
---

# CASE: MCP Route Orchestration Hardening

## Goal
Reduce endpoint fragility by extracting MCP route orchestration and error mapping out of `app.rb` into small, testable units while preserving existing API behavior.

## Why this next
- Value: keeps the mutation/read surface maintainable as additional MCP tools are added.
- Dependency/Risk: derisks future slices (index/retrieval and richer mutation policies) by preventing `app.rb` from becoming a monolith.
- Tech debt note: pays down current route-layer complexity debt without changing domain behavior.

## Definition of Done
- [ ] `app.rb` no longer contains duplicated rescue/error mapping blocks for MCP routes.
- [ ] MCP notes and patch endpoint behavior remains unchanged (status codes + JSON shapes).
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec`

## Scope
**In**
- Extract route-level orchestration for MCP notes and patch flows into focused classes/modules under `app/`.
- Centralize known exception-to-HTTP error mapping used by MCP endpoints.
- Add/adjust specs for orchestration/error mapping behavior where needed.

**Out**
- Changing endpoint URLs, payload shapes, or patch semantics.
- New MCP capabilities (indexing, retrieval, new mutation tools).
- Provider abstraction work.

## Proposed approach
Introduce small endpoint handlers (or service objects) that encapsulate each MCP action and return structured success/error results. Keep `App` responsible only for HTTP wiring and serialization. Move repeated error mapping into one helper/module that maps known domain exceptions to stable API error codes/messages. Preserve current `NotesReader`, `PatchValidator`, and `PatchApplier` contracts so this stays a bounded refactor with low behavioral risk.

## Steps (agent-executable)
1. Identify duplicated route orchestration/error handling patterns in `app.rb` for notes and patch endpoints.
2. Add focused endpoint handler classes/modules for `notes list`, `notes read`, `patch propose`, and `patch apply`.
3. Add a shared MCP error-mapping component that translates known exceptions into status/code/message triples.
4. Update `app.rb` to delegate to handlers and shared mapper while preserving response JSON shapes.
5. Run and update endpoint specs to ensure behavior parity and catch regressions.
6. Run full test suite and resolve any failures.

## Risks / Tech debt / Refactor signals
- Risk: subtle API contract drift during refactor. → Mitigation: keep existing request/response specs as contract tests and avoid payload/schema changes.
- Debt: pays down `app.rb` route concentration debt; may still leave lightweight Sinatra wiring in a single file.
- Refactor suggestion (if any): if MCP endpoints continue growing, move from single-file Sinatra routes to mounted modular endpoint files.

## Notes / Open questions
- Assumption: preserving current MCP response contracts is higher priority than introducing new abstractions for dependency injection.
