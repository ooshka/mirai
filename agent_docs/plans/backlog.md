# Backlog

## Next 3 Candidate Slices

1. Git Commit Metadata Enrichment (selected)
- Value: improves auditability by attaching explicit MCP operation metadata to patch-apply commits.
- Size: ~0.5-1 day.

2. Patch Policy Hardening (edge cases + deterministic conflict contract)
- Value: hardens parser/apply behavior for malformed hunks and less common diff shapes before expanding mutation scope.
- Size: ~1 day.

3. MCP Mutation Route Modularization
- Value: keeps Sinatra wiring maintainable as additional mutation tools are added.
- Size: ~1-2 days.
