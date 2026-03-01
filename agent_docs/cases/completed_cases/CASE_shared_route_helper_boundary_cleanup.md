---
case_id: CASE_shared_route_helper_boundary_cleanup
created: 2026-03-01
---

# CASE: Shared Route Helper Boundary Cleanup

## Goal
Extract MCP route-shared helper methods from `App` into a focused helper module so route composition stays explicit and maintainable.

## Why this next
- Value: reduces coupling between `App` boot/config responsibilities and MCP route helper behavior.
- Dependency/Risk: derisks future MCP endpoint growth by preventing helper logic from expanding inside the main app shell.
- Tech debt note: pays down residual helper coupling debt left after route modularization.

## Definition of Done
- [ ] MCP helper methods used by route modules (`render_error`, patch payload parsing, MCP error handling, policy enforcement wiring) are defined in a dedicated helper module.
- [ ] `App` remains a thin composition shell (settings + module registration) with no contract drift in existing MCP endpoint behavior.
- [ ] Request/error behavior for affected endpoints remains unchanged.
- [ ] Tests/verification: `docker compose run --rm dev bundle exec rspec spec/mcp_notes_spec.rb spec/mcp_patch_spec.rb spec/mcp_index_spec.rb spec/mcp_index_query_spec.rb spec/mcp_error_mapper_spec.rb`

## Scope
**In**
- Add a route helper module under `app/routes/` or `app/services/mcp/` and wire it into `App`.
- Move existing MCP route-shared helper methods into that module with minimal behavioral change.
- Keep policy/error mapping interactions explicit and test-backed.

**Out**
- New endpoint features, payload shape changes, or auth/policy redesign.
- Service-layer rewrites unrelated to helper boundary cleanup.

## Proposed approach
Create a single helper module (for example `Routes::McpHelpers`) containing the existing helper methods and include/register it from `App`. Keep method names and call sites in route modules unchanged to minimize risk. Preserve helper behavior exactly by reusing current `Mcp::ErrorMapper` and `Mcp::ActionPolicy` usage paths. Validate with existing request specs as contract tests rather than introducing broader refactors.

## Steps (agent-executable)
1. Add dedicated MCP helper module with current helper methods and required dependencies.
2. Wire the helper module into `App` and remove duplicate inline helper definitions from `app.rb`.
3. Ensure route modules continue using same helper calls with unchanged endpoint contracts.
4. Run targeted MCP request/error specs and fix any helper-scope regressions only.

## Risks / Tech debt / Refactor signals
- Risk: helper method scope/context differences could alter error handling behavior. → Mitigation: keep method signatures/call sites unchanged and gate with request specs.
- Debt: helper module may still own several responsibilities (error rendering + parsing + policy enforcement), acceptable for this bounded cleanup.
- Refactor suggestion (if any): if helper responsibilities continue to grow, split module into smaller parsing/policy helper units in a later slice.

## Notes / Open questions
- Assumption: preserving existing helper method names is preferred over renaming to keep this slice low risk.
