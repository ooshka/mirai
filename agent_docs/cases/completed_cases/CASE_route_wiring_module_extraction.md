---
case_id: CASE_route_wiring_module_extraction
created: 2026-03-01
---

# CASE: Route Wiring Module Extraction

## Goal
Reduce route-layer complexity by extracting Sinatra route wiring from `app.rb` into focused route modules while preserving all existing HTTP contracts.

## Why this next
- Value: keeps endpoint growth maintainable and easier to review as MCP actions continue to expand.
- Dependency/Risk: derisks future feature slices by preventing `app.rb` from becoming a high-churn bottleneck.
- Tech debt note: pays down known route-concentration debt without changing domain/service behavior.

## Definition of Done
- [ ] `app.rb` becomes a thin composition shell (settings/helpers + route module registration), not the primary route-definition file.
- [ ] MCP and health/config endpoint contracts remain unchanged (paths, status codes, and JSON payload shapes).
- [ ] Route modules are organized in explicit, minimal files (for example base routes vs MCP routes) with no new framework dependency.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/health_spec.rb spec/mcp_notes_spec.rb spec/mcp_patch_spec.rb spec/mcp_index_spec.rb spec/mcp_index_query_spec.rb`

## Scope
**In**
- Extract route blocks from `app.rb` into small route modules under `app/` (or `app/routes/`) using existing service actions.
- Keep existing helper behavior (`render_error`, payload parsing, MCP error handling) explicit and reusable from module context.
- Preserve `config.ru`/boot behavior with no endpoint contract changes.

**Out**
- New endpoint functionality, payload shape changes, or MCP action behavior changes.
- Service-layer rewrites (`Mcp::*Action`, parser, validator, index internals).
- Authentication, middleware additions, or framework migration.

## Proposed approach
Use Sinatra extension/registration style modules to hold route definitions and register them from `App`. Keep shared helpers in `App` (or one shared helper module) and ensure route modules call the same action objects used today. Split into two files: core routes (`/health`, `/config`) and MCP routes (`/mcp/...`) to reduce churn hotspots. Preserve order and endpoint paths exactly; this slice is composition-only. Validate behavior with existing request specs as contract tests.

## Steps (agent-executable)
1. Add route module files for core and MCP endpoints, each containing only route definitions and existing action delegation.
2. Update `app.rb` to register/use those modules while keeping settings and shared helpers intact.
3. Ensure helper access from route modules (payload parsing and MCP error mapping) remains explicit and deterministic.
4. Run targeted request specs covering health/config, notes, patch, index lifecycle, and index query routes.
5. If specs expose contract drift, adjust wiring only (not service behavior) until parity is restored.

## Risks / Tech debt / Refactor signals
- Risk: subtle helper-scope differences can change error handling behavior in modular routes. → Mitigation: retain request specs as contract gate and keep helper ownership centralized.
- Debt: pays down monolithic `app.rb` route concentration; may leave minor helper coupling to be cleaned in a later slice.
- Refactor suggestion (if any): if route modules continue to grow, introduce a small route registration manifest to keep boot order explicit.

## Notes / Open questions
- Assumption: preserving API contracts exactly is higher priority than optimizing internal helper shape in this slice.
