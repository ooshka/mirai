# Current Sprint

## Active Case
`agent_docs/cases/CASE_shared_route_helper_boundary_cleanup.md`

## Sprint Goal
Reduce route/helper coupling after module extraction:
- move shared MCP route helpers into one explicit helper module
- keep `App` as thin composition shell (settings + registration)
- preserve existing MCP request/error contracts while changing helper ownership only
