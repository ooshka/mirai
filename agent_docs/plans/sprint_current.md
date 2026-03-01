# Current Sprint

## Active Case
No active case.

## Sprint Goal
Reduce route/helper coupling after module extraction:
- move shared MCP route helpers into one explicit helper module
- keep `App` as thin composition shell (settings + registration)
- preserve existing MCP request/error contracts while changing helper ownership only
